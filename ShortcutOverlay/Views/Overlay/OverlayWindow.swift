import AppKit
import SwiftUI

/// A floating, non-activating overlay window that displays shortcuts
class OverlayWindow: NSPanel {

    // MARK: - Initialization

    init<Content: View>(contentView: Content) {
        // Calculate 80% of screen size
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        let windowWidth = screenFrame.width * 0.8
        let windowHeight = screenFrame.height * 0.8

        // Create hosting controller for SwiftUI content
        let hostingView = NSHostingView(rootView: contentView)

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Window configuration
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.contentView = hostingView

        // Center on screen
        self.center()

        // Start invisible
        self.alphaValue = 0
        self.animationBehavior = .default
    }

    // MARK: - Show/Hide

    /// Show the overlay with animation
    func show(animated: Bool = true) {
        self.makeKeyAndOrderFront(nil)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1  // Fast fade-in for instant feel
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().alphaValue = 1.0
            }
        } else {
            self.alphaValue = 1.0
        }
    }

    /// Hide the overlay with animation
    func hide(animated: Bool = true) {
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1  // Fast fade-out for snappy feel
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.animator().alphaValue = 0.0
            }, completionHandler: {
                self.orderOut(nil)
            })
        } else {
            self.alphaValue = 0.0
            self.orderOut(nil)
        }
    }

    // MARK: - Window Behavior Overrides

    /// Allow window to become key for search field input
    /// The .nonactivatingPanel style mask ensures we don't disruptively steal focus
    override var canBecomeKey: Bool {
        return true
    }

    /// Prevent window from becoming main
    override var canBecomeMain: Bool {
        return false
    }

    // MARK: - Positioning

    /// Center the window on the screen with the mouse cursor
    func centerOnActiveScreen() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = self.frame

            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2

            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    /// Update content size and re-center
    func updateContentSize(_ size: NSSize) {
        let currentCenter = NSPoint(
            x: frame.midX,
            y: frame.midY
        )

        self.setContentSize(size)

        // Re-center on same point
        self.setFrameOrigin(NSPoint(
            x: currentCenter.x - size.width / 2,
            y: currentCenter.y - size.height / 2
        ))
    }
}
