import SwiftUI
import GoogleSignIn

// defines the focused action that can open the Add Task sheet
private struct AddTaskActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

// adds the Add Task action to SwiftUI's focused window values
extension FocusedValues {
    // returns the action supplied by whichever receipt window is active
    var addTaskAction: (() -> Void)? {
        get { self[AddTaskActionKey.self] }
        set { self[AddTaskActionKey.self] = newValue }
    }
}

// replaces the normal New Window command with the app's Add Task command
private struct TaskReceiptCommands: Commands {
    // reads the Add Task action from the currently focused receipt window
    @FocusedValue(\.addTaskAction) private var addTaskAction

    // builds the File menu command and its keyboard shortcut
    var body: some Commands {
        // replaces Command-N so it does not open another app window
        CommandGroup(replacing: .newItem) {
            // runs the focused window's action when Add Task is chosen
            Button("Add Task") {
                addTaskAction?()
            }
            // lets the user open the Add Task sheet with Command-N
            .keyboardShortcut("n", modifiers: .command)
            // disables the command when no receipt window is active
            .disabled(addTaskAction == nil)
        }
    }
}

@main
// starts the application and defines its main window scene
struct TaskReceiptApp: App {

    // connects SwiftUI's app lifecycle to the AppKit delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    // creates one shared task store for all views in the app
    @StateObject private var store = TodoStore()

    // builds the receipt window and installs the app menu commands
    var body: some Scene {
        // creates the main window containing the receipt interface
        WindowGroup {
            ContentView()
                // makes the same task store available to child views
                .environmentObject(store)
                // sends google authentication callbacks to its sdk
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        // hides the standard title bar so the receipt fills the window
        .windowStyle(.hiddenTitleBar)
        // installs the custom Command-N behavior in the menu bar
        .commands {
            TaskReceiptCommands()
        }
        // this can be enabled if SwiftUI should lock resizing to content size
        // .windowResizability(.contentSize)
    }
}
