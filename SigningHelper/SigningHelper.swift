// imports the macos interface framework used by the signing helper
import SwiftUI

// provides a minimal app target that lets xcode create the provisioning profile
@main
struct SigningHelperApp: App {
    // creates the helper window required by a macos app target
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}
