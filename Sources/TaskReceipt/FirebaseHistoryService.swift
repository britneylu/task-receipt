import Foundation
import AppKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

// describes whether the user has chosen an account or guest session
enum AccountState: Equatable {
    case loading
    case signedOut
    case guest
    case signedIn(String)
}

// describes the current connection between task history and firebase
enum HistorySyncState: Equatable {
    case connecting
    case synced
    case localOnly
    case failed(String)
}

// returns authentication results safely to the main interface
typealias AuthenticationCompletion = @MainActor @Sendable (String?) -> Void

// handles firebase accounts and cloud firestore history
@MainActor
final class FirebaseHistoryService {
    // shares one firebase connection throughout the app
    static let shared = FirebaseHistoryService()

    // holds firebase state after configuration and authentication
    private var database: Firestore?
    private var userID: String?
    private var listener: ListenerRegistration?
    private var authListener: AuthStateDidChangeListenerHandle?
    private var isGuest = false
    private var isConfigured = false

    // keeps account changes available to the task store
    private var onAccount: ((AccountState) -> Void)?
    private var onStatus: ((HistorySyncState) -> Void)?
    private var onHistory: (([TodoItem]) -> Void)?

    // keeps signed-in changes made while firestore is connecting
    private var pendingSaves: [UUID: TodoItem] = [:]
    private var pendingDeletes: Set<UUID> = []

    // prevents other parts of the app from creating this service directly
    private init() {}

    // configures firebase and restores a previously signed-in account
    func start(
        onAccount: @escaping (AccountState) -> Void,
        onStatus: @escaping (HistorySyncState) -> Void,
        onHistory: @escaping ([TodoItem]) -> Void
    ) {
        self.onAccount = onAccount
        self.onStatus = onStatus
        self.onHistory = onHistory

        guard configureFirebase() else {
            onStatus(.localOnly)
            onAccount(.signedOut)
            return
        }

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self else { return }

                if let user, !user.isAnonymous {
                    self.isGuest = false
                    self.connect(user: user)
                } else if !self.isGuest {
                    self.disconnect()
                    onAccount(.signedOut)
                }
            }
        }
    }

    // signs in to an existing email and password account
    func signIn(
        email: String,
        password: String,
        completion: @escaping AuthenticationCompletion
    ) {
        guard isConfigured else {
            completion("Add GoogleService-Info.plist before signing in")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            Task { @MainActor in
                completion(error?.localizedDescription)
            }
        }
    }

    // creates a new firebase email and password account
    func createAccount(
        email: String,
        password: String,
        completion: @escaping AuthenticationCompletion
    ) {
        guard isConfigured else {
            completion("Add GoogleService-Info.plist before creating an account")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            Task { @MainActor in
                completion(error?.localizedDescription)
            }
        }
    }

    // opens google sign-in and exchanges its token for a firebase account
    func signInWithGoogle(
        presenting window: NSWindow,
        completion: @escaping AuthenticationCompletion
    ) {
        guard
            isConfigured,
            let clientID = FirebaseApp.app()?.options.clientID
        else {
            completion("Firebase is missing its Google client configuration")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
            if let error {
                Task { @MainActor in
                    completion(error.localizedDescription)
                }
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                Task { @MainActor in
                    completion("Google did not return a sign-in token")
                }
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { _, error in
                Task { @MainActor in
                    completion(error?.localizedDescription)
                }
            }
        }
    }

    // starts a temporary session that never writes history to firebase
    func continueAsGuest() {
        isGuest = true
        disconnect()
        onStatus?(.localOnly)
        onHistory?([])
        onAccount?(.guest)
    }

    // leaves guest mode so the login interface appears again
    func leaveGuest() {
        isGuest = false
        onHistory?([])
        onAccount?(.signedOut)
    }

    // signs out of firebase and removes cloud history from the interface
    func signOut() -> String? {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            disconnect()
            onHistory?([])
            onAccount?(.signedOut)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    // uploads one completed task only when an account is signed in
    func save(_ task: TodoItem) {
        guard !isGuest, userID != nil else { return }
        pendingDeletes.remove(task.id)

        guard let document = document(for: task.id) else {
            pendingSaves[task.id] = task
            return
        }

        document.setData(data(for: task), merge: true)
    }

    // deletes one cloud record only when an account is signed in
    func delete(_ task: TodoItem) {
        guard !isGuest, userID != nil else { return }
        pendingSaves.removeValue(forKey: task.id)

        guard let document = document(for: task.id) else {
            pendingDeletes.insert(task.id)
            return
        }

        document.delete()
    }

    // loads firebase options from the app bundle or project directory
    private func configureFirebase() -> Bool {
        if FirebaseApp.app() != nil {
            isConfigured = true
            return true
        }

        let fileManager = FileManager.default
        let projectDirectory = fileManager.currentDirectoryPath
        var possiblePaths = [
            URL(fileURLWithPath: projectDirectory)
                .appendingPathComponent("GoogleService-Info.plist").path,
            URL(fileURLWithPath: projectDirectory)
                .appendingPathComponent("Sources/TaskReceipt/GoogleService-Info.plist").path
        ]

        if let bundledPath = Bundle.main.path(
            forResource: "GoogleService-Info",
            ofType: "plist"
        ) {
            possiblePaths.insert(bundledPath, at: 0)
        }

        guard
            let path = possiblePaths.first(where: fileManager.fileExists),
            let options = FirebaseOptions(contentsOfFile: path)
        else {
            return false
        }

        FirebaseApp.configure(options: options)
        isConfigured = true
        return true
    }

    // opens firestore history for the authenticated firebase user
    private func connect(user: User) {
        let accountChanged = userID != user.uid
        userID = user.uid
        database = Firestore.firestore()

        if accountChanged {
            onHistory?([])
        }

        flushPendingChanges()
        onStatus?(.connecting)
        onAccount?(.signedIn(user.email ?? user.displayName ?? "ACCOUNT"))

        listener?.remove()
        listener = historyCollection()?.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.onStatus?(.failed(error.localizedDescription))
                    return
                }

                let history = snapshot?.documents.compactMap(self.task(from:)) ?? []
                self.onHistory?(history)
                self.onStatus?(.synced)
            }
        }
    }

    // removes firestore state when there is no signed-in account
    private func disconnect() {
        listener?.remove()
        listener = nil
        database = nil
        userID = nil
        pendingSaves.removeAll()
        pendingDeletes.removeAll()
    }

    // sends changes that occurred while firestore was connecting
    private func flushPendingChanges() {
        let saves = pendingSaves.values
        let deletes = pendingDeletes
        pendingSaves.removeAll()
        pendingDeletes.removeAll()

        for task in saves {
            save(task)
        }

        for id in deletes {
            document(for: id)?.delete()
        }
    }

    // returns the signed-in user's firestore history collection
    private func historyCollection() -> CollectionReference? {
        guard let database, let userID else { return nil }
        return database.collection("users").document(userID).collection("history")
    }

    // returns the firestore document used by one completed task
    private func document(for id: UUID) -> DocumentReference? {
        historyCollection()?.document(id.uuidString)
    }

    // converts a task into values cloud firestore can store
    private func data(for task: TodoItem) -> [String: Any] {
        [
            "id": task.id.uuidString,
            "title": task.title,
            "category": task.category,
            "dueDate": Timestamp(date: task.dueDate),
            "isCompleted": true,
            "completedAt": Timestamp(date: task.completedAt ?? Date())
        ]
    }

    // converts one firestore document back into a task
    private func task(from document: QueryDocumentSnapshot) -> TodoItem? {
        let values = document.data()

        guard
            let idText = values["id"] as? String,
            let id = UUID(uuidString: idText),
            let title = values["title"] as? String,
            let category = values["category"] as? String,
            let dueDate = values["dueDate"] as? Timestamp,
            let completedAt = values["completedAt"] as? Timestamp
        else {
            return nil
        }

        return TodoItem(
            id: id,
            title: title,
            category: category,
            dueDate: dueDate.dateValue(),
            isCompleted: true,
            completedAt: completedAt.dateValue()
        )
    }
}
