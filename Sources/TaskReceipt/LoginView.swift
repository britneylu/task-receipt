import SwiftUI
import GoogleSignInSwift

// lets the user choose a saved account or temporary guest session
struct LoginView: View {
    // sends account actions to the shared task store
    @EnvironmentObject var store: TodoStore

    // holds the values typed into the account form
    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false

    // matches the receipt appearance used throughout the app
    private let paper = Color(red: 0.975, green: 0.972, blue: 0.955)
    private let ink = Color(red: 0.11, green: 0.11, blue: 0.10)

    // builds google, email, and guest login choices
    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 7) {
                Text("TASK RECEIPT")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))

                Text(isCreatingAccount ? "CREATE AN ACCOUNT" : "SIGN IN TO SAVE HISTORY")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(1.2)
                    .opacity(0.5)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("EMAIL")
                    .fieldLabel()

                TextField("you@example.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("PASSWORD")
                    .fieldLabel()

                SecureField("at least 6 characters", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(isCreatingAccount ? .newPassword : .password)
            }

            if let error = store.authenticationError {
                Text(error)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(isCreatingAccount ? "CREATE ACCOUNT" : "SIGN IN") {
                if isCreatingAccount {
                    store.createAccount(email: email, password: password)
                } else {
                    store.signIn(email: email, password: password)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(ink)
            .frame(maxWidth: .infinity)
            .disabled(formIsInvalid || store.authenticationIsBusy)

            Button(isCreatingAccount ? "ALREADY HAVE AN ACCOUNT? SIGN IN" : "NEED AN ACCOUNT? CREATE ONE") {
                isCreatingAccount.toggle()
                store.authenticationError = nil
            }
            .buttonStyle(.plain)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))

            HStack {
                Rectangle().frame(height: 1)
                Text("OR")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .opacity(0.4)
                Rectangle().frame(height: 1)
            }
            .foregroundStyle(ink.opacity(0.15))

            // uses google's official button and multicolor G artwork
            GoogleSignInButton {
                store.signInWithGoogle()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(store.authenticationIsBusy)

            Button("CONTINUE AS GUEST") {
                store.continueAsGuest()
            }
            .buttonStyle(.plain)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))

            Text("guest history is deleted when the app closes")
                .font(.system(size: 8, design: .monospaced))
                .opacity(0.4)

            if store.authenticationIsBusy {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(28)
        .frame(width: 390)
        .background(paper)
        .foregroundStyle(ink)
        .fontDesign(.monospaced)
        .preferredColorScheme(.light)
        .interactiveDismissDisabled()
    }

    // prevents incomplete credentials from being submitted
    private var formIsInvalid: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || password.count < 6
    }
}

// provides consistent labels for the login fields
private extension Text {
    func fieldLabel() -> some View {
        font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.secondary)
    }
}
