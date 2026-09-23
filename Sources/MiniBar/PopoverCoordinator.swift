import AppKit
import SwiftUI

/// Manages the NSPopover lifecycle, attaching to the ControlItem status bar button.
@MainActor
public final class PopoverCoordinator: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let scanner: MenuBarScanner
    private let clickProxy: ClickProxyService
    private weak var anchorButton: NSStatusBarButton?
    public var onDividerMomentaryRestore: (() -> Void)?
    public var onDividerReFold: (() -> Void)?

    public init(
        scanner: MenuBarScanner = MenuBarScanner(),
        clickProxy: ClickProxyService = ClickProxyService()
    ) {
        self.scanner = scanner
        self.clickProxy = clickProxy
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
            guard let self = self else { return }
            // Close the popover immediately to avoid obscuring the opened menu
            self.close()

            // Find matching window from scanned list
            if let window = managed.first(where: { $0.windowID == item.id }) {
                self.clickProxy.trigger(
                    window: window,
                    onDividerMomentaryRestore: self.onDividerMomentaryRestore,
                    onDividerReFold: self.onDividerReFold
                )
            }
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
