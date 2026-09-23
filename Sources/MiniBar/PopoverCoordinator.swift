import AppKit
import SwiftUI

/// Manages the NSPopover lifecycle, attaching to the ControlItem status bar button.
@MainActor
public final class PopoverCoordinator: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let scanner: MenuBarScanner
    private weak var anchorButton: NSStatusBarButton?

    public init(scanner: MenuBarScanner = MenuBarScanner()) {
        self.scanner = scanner
        super.init()
        setupPopover()
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
    }

    public func setAnchorButton(_ button: NSStatusBarButton?) {
        self.anchorButton = button
    }

    public var isShown: Bool {
        popover.isShown
    }

    /// Toggles the popover open / closed.
    public func toggle() {
        if popover.isShown {
            close()
        } else {
            show()
        }
    }

    public func show() {
        guard let button = anchorButton else { return }

        // Scan current managed status items
        let (managed, _) = scanner.scanStatusWindows()

        let viewModels = managed.map { window in
            let icon = scanner.icon(for: window)
            return PopoverItemViewModel(
                id: window.windowID,
                title: window.title,
                ownerName: window.ownerName,
                icon: icon
            )
        }

        let contentView = PopoverGridView(items: viewModels) { [weak self] item in
            // Handle item click (Ticket 4 will plug in ClickProxy here)
            print("Clicked status item: \(item.displayName) (ID: \(item.id))")
            self?.close()
        }

        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController

        // Show anchored to the status bar button
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        button.window?.makeKey()
    }

    public func close() {
        popover.performClose(nil)
    }
}
