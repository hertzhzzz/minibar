import Foundation
import CoreGraphics

/// Whether a managed item currently sits in the visible bar or the folded drawer.
public enum PinState: Equatable, Sendable {
    /// Remains in the visible menu bar to the right of the Divider Item.
    case pinned
    /// Pushed off-screen to the left of the Divider Item and accessed via the popover.
    case unpinned
}

/// Pure layout helpers for Arrange Mode: pin classification, drag targets, and grid filtering.
public enum ItemLayout {
    /// Distance past a Divider Item edge so WindowServer registers a section change.
    public static let dividerCrossingOffset: CGFloat = 8

    /// An item is unpinned when its center is strictly left of the Divider Item.
    public static func pinState(itemBounds: CGRect, dividerBounds: CGRect) -> PinState {
        itemBounds.midX < dividerBounds.minX ? .unpinned : .pinned
    }

    /// Target X for a ⌘ + Drag that toggles pin state by crossing the Divider Item.
    public static func dragTargetX(itemBounds: CGRect, dividerBounds: CGRect) -> CGFloat {
        switch pinState(itemBounds: itemBounds, dividerBounds: dividerBounds) {
        case .unpinned:
            return dividerBounds.maxX + dividerCrossingOffset
        case .pinned:
            return dividerBounds.minX - dividerCrossingOffset
        }
    }

    /// The Divider Item is registered after the Control Item, so it is the leftmost MiniBar window.
    public static func dividerBounds(from ownWindows: [StatusItemWindow]) -> CGRect? {
        ownWindows.min(by: { $0.bounds.minX < $1.bounds.minX })?.bounds
    }

    /// Normal mode shows only unpinned drawer items; Arrange Mode shows every managed item.
    public static func visibleItems(_ items: [PopoverItemViewModel], arrangeMode: Bool) -> [PopoverItemViewModel] {
        arrangeMode ? items : items.filter { $0.pinState == .unpinned }
    }
}
