import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {

    let taskCount: Int

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            configure(view.window)
        }

        return view
    }

    func updateNSView(
        _ nsView: NSView,
        context: Context
    ) {
        DispatchQueue.main.async {
            configure(nsView.window)
            resizeWindow(nsView.window)
        }
    }

    // MARK: - Window Setup

    private func configure(_ window: NSWindow?) {
        guard let window else { return }

        // Drag window by clicking its background
        window.isMovableByWindowBackground = true

        // Title bar appearance
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)

        // Receipt background
        window.backgroundColor = NSColor(
            red: 0.975,
            green: 0.972,
            blue: 0.955,
            alpha: 1.0
        )

        window.isOpaque = true
        window.hasShadow = true

        // Normal Mac buttons
        window.standardWindowButton(.closeButton)?
            .isHidden = false

        window.standardWindowButton(.miniaturizeButton)?
            .isHidden = false

        window.standardWindowButton(.zoomButton)?
            .isHidden = false
    }

    // MARK: - Auto Resize

    private func resizeWindow(_ window: NSWindow?) {
        guard
            let window,
            let contentView = window.contentView
        else {
            return
        }

        // Save exactly where the top-left corner currently is
        let topLeft = NSPoint(
            x: window.frame.minX,
            y: window.frame.maxY
        )

        // Figure out how tall the SwiftUI content wants to be
        let fittingSize = contentView.fittingSize

        // Keep the receipt within the usable screen height. The task list
        // becomes scrollable when its content needs more room than this.
        let screen = window.screen ?? NSScreen.main
        let maximumHeight = max(
            320,
            (screen?.visibleFrame.height ?? fittingSize.height) - 40
        )
        let contentHeight = min(fittingSize.height, maximumHeight)

        // Resize only the content
        window.setContentSize(
            NSSize(
                width: fittingSize.width,
                height: contentHeight
            )
        )

        // Put the window back at the exact same top-left position
        window.setFrameTopLeftPoint(topLeft)
    }
}
