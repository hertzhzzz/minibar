import Foundation
import CoreGraphics
import AppKit

/// One status item hosted in the system status bar (Control Item or Divider Item).
@MainActor
public protocol StatusItemHandle: AnyObject {
    var length: CGFloat { get set }
    var symbolName: String? { get set }
    var action: (() -> Void)? { get set }
    var rawButton: NSStatusBarButton? { get }
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
    private let popoverCoordinator: PopoverCoordinator?
    private(set) public var controlItem: StatusItemHandle?
    private(set) public var dividerItem: StatusItemHandle?
    private var isFolded = true

    public init(
        statusBar: StatusBarInstalling,
        popoverCoordinator: PopoverCoordinator? = nil
    ) {
        self.statusBar = statusBar
        self.popoverCoordinator = popoverCoordinator
    }

    /// Creates the Control Item first, then the Divider Item, so the Divider Item
    /// lands immediately to the Control Item's left. Starts Folded (10_000).
    public func register() {
        let control = statusBar.makeStatusItem(length: controlItemLength)
        control.symbolName = "menubar.dock.rectangle"
        control.action = { [weak self] in
            self?.handleClick()
        }
        controlItem = control

        popoverCoordinator?.onPopoverDidClose = { [weak self] in
            self?.handlePopoverDidClose()
        }

        if let button = control.rawButton {
            popoverCoordinator?.setAnchorButton(button)
            popoverCoordinator?.onDividerMomentaryRestore = { [weak self] in
                self?.dividerItem?.length = dividerExpandedLength
            }
            popoverCoordinator?.onDividerReFold = { [weak self] in
                guard let self = self else { return }
                if self.isFolded {
                    self.dividerItem?.length = dividerFoldedLength
                }
            }
        }

        let divider = statusBar.makeStatusItem(length: dividerFoldedLength)
        divider.symbolName = nil
        dividerItem = divider

        isFolded = true
    }

    /// Handles click on the Control Item: expands the Divider Item before showing
    /// the popover so pin-state classification sees the 8pt layout, then folds
    /// after the popover closes.
    public func handleClick() {
        if popoverCoordinator?.isShown == true {
            toggle()
            popoverCoordinator?.close()
        } else {
            toggle()
            popoverCoordinator?.show()
        }
    }

    /// Folds after the popover dismisses (Control Item click or transient outside click)
    /// so the next open always scans pin state against the 8pt Divider Item.
    public func handlePopoverDidClose() {
        if !isFolded {
            toggle()
        }
    }

    /// Called to toggle Spacer Push: Folded (10_000) <-> Expanded (8).
    public func toggle() {
        isFolded.toggle()
        dividerItem?.length = isFolded ? dividerFoldedLength : dividerExpandedLength
    }
}
