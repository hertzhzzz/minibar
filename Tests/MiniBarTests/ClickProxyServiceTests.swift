import Foundation
import CoreGraphics
import Testing
@testable import MiniBar

final class MockAccessibilityPerformer: @unchecked Sendable, AccessibilityActionPerforming {
    var shouldSucceed: Bool
    private(set) var callCount = 0

    init(shouldSucceed: Bool) {
        self.shouldSucceed = shouldSucceed
    }

    func performAction(pid: pid_t, windowBounds: CGRect) -> Bool {
        callCount += 1
        return shouldSucceed
    }
}

final class MockSyntheticEventDispatcher: @unchecked Sendable, SyntheticEventDispatching {
    var shouldSucceed: Bool
    private(set) var dispatchedPoints: [CGPoint] = []
    private(set) var dispatchedWindowIDs: [CGWindowID] = []

    init(shouldSucceed: Bool) {
        self.shouldSucceed = shouldSucceed
    }

    func dispatchClick(at point: CGPoint, windowID: CGWindowID) -> Bool {
        dispatchedPoints.append(point)
        dispatchedWindowIDs.append(windowID)
        return shouldSucceed
    }
}

@MainActor
struct ClickProxyServiceTests {
    private func makeTestWindow(id: CGWindowID = 100, pid: pid_t = 1234) -> StatusItemWindow {
        StatusItemWindow(
            windowID: id,
            ownerPID: pid,
            ownerName: "TestApp",
            title: "Test",
            bounds: CGRect(x: 100, y: 0, width: 30, height: 30),
            isImmovable: false
        )
    }

    @Test func trigger_prefersTrack1_whenAccessibilitySucceeds() {
        let axPerformer = MockAccessibilityPerformer(shouldSucceed: true)
        let eventDispatcher = MockSyntheticEventDispatcher(shouldSucceed: true)
        let service = ClickProxyService(
            axPerformer: axPerformer,
            eventDispatcher: eventDispatcher
        )

        var restoredDivider = false
        var reFoldedDivider = false

        let result = service.trigger(
            window: makeTestWindow(),
            onDividerMomentaryRestore: { restoredDivider = true },
            onDividerReFold: { reFoldedDivider = true }
        )

        #expect(result == true)
        #expect(axPerformer.callCount == 1)
        #expect(eventDispatcher.dispatchedPoints.isEmpty)
        #expect(!restoredDivider) // Fallback hooks should NOT be called
        #expect(!reFoldedDivider)
    }

    @Test func trigger_fallsBackToTrack2_whenAccessibilityFails() {
        let axPerformer = MockAccessibilityPerformer(shouldSucceed: false)
        let eventDispatcher = MockSyntheticEventDispatcher(shouldSucceed: true)
        let service = ClickProxyService(
            axPerformer: axPerformer,
            eventDispatcher: eventDispatcher
        )

        var restoredDivider = false
        var reFoldedDivider = false

        let window = makeTestWindow(id: 42)
        let result = service.trigger(
            window: window,
            onDividerMomentaryRestore: { restoredDivider = true },
            onDividerReFold: { reFoldedDivider = true }
        )

        #expect(result == true)
        #expect(axPerformer.callCount == 1)
        #expect(eventDispatcher.dispatchedPoints.count == 1)
        #expect(eventDispatcher.dispatchedWindowIDs.first == 42)
        #expect(restoredDivider) // Fallback divider restoration triggered
        #expect(reFoldedDivider) // Fallback divider refolding triggered
    }
}
