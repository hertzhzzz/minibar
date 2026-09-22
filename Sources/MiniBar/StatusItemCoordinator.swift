import Foundation
import CoreGraphics

/// One status item hosted in the system status bar (Control Item or Divider Item).
@MainActor
public protocol StatusItemHandle: AnyObject {
    var length: CGFloat { get set }
    var symbolName: String? { get set }
    var action: (() -> Void)? { get set }
}

/// Seam over `NSStatusBar.system` so tests never touch the real status bar / WindowServer.
@MainActor
public protocol StatusBarInstalling {
    func makeStatusItem(length: CGFloat) -> StatusItemHandle
}

/// Divider Item length while Folded: pushes everything to its left off-screen.
public let dividerFoldedLength: CGFloat = 10_000

/// Divider Item length while Expanded: the documented "normal width".
public let dividerExpandedLength: CGFloat = 8

/// Control Item's fixed status-bar button length.
public let controlItemLength: CGFloat = 24

/// Registers MiniBar's Control Item and Divider Item, and performs Spacer Push on toggle.
@MainActor
public final class StatusItemCoordinator {
    private let statusBar: StatusBarInstalling
    private(set) public var controlItem: StatusItemHandle?
    private(set) public var dividerItem: StatusItemHandle?
    private var isFolded = true

    public init(statusBar: StatusBarInstalling) {
        self.statusBar = statusBar
    }

    /// Creates the Control Item first, then the Divider Item, so the Divider Item
    /// lands immediately to the Control Item's left. Starts Folded (10_000).
    public func register() {
        let control = statusBar.makeStatusItem(length: controlItemLength)
        control.symbolName = "menubar.dock.rectangle"
        control.action = { [weak self] in
            self?.toggle()
        }
        controlItem = control

        let divider = statusBar.makeStatusItem(length: dividerFoldedLength)
        divider.symbolName = nil
        dividerItem = divider

        isFolded = true
    }

    /// Called on a Control Item click. Toggles Spacer Push: Folded (10_000) <-> Expanded (8).
    public func toggle() {
        isFolded.toggle()
        dividerItem?.length = isFolded ? dividerFoldedLength : dividerExpandedLength
    }
}
