import Foundation
import CoreGraphics
import Testing
@testable import MiniBar

@MainActor
struct PopoverCoordinatorTests {
    @Test func popoverCoordinator_initialState_isNotShown() {
        let coordinator = PopoverCoordinator()
        #expect(!coordinator.isShown)
    }

    @Test func popoverItemViewModel_displayNamePriority() {
        let item1 = PopoverItemViewModel(id: 1, title: "Title", ownerName: "Owner", icon: nil)
        #expect(item1.displayName == "Owner")

        let item2 = PopoverItemViewModel(id: 2, title: "Title", ownerName: "", icon: nil)
        #expect(item2.displayName == "Title")

        let item3 = PopoverItemViewModel(id: 3, title: "", ownerName: "", icon: nil)
        #expect(item3.displayName == "Unknown")
    }

    @Test func popoverCoordinator_withoutAnchor_doesNotCrash() {
        let coordinator = PopoverCoordinator()
        coordinator.show()
        #expect(!coordinator.isShown)
        coordinator.toggle()
        #expect(!coordinator.isShown)
    }
}
