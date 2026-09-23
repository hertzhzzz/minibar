import Foundation
import CoreGraphics
import AppKit
import Testing
@testable import MiniBar

@MainActor
final class FakeStatusItemHandle: StatusItemHandle {
    var length: CGFloat
    var symbolName: String?
    var action: (() -> Void)?
    var rawButton: NSStatusBarButton? = nil

    init(length: CGFloat) {
        self.length = length
    }
}

@MainActor
final class FakeStatusBarInstaller: StatusBarInstalling {
    private(set) var createdItems: [FakeStatusItemHandle] = []

    func makeStatusItem(length: CGFloat) -> StatusItemHandle {
        let item = FakeStatusItemHandle(length: length)
        createdItems.append(item)
        return item
    }
}

@MainActor
struct StatusItemCoordinatorTests {
    @Test func register_createsControlItemWithSymbolAndDividerItemWithNoImage() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)

        coordinator.register()

        #expect(fakeStatusBar.createdItems.count == 2)
        #expect(coordinator.controlItem?.symbolName == "menubar.dock.rectangle")
        #expect(coordinator.dividerItem?.symbolName == nil)
    }

    @Test func register_createsControlItemBeforeDividerItem() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)

        coordinator.register()

        #expect(fakeStatusBar.createdItems[0] === coordinator.controlItem as? FakeStatusItemHandle)
        #expect(fakeStatusBar.createdItems[1] === coordinator.dividerItem as? FakeStatusItemHandle)
    }

    @Test func register_dividerLengthIs10000_folded() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)

        coordinator.register()

        #expect(coordinator.dividerItem?.length == 10000)
    }

    @Test func toggle_setsDividerLengthTo8_thenBackTo10000() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)
        coordinator.register()

        coordinator.toggle()
        #expect(coordinator.dividerItem?.length == 8)

        coordinator.toggle()
        #expect(coordinator.dividerItem?.length == 10000)
    }

    @Test func controlItemAction_triggersToggle() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)
        coordinator.register()

        #expect(coordinator.dividerItem?.length == 10000)
        coordinator.controlItem?.action?()
        #expect(coordinator.dividerItem?.length == 8)
        coordinator.controlItem?.action?()
        #expect(coordinator.dividerItem?.length == 10000)
    }

    @Test func handlePopoverDidClose_foldsWhenExpanded() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)
        coordinator.register()

        coordinator.toggle()
        #expect(coordinator.dividerItem?.length == dividerExpandedLength)

        coordinator.handlePopoverDidClose()
        #expect(coordinator.dividerItem?.length == dividerFoldedLength)
    }

    @Test func handlePopoverDidClose_leavesFoldedStateUnchanged() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)
        coordinator.register()

        coordinator.handlePopoverDidClose()
        #expect(coordinator.dividerItem?.length == dividerFoldedLength)
    }

    @Test func prepareForTermination_restoresDividerToNormalWidthWhenFolded() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)
        coordinator.register()
        #expect(coordinator.dividerItem?.length == dividerFoldedLength)

        coordinator.prepareForTermination()
        #expect(coordinator.dividerItem?.length == dividerExpandedLength)
    }

    @Test func prepareForTermination_keepsNormalWidthWhenAlreadyExpanded() {
        let fakeStatusBar = FakeStatusBarInstaller()
        let coordinator = StatusItemCoordinator(statusBar: fakeStatusBar)
        coordinator.register()
        coordinator.toggle()

        coordinator.prepareForTermination()
        #expect(coordinator.dividerItem?.length == dividerExpandedLength)
    }
}
