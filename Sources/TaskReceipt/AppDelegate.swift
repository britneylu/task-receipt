import SwiftUI
import AppKit

// performs AppKit setup that is not exposed by the SwiftUI app lifecycle
final class AppDelegate: NSObject, NSApplicationDelegate {

    // makes TaskReceipt a normal foreground app when it finishes launching
    func applicationDidFinishLaunching(_ notification: Notification) {
        // shows the app in the Dock and gives it a menu bar
        NSApp.setActivationPolicy(.regular)

        // activates the app after its first window has been created
        DispatchQueue.main.async {
            NSApp.activate()
        }
    }
}
