import Foundation
import CoreGraphics
import Testing
@testable import MiniBar

final class MockClock: InstantProviding, @unchecked Sendable {
    var now: TimeInterval

    init(now: TimeInterval) {
        self.now = now
    }
}

final class MockCommandDragDispatcher: CommandDragDispatching, @unchecked Sendable {
    private(set) var starts: [CGPoint] = []
    private(set) var ends: [CGPoint] = []
    private(set) var windowIDs: [CGWindowID] = []
    var shouldSucceed = true

    func dispatchCommandDrag(from start: CGPoint, to end: CGPoint, windowID: CGWindowID) -> Bool {
        starts.append(start)
        ends.append(end)
        windowIDs.append(windowID)
        return shouldSucceed
    }
}

@MainActor
struct ItemArrangerTests {
    private let dividerBounds = CGRect(x: 800, y: 0, width: 8, height: 24)

    private func makeWindow(
        id: CGWindowID = 42,
        x: CGFloat,
        width: CGFloat = 30,
        isImmovable: Bool = false
    ) -> StatusItemWindow {
        StatusItemWindow(
            windowID: id,
            ownerPID: 1234,
            ownerName: "TestApp",
            title: "Test",
            bounds: CGRect(x: x, y: 0, width: width, height: 24),
            isImmovable: isImmovable
        )
    }

    @Test func togglePin_unpinnedItem_dragsToRightOfDivider() {
        let dispatcher = MockCommandDragDispatcher()
        let arranger = ItemArranger(dispatcher: dispatcher, clock: MockClock(now: 1))
        let window = makeWindow(x: 700)

        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == true)
        #expect(dispatcher.starts == [CGPoint(x: 715, y: 12)])
        #expect(dispatcher.ends == [CGPoint(x: 816, y: 12)])
        #expect(dispatcher.windowIDs == [42])
        #expect(arranger.busyWindowID == 42)
    }

    @Test func togglePin_pinnedItem_dragsToLeftOfDivider() {
        let dispatcher = MockCommandDragDispatcher()
        let arranger = ItemArranger(dispatcher: dispatcher, clock: MockClock(now: 1))
        let window = makeWindow(id: 7, x: 820, width: 24)

        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == true)
        #expect(dispatcher.starts == [CGPoint(x: 832, y: 12)])
        #expect(dispatcher.ends == [CGPoint(x: 792, y: 12)])
        #expect(dispatcher.windowIDs == [7])
    }

    @Test func togglePin_rejectsImmovableItem() {
        let dispatcher = MockCommandDragDispatcher()
        let arranger = ItemArranger(dispatcher: dispatcher, clock: MockClock(now: 1))
        let window = makeWindow(x: 700, isImmovable: true)

        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == false)
        #expect(dispatcher.starts.isEmpty)
        #expect(arranger.busyWindowID == nil)
    }

    @Test func togglePin_ignoresCallsWithinDebounceInterval() {
        let clock = MockClock(now: 10.0)
        let dispatcher = MockCommandDragDispatcher()
        let arranger = ItemArranger(dispatcher: dispatcher, clock: clock)
        let window = makeWindow(x: 700)

        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == true)
        #expect(dispatcher.starts.count == 1)
        arranger.markIdle()

        clock.now = 10.2
        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == false)
        #expect(dispatcher.starts.count == 1)

        clock.now = 10.3
        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == true)
        #expect(dispatcher.starts.count == 2)
    }

    @Test func togglePin_rejectsWhileBusy() {
        let clock = MockClock(now: 1)
        let dispatcher = MockCommandDragDispatcher()
        let arranger = ItemArranger(dispatcher: dispatcher, clock: clock)
        let window = makeWindow(x: 700)

        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == true)
        clock.now = 2
        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == false)
        #expect(dispatcher.starts.count == 1)

        arranger.markIdle()
        #expect(arranger.busyWindowID == nil)
        #expect(arranger.togglePin(window: window, dividerBounds: dividerBounds) == true)
        #expect(dispatcher.starts.count == 2)
    }
}
