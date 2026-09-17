import SwiftUI

private struct AddTaskActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var addTaskAction: (() -> Void)? {
        get { self[AddTaskActionKey.self] }
        set { self[AddTaskActionKey.self] = newValue }
    }
}

private struct TaskReceiptCommands: Commands {
    @FocusedValue(\.addTaskAction) private var addTaskAction

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Add Task") {
                addTaskAction?()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(addTaskAction == nil)
        }
    }
}

@main
struct TaskReceiptApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @StateObject private var store = TodoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            TaskReceiptCommands()
        }
        // .windowResizability(.contentSize)
    }
}
