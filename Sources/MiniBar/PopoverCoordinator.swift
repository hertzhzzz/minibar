import AppKit
import SwiftUI

/// Manages the NSPopover lifecycle, attaching to the ControlItem status bar button.
@MainActor
public final class PopoverCoordinator: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let scanner: MenuBarScanner
    private let clickProxy: ClickProxyService
    private let itemArranger: ItemArranger
    private let launchAtLogin: LaunchAtLoginService
    private let contentModel = PopoverContentModel()
    private var managedWindows: [StatusItemWindow] = []
    private var dividerBounds: CGRect = .zero
    private weak var anchorButton: NSStatusBarButton?
    public var onDividerMomentaryRestore: (() -> Void)?
    public var onDividerReFold: (() -> Void)?
    public var onPopoverDidClose: (() -> Void)?

    public init(
        scanner: MenuBarScanner = MenuBarScanner(),
        clickProxy: ClickProxyService = ClickProxyService(),
        itemArranger: ItemArranger = ItemArranger(),
        launchAtLogin: LaunchAtLoginService = LaunchAtLoginService()
    ) {
        self.scanner = scanner
        self.clickProxy = clickProxy
        self.itemArranger = itemArranger
        self.launchAtLogin = launchAtLogin
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

        contentModel.isArrangeMode = false
        contentModel.busyWindowID = nil
        contentModel.isLaunchAtLogin = launchAtLogin.isEnabled
        itemArranger.markIdle()
        refreshItems()

        let contentView = PopoverGridView(
            model: contentModel,
            onItemClicked: { [weak self] item in
                self?.handleItemClicked(item)
            },
            onLaunchAtLoginChanged: { [weak self] enabled in
                self?.handleLaunchAtLoginChanged(enabled)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )

        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        button.window?.makeKey()
    }

    public func close() {
        popover.performClose(nil)
    }

    public func popoverDidClose(_ notification: Notification) {
        onPopoverDidClose?()
    }

    private func refreshItems() {
        let (managed, _) = scanner.scanStatusWindows()
        managedWindows = managed
        dividerBounds = ItemLayout.dividerBounds(from: scanner.scanOwnStatusWindows()) ?? .zero

        contentModel.items = managed.map { window in
            PopoverItemViewModel(
                id: window.windowID,
                title: window.title,
                ownerName: window.ownerName,
                icon: scanner.icon(for: window),
                pinState: ItemLayout.pinState(itemBounds: window.bounds, dividerBounds: dividerBounds)
            )
        }
    }

    private func handleItemClicked(_ item: PopoverItemViewModel) {
        guard let window = managedWindows.first(where: { $0.windowID == item.id }) else { return }

        if contentModel.isArrangeMode {
            handleArrange(item: item, window: window)
        } else {
            close()
            clickProxy.trigger(
                window: window,
                onDividerMomentaryRestore: onDividerMomentaryRestore,
                onDividerReFold: onDividerReFold
            )
        }
    }

    private func handleArrange(item: PopoverItemViewModel, window: StatusItemWindow) {
        guard itemArranger.togglePin(window: window, dividerBounds: dividerBounds) else { return }

        contentModel.busyWindowID = item.id
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(ItemArranger.debounceInterval))
            guard let self else { return }
            self.itemArranger.markIdle()
            self.refreshItems()
            self.contentModel.busyWindowID = nil
        }
    }

    private func handleLaunchAtLoginChanged(_ enabled: Bool) {
        try? launchAtLogin.setEnabled(enabled)
        contentModel.isLaunchAtLogin = launchAtLogin.isEnabled
    }
}
