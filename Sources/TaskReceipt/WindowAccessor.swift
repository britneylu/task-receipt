import SwiftUI
import AppKit

// gives SwiftUI access to settings and sizing on its underlying NSWindow
struct WindowAccessor: NSViewRepresentable {

    // causes SwiftUI to update this bridge whenever the task count changes
    let taskCount: Int

    // creates an invisible AppKit view that can locate its parent window
    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        // waits until the view has been attached before configuring the window
        DispatchQueue.main.async {
            configure(view.window)
        }

        return view
    }

    // reconfigures and resizes the window after SwiftUI content changes
    func updateNSView(
        _ nsView: NSView,
        context: Context
    ) {
        // runs after the current layout pass has produced a fitting size
        DispatchQueue.main.async {
            configure(nsView.window)
            resizeWindow(nsView.window)
        }
    }

    // mark: - Window Setup

    // applies the receipt appearance and normal macOS window behavior
    private func configure(_ window: NSWindow?) {
        // stops until the invisible view belongs to a window
        guard let window else { return }

        // drag window by clicking its background
        window.isMovableByWindowBackground = true

        // title bar appearance
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)

        // receipt background
        window.backgroundColor = NSColor(
            red: 0.975,
            green: 0.972,
            blue: 0.955,
            alpha: 1.0
        )

        // keeps the window solid and gives it the normal macOS shadow
        window.isOpaque = true
        window.hasShadow = true

        // normal Mac buttons
        window.standardWindowButton(.closeButton)?
            .isHidden = false

        window.standardWindowButton(.miniaturizeButton)?
            .isHidden = false

        window.standardWindowButton(.zoomButton)?
            .isHidden = false
    }

    // mark: - Auto Resize

    // fits the window to its content without letting it exceed the screen
    private func resizeWindow(_ window: NSWindow?) {
        // resizing needs both a window and its root content view
        guard
            let window,
            let contentView = window.contentView
        else {
            return
        }

        // save exactly where the top-left corner currently is
        let topLeft = NSPoint(
            x: window.frame.minX,
            y: window.frame.maxY
        )

        // figure out how tall the SwiftUI content wants to be
        let fittingSize = contentView.fittingSize

        // keep the receipt within the usable screen height. The task list
        // becomes scrollable when its content needs more room than this
        // uses the window's current display, falling back to the main display
        let screen = window.screen ?? NSScreen.main
        let maximumHeight = max(
            320,
            (screen?.visibleFrame.height ?? fittingSize.height) - 40
        )
        // chooses the content height unless it is taller than the screen limit
        let contentHeight = min(fittingSize.height, maximumHeight)

        // resize only the content
        window.setContentSize(
            NSSize(
                width: fittingSize.width,
                height: contentHeight
            )
        )

        // put the window back at the exact same top-left position
        window.setFrameTopLeftPoint(topLeft)
    }
}
