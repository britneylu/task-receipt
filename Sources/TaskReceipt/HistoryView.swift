import SwiftUI

// displays tasks that have been completed and moved off the receipt
struct HistoryView: View {
    // reads completed tasks and history actions from the shared store
    @EnvironmentObject var store: TodoStore

    // keeps the sheet exactly as tall as the main receipt that opened it
    let receiptHeight: CGFloat

    // closes the history sheet
    @Environment(\.dismiss) private var dismiss

    // matches the paper and ink colors used by the main receipt
    private let paper = Color(red: 0.975, green: 0.972, blue: 0.955)
    private let ink = Color(red: 0.11, green: 0.11, blue: 0.10)

    // builds the history heading, sync status, and completed task list
    var body: some View {
        VStack(spacing: 0) {
            header

            Rectangle()
                .fill(ink.opacity(0.18))
                .frame(height: 1)

            if store.history.isEmpty {
                emptyHistory
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.sortedHistory) { task in
                            HistoryRow(task: task)

                            if task.id != store.sortedHistory.last?.id {
                                Rectangle()
                                    .fill(ink.opacity(0.08))
                                    .frame(height: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            Rectangle()
                .fill(ink.opacity(0.18))
                .frame(height: 1)

            footer
        }
        .frame(width: 320, height: receiptHeight)
        .background(paper)
        .foregroundStyle(ink)
        .fontDesign(.monospaced)
    }

    // shows the history title and number of completed tasks
    private var header: some View {
        VStack(spacing: 7) {
            Text("TASK HISTORY")
                .font(.system(size: 18, weight: .bold, design: .monospaced))

            Text("\(store.history.count) COMPLETED")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .opacity(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // explains that history will appear after a task is checked off
    private var emptyHistory: some View {
        VStack(spacing: 7) {
            Text("NO COMPLETED TASKS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))

            Text("finished tasks will appear here")
                .font(.system(size: 9, design: .monospaced))
                .opacity(0.42)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // shows firebase state and provides a button for closing history
    private var footer: some View {
        HStack {
            Label(syncLabel, systemImage: syncIcon)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(ink.opacity(0.5))
                .help(syncHelp)

            Spacer()

            Button("DONE") {
                dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
        .padding(20)
    }

    // converts the firebase state into a short status label
    private var syncLabel: String {
        if store.accountState == .guest {
            return "GUEST SESSION"
        }

        switch store.historySyncState {
        case .connecting:
            return "CONNECTING"
        case .synced:
            return "FIREBASE SYNCED"
        case .localOnly:
            return "LOCAL HISTORY"
        case .failed:
            return "SYNC ERROR"
        }
    }

    // chooses an icon that matches the current sync state
    private var syncIcon: String {
        if store.accountState == .guest {
            return "person.crop.circle.badge.clock"
        }

        switch store.historySyncState {
        case .connecting:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.icloud"
        case .localOnly:
            return "internaldrive"
        case .failed:
            return "exclamationmark.icloud"
        }
    }

    // gives more detail when the user hovers over the sync status
    private var syncHelp: String {
        if store.accountState == .guest {
            return "Guest history is deleted when the app closes"
        }

        switch store.historySyncState {
        case .connecting:
            return "Connecting to Firebase"
        case .synced:
            return "Completed tasks are synced with Cloud Firestore"
        case .localOnly:
            return "Add GoogleService-Info.plist to enable Firebase sync"
        case .failed(let message):
            return message
        }
    }
}

// displays one completed task with restore and delete actions
private struct HistoryRow: View {
    // changes the shared history when a button is clicked
    @EnvironmentObject var store: TodoStore

    // holds the completed task displayed by this row
    let task: TodoItem

    // uses the same dark ink color as the rest of the receipt
    private let ink = Color(red: 0.11, green: 0.11, blue: 0.10)

    // arranges task details, completion date, and actions
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .strikethrough()

                Text(task.category.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ink.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(dueDateText)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))

                Text("COMPLETED")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(ink.opacity(0.5))
            }

            Button {
                store.restoreTask(task)
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.plain)
            .help("Restore task")

            Button(role: .destructive) {
                store.deleteHistoryTask(task)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .help("Delete permanently")
        }
        .padding(.vertical, 14)
    }

    // formats the task's original due date for the history receipt
    private var dueDateText: String {
        task.dueDate
            .formatted(.dateTime.month(.abbreviated).day().year())
            .uppercased()
    }
}
