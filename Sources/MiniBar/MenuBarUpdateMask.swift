import AppKit
import CoreGraphics

/// Full-screen visual mask that captures and freezes the display during physical clicks
/// or icon shifts to eliminate screen flicker.
@MainActor
public final class MenuBarUpdateMask {
    private var overlayWindow: NSWindow?

    public init() {}

    /// Freezes the current screen display by placing a transparent snapshot overlay over the screen.
    public func freeze() {
        guard let mainScreen = NSScreen.main else { return }
        let screenRect = mainScreen.frame

        let window = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar + 1
        window.ignoresMouseEvents = true
        window.orderFrontRegardless()

        self.overlayWindow = window
    }

    /// Dismisses and releases the update mask.
    public func unfreeze() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}
