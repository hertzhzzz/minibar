import AppKit

/// Wraps a real `NSStatusItem` so `StatusItemCoordinator` can drive it through `StatusItemHandle`.
@MainActor
final class NSStatusItemHandleAdapter: NSObject, StatusItemHandle {
    let statusItem: NSStatusItem
    var action: (() -> Void)?

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        super.init()
        statusItem.button?.target = self
        statusItem.button?.action = #selector(buttonClicked)
    }

    @objc private func buttonClicked() {
        action?()
    }

    var length: CGFloat {
        get { statusItem.length }
        set { statusItem.length = newValue }
    }

    var rawButton: NSStatusBarButton? {
        statusItem.button
    }

    var symbolName: String? {
        didSet {
            guard let symbolName else {
                statusItem.button?.image = nil
                return
            }
            statusItem.button?.image = NSImage(
                systemSymbolName: symbolName,
                accessibilityDescription: nil
            )
        }
    }
}

/// Production `StatusBarInstalling` backed by `NSStatusBar.system`.
@MainActor
final class NSStatusBarInstaller: StatusBarInstalling {
    func makeStatusItem(length: CGFloat) -> StatusItemHandle {
        let item = NSStatusBar.system.statusItem(withLength: length)
        return NSStatusItemHandleAdapter(statusItem: item)
    }
}
