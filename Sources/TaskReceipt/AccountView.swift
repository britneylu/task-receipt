import SwiftUI

// displays the current session and its available account action
struct AccountView: View {
    // reads account state and authentication actions from the task store
    @EnvironmentObject var store: TodoStore

    // closes the account sheet after an action
    @Environment(\.dismiss) private var dismiss

    // tracks whether the pointer is over the account action
    @State private var accountActionHover = false

    // matches the receipt colors used throughout the app
    private let paper = Color(red: 0.975, green: 0.972, blue: 0.955)
    private let ink = Color(red: 0.11, green: 0.11, blue: 0.10)

    // builds a compact receipt-style account panel
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: accountIcon)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(ink.opacity(0.55))

            VStack(spacing: 6) {
                Text(accountTitle)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(accountMessage)
                    .font(.system(size: 9, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ink.opacity(0.5))
            }

            Button(accountActionTitle) {
                performAccountAction()
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(ink.opacity(0.78))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(accountActionHover ? ink.opacity(0.07) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ink.opacity(0.2), lineWidth: 1)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    accountActionHover = hovering
                }
            }

            Button("DONE") {
                dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
        }
        .padding(28)
        .frame(width: 320)
        .background(paper)
        .foregroundStyle(ink)
        .fontDesign(.monospaced)
    }

    // chooses the account symbol for the current session
    private var accountIcon: String {
        if case .signedIn = store.accountState {
            return "person.crop.circle.fill"
        }

        return "person.crop.circle"
    }

    // displays the email address or guest session name
    private var accountTitle: String {
        if case .signedIn(let name) = store.accountState {
            return name
        }

        return "GUEST SESSION"
    }

    // explains whether this session saves completed history
    private var accountMessage: String {
        if case .signedIn = store.accountState {
            return "your completed history is saved with firebase"
        }

        return "guest history is deleted when the app closes"
    }

    // chooses the action offered for the current session
    private var accountActionTitle: String {
        if case .signedIn = store.accountState {
            return "SIGN OUT"
        }

        return "SIGN IN"
    }

    // signs out or returns a guest to the login interface
    private func performAccountAction() {
        let wasGuest = store.accountState == .guest

        if !wasGuest {
            store.signOut()
        }

        dismiss()

        if wasGuest {
            DispatchQueue.main.async {
                store.showLogin()
            }
        }
    }
}
