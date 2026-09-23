import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

/// Seam for executing accessibility actions on applications.
public protocol AccessibilityActionPerforming: Sendable {
    func performAction(pid: pid_t, windowBounds: CGRect) -> Bool
}

/// Seam for synthesizing mouse click events via CoreGraphics.
public protocol SyntheticEventDispatching: Sendable {
    func dispatchClick(at point: CGPoint, windowID: CGWindowID) -> Bool
}

/// Default Accessibility Action Performer using macOS AXUIElement APIs.
public final class SystemAccessibilityPerformer: AccessibilityActionPerforming {
    public init() {}

    public func performAction(pid: pid_t, windowBounds: CGRect) -> Bool {
        let appElement = AXUIElementCreateApplication(pid)

        var childrenVal: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXChildrenAttribute as CFString, &childrenVal) == .success,
              let bars = childrenVal as? [AXUIElement] else {
            return false
        }

        for bar in bars {
            var subChildren: AnyObject?
            guard AXUIElementCopyAttributeValue(bar, kAXChildrenAttribute as CFString, &subChildren) == .success,
                  let items = subChildren as? [AXUIElement] else {
                continue
            }

            for item in items {
                var role: AnyObject?
                AXUIElementCopyAttributeValue(item, kAXRoleAttribute as CFString, &role)
                if (role as? String) == "AXMenuBarItem" {
                    // Try AXPress or AXShowMenu
                    if AXUIElementPerformAction(item, kAXPressAction as CFString) == .success {
                        return true
                    }
                    if AXUIElementPerformAction(item, "AXShowMenu" as CFString) == .success {
                        return true
                    }
                }
            }
        }

        return false
    }
}

/// Default synthetic event dispatcher using CoreGraphics CGEvent.
public final class SystemSyntheticEventDispatcher: SyntheticEventDispatching {
    public init() {}

    public func dispatchClick(at point: CGPoint, windowID: CGWindowID) -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return false }

        guard let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
              let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
            return false
        }

        // Tag event with window ID to direct it to the target status item
        mouseDown.setIntegerValueField(CGEventField(rawValue: 0x33) ?? .eventSourceUserData, value: Int64(windowID))
        mouseUp.setIntegerValueField(CGEventField(rawValue: 0x33) ?? .eventSourceUserData, value: Int64(windowID))

        mouseDown.post(tap: .cghidEventTap)
        mouseUp.post(tap: .cghidEventTap)
        return true
    }
}

/// Service that coordinates double-track click delivery to status items.
@MainActor
public final class ClickProxyService {
    private let axPerformer: AccessibilityActionPerforming
    private let eventDispatcher: SyntheticEventDispatching
    private let updateMask: MenuBarUpdateMask

    public init(
        axPerformer: AccessibilityActionPerforming = SystemAccessibilityPerformer(),
        eventDispatcher: SyntheticEventDispatching = SystemSyntheticEventDispatcher(),
        updateMask: MenuBarUpdateMask = MenuBarUpdateMask()
    ) {
        self.axPerformer = axPerformer
        self.eventDispatcher = eventDispatcher
        self.updateMask = updateMask
    }

    /// Primary entry point: Attempts Track 1 (AX) first; falls back to Track 2 (Masked synthetic CGEvent).
    /// Calls `onDividerMomentaryRestore` if fallback requires temporarily setting divider length to 8pt.
    @discardableResult
    public func trigger(
        window: StatusItemWindow,
        onDividerMomentaryRestore: (() -> Void)? = nil,
        onDividerReFold: (() -> Void)? = nil
    ) -> Bool {
        // Track 1: Accessibility Action (preferred, no cursor jump)
        if axPerformer.performAction(pid: window.ownerPID, windowBounds: window.bounds) {
            return true
        }

        // Track 2: Fallback via MenuBarUpdateMask + Momentary Divider Restore + CGEvent
        updateMask.freeze()
        defer {
            updateMask.unfreeze()
            onDividerReFold?()
        }

        onDividerMomentaryRestore?()

        let clickPoint = CGPoint(
            x: window.bounds.midX,
            y: window.bounds.midY
        )

        return eventDispatcher.dispatchClick(at: clickPoint, windowID: window.windowID)
    }
}
