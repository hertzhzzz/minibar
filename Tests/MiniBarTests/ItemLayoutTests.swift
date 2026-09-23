import Foundation
import CoreGraphics
import Testing
@testable import MiniBar

struct ItemLayoutTests {
    private let dividerBounds = CGRect(x: 800, y: 0, width: 8, height: 24)

    @Test func pinState_leftOfDivider_isUnpinned() {
        let itemBounds = CGRect(x: 700, y: 0, width: 30, height: 24)
        #expect(ItemLayout.pinState(itemBounds: itemBounds, dividerBounds: dividerBounds) == .unpinned)
    }

    @Test func pinState_rightOfDivider_isPinned() {
        let itemBounds = CGRect(x: 820, y: 0, width: 24, height: 24)
        #expect(ItemLayout.pinState(itemBounds: itemBounds, dividerBounds: dividerBounds) == .pinned)
    }

    @Test func dragTargetX_unpinnedItem_crossesToRightOfDivider() {
        let itemBounds = CGRect(x: 700, y: 0, width: 30, height: 24)
        #expect(ItemLayout.dragTargetX(itemBounds: itemBounds, dividerBounds: dividerBounds) == 816)
    }

    @Test func dragTargetX_pinnedItem_crossesToLeftOfDivider() {
        let itemBounds = CGRect(x: 820, y: 0, width: 24, height: 24)
        #expect(ItemLayout.dragTargetX(itemBounds: itemBounds, dividerBounds: dividerBounds) == 792)
    }

    @Test func dividerBounds_picksLeftmostOwnWindow() {
        let control = StatusItemWindow(
            windowID: 1,
            ownerPID: 1,
            ownerName: "MiniBar",
            title: "Control",
            bounds: CGRect(x: 900, y: 0, width: 24, height: 24),
            isImmovable: false
        )
        let divider = StatusItemWindow(
            windowID: 2,
            ownerPID: 1,
            ownerName: "MiniBar",
            title: "Divider",
            bounds: CGRect(x: 800, y: 0, width: 8, height: 24),
            isImmovable: false
        )

        #expect(ItemLayout.dividerBounds(from: [control, divider]) == divider.bounds)
    }

    @Test func visibleItems_hidesPinnedOutsideArrangeMode() {
        let unpinned = PopoverItemViewModel(id: 1, title: "WeChat", ownerName: "WeChat", icon: nil, pinState: .unpinned)
        let pinned = PopoverItemViewModel(id: 2, title: "Battery", ownerName: "Control Centre", icon: nil, pinState: .pinned)
        let items = [unpinned, pinned]

        let normal = ItemLayout.visibleItems(items, arrangeMode: false)
        #expect(normal.map(\.id) == [1])

        let arranging = ItemLayout.visibleItems(items, arrangeMode: true)
        #expect(arranging.map(\.id) == [1, 2])
    }
}
