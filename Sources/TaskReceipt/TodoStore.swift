import Foundation
import AppKit

// owns the task list and handles every change made to it
@MainActor
final class TodoStore: ObservableObject {

    // updates the interface when tasks change and saves each change
    @Published var tasks: [TodoItem] = [] {
        didSet {
            saveTasks()
        }
    }

    // keeps history in memory for guests or mirrors the signed-in account
    @Published var history: [TodoItem] = []

    // reports whether the user is signed in or using a guest session
    @Published var accountState: AccountState = .loading

    // reports progress and errors from the login interface
    @Published var authenticationIsBusy = false
    @Published var authenticationError: String?

    // reports whether completed history is connected to firebase
    @Published var historySyncState: HistorySyncState = .connecting

    // names the UserDefaults entry that stores the encoded task list
    private let saveKey = "savedReceiptTasks"

    // syncs completed tasks with cloud firestore
    private let historyService = FirebaseHistoryService.shared

    // holds older or guest history until the user signs in
    private var unsyncedHistory: [TodoItem] = []

    // restores saved tasks when the store is created
    init() {
        loadTasks()
        collectUnsyncedHistory()

        // reacts to account changes and cloud history updates
        historyService.start(
            onAccount: { [weak self] state in
                self?.handleAccountState(state)
            },
            onStatus: { [weak self] state in
                self?.historySyncState = state
            },
            onHistory: { [weak self] cloudHistory in
                self?.history = cloudHistory
            }
        )
    }

    // returns active tasks ordered by due date
    var sortedTasks: [TodoItem] {
        tasks.sorted { $0.dueDate < $1.dueDate }
    }

    // returns completed tasks with the newest completion first
    var sortedHistory: [TodoItem] {
        history.sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }
    }

    // counts only tasks that have not been completed
    var remainingCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    // creates a task from the form values and adds it to the list
    func addTask(
        title: String,
        category: String,
        dueDate: Date
    ) {
        // builds the new task with a fresh ID and incomplete status
        let task = TodoItem(
            title: title,
            category: category,
            dueDate: dueDate
        )

        // publishing this change also triggers automatic saving
        tasks.append(task)
    }

    // moves an active task into completed history
    func toggleTask(_ task: TodoItem) {
        // finds the current array position using the task's stable ID
        guard
            let index = tasks.firstIndex(where: {
                $0.id == task.id
            })
        else {
            return
        }

        // stamps the completion time before archiving the task
        var completedTask = tasks.remove(at: index)
        completedTask.isCompleted = true
        completedTask.completedAt = Date()
        history.append(completedTask)
        historyService.save(completedTask)
    }

    // moves a completed task from history back to the active receipt
    func restoreTask(_ task: TodoItem) {
        guard let index = history.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        var restoredTask = history.remove(at: index)
        restoredTask.isCompleted = false
        restoredTask.completedAt = nil
        tasks.append(restoredTask)
        historyService.delete(task)
    }

    // permanently removes one task from completed history
    func deleteHistoryTask(_ task: TodoItem) {
        history.removeAll { $0.id == task.id }
        historyService.delete(task)
    }

    // signs in with an existing email and password
    func signIn(email: String, password: String) {
        runAuthentication { completion in
            historyService.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                completion: completion
            )
        }
    }

    // creates a new email and password account
    func createAccount(email: String, password: String) {
        runAuthentication { completion in
            historyService.createAccount(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                completion: completion
            )
        }
    }

    // opens the google account authentication window
    func signInWithGoogle() {
        guard let window = NSApp.keyWindow else {
            authenticationError = "The Google sign-in window is not available"
            return
        }

        runAuthentication { completion in
            historyService.signInWithGoogle(
                presenting: window,
                completion: completion
            )
        }
    }

    // starts a guest session whose history lasts only until the app closes
    func continueAsGuest() {
        authenticationError = nil
        historyService.continueAsGuest()
    }

    // returns from guest mode to the login interface without losing this session
    func showLogin() {
        unsyncedHistory = history
        historyService.leaveGuest()
    }

    // signs out and returns to the login interface
    func signOut() {
        authenticationError = historyService.signOut()
        unsyncedHistory.removeAll()
        history.removeAll()
    }

    // removes the task with the matching ID
    func deleteTask(_ task: TodoItem) {
        tasks.removeAll {
            $0.id == task.id
        }
    }

    // encodes all tasks as JSON and saves them in UserDefaults
    private func saveTasks() {
        do {
            // converts the Swift task values into storable data
            let data = try JSONEncoder().encode(tasks)

            // writes the encoded data under the app's save key
            UserDefaults.standard.set(
                data,
                forKey: saveKey
            )
        } catch {
            // reports encoding failures during development
            print("Failed to save tasks: \(error)")
        }
    }

    // loads and decodes tasks saved during an earlier app session
    private func loadTasks() {
        // stops when the user has no saved task data yet
        guard
            let data = UserDefaults.standard.data(
                forKey: saveKey
            )
        else {
            return
        }

        do {
            // converts the saved JSON data back into task values
            tasks = try JSONDecoder().decode(
                [TodoItem].self,
                from: data
            )
        } catch {
            // reports invalid or unreadable saved data during development
            print("Failed to load tasks: \(error)")
        }
    }

    // collects history created before account-based syncing was added
    private func collectUnsyncedHistory() {
        var collected = tasks.filter(\.isCompleted)
        tasks.removeAll { $0.isCompleted }

        if
            let data = UserDefaults.standard.data(forKey: "savedReceiptHistory"),
            let olderHistory = try? JSONDecoder().decode([TodoItem].self, from: data)
        {
            collected.append(contentsOf: olderHistory)
            UserDefaults.standard.removeObject(forKey: "savedReceiptHistory")
        }

        for var task in collected {
            task.completedAt = task.completedAt ?? Date()

            if !unsyncedHistory.contains(where: { $0.id == task.id }) {
                unsyncedHistory.append(task)
            }
        }
    }

    // updates history when the account or guest choice changes
    private func handleAccountState(_ state: AccountState) {
        accountState = state

        switch state {
        case .loading:
            break
        case .signedOut:
            history.removeAll()
        case .guest:
            history = unsyncedHistory
        case .signedIn:
            history.removeAll()

            for task in unsyncedHistory {
                historyService.save(task)
            }

            unsyncedHistory.removeAll()
        }
    }

    // runs one authentication request and publishes its result
    private func runAuthentication(
        _ operation: (@escaping AuthenticationCompletion) -> Void
    ) {
        authenticationIsBusy = true
        authenticationError = nil

        operation { [weak self] error in
            self?.authenticationIsBusy = false

            if error?.localizedCaseInsensitiveContains("keychain") == true {
                self?.authenticationError =
                    "This Mac build needs Apple code signing and Keychain Sharing"
            } else {
                self?.authenticationError = error
            }
        }
    }

    // replaces the editable values of an existing task
    func updateTask(
        id: UUID,
        title: String,
        category: String,
        dueDate: Date
    ) {
        // finds the exact task that the edit form was opened for
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return
        }

        // applies the edited values while preserving ID and completion state
        tasks[index].title = title
        tasks[index].category = category
        tasks[index].dueDate = dueDate
    }
}
