import Foundation
import CoreGraphics

/// Seam for synthesizing a Command-drag gesture via CoreGraphics.
public protocol CommandDragDispatching: Sendable {
    func dispatchCommandDrag(from start: CGPoint, to end: CGPoint, windowID: CGWindowID) -> Bool
}

/// Seam for reading the current time so debounce can be unit-tested.
public protocol InstantProviding: Sendable {
    var now: TimeInterval { get }
}

/// Production clock backed by process uptime.
public struct SystemClock: InstantProviding, Sendable {
    public init() {}

    public var now: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}

/// Production Command-drag dispatcher using CoreGraphics CGEvent.
public final class SystemCommandDragDispatcher: CommandDragDispatching {
    public init() {}

    public func dispatchCommandDrag(from start: CGPoint, to end: CGPoint, windowID: CGWindowID) -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return false }

        guard let mouseDown = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: start,
            mouseButton: .left
        ), let mouseDragged = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDragged,
            mouseCursorPosition: end,
            mouseButton: .left
        ), let mouseUp = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: end,
            mouseButton: .left
        ) else {
            return false
        }

        let windowField = CGEventField(rawValue: 0x33) ?? .eventSourceUserData
        for event in [mouseDown, mouseDragged, mouseUp] {
            event.flags = .maskCommand
            event.setIntegerValueField(windowField, value: Int64(windowID))
        }

        mouseDown.post(tap: .cghidEventTap)
        mouseDragged.post(tap: .cghidEventTap)
        mouseUp.post(tap: .cghidEventTap)
        return true
    }
}

/// Coordinates Arrange Mode pin/unpin by synthesizing ⌘ + Drag across the Divider Item.
@MainActor
public final class ItemArranger {
    public static let debounceInterval: TimeInterval = 0.3

    private let dispatcher: CommandDragDispatching
    private let clock: InstantProviding
    private var lastOperationAt: TimeInterval?

    public private(set) var busyWindowID: CGWindowID?

    public init(
        dispatcher: CommandDragDispatching = SystemCommandDragDispatcher(),
        clock: InstantProviding = SystemClock()
    ) {
        self.dispatcher = dispatcher
        self.clock = clock
    }

    /// Drags the item across the Divider Item to toggle Pinned / Unpinned.
    /// Rejects immovable items, in-flight operations, and calls inside the 0.3s debounce window.
    @discardableResult
    public func togglePin(window: StatusItemWindow, dividerBounds: CGRect) -> Bool {
        guard !window.isImmovable else { return false }
        guard busyWindowID == nil else { return false }

        let now = clock.now
        if let lastOperationAt, now - lastOperationAt < Self.debounceInterval {
            return false
        }

        let start = CGPoint(x: window.bounds.midX, y: window.bounds.midY)
        let targetX = ItemLayout.dragTargetX(itemBounds: window.bounds, dividerBounds: dividerBounds)
        let end = CGPoint(x: targetX, y: window.bounds.midY)

        busyWindowID = window.windowID
        let success = dispatcher.dispatchCommandDrag(from: start, to: end, windowID: window.windowID)
        if success {
            lastOperationAt = now
        } else {
            busyWindowID = nil
        }
        return success
    }

    /// Clears the in-flight loading state after debounce / visual feedback completes.
    public func markIdle() {
        busyWindowID = nil
    }
}
