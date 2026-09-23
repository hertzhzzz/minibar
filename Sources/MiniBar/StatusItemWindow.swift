import Foundation
import CoreGraphics

/// Domain representation of a status bar item window detected in macOS WindowServer.
public struct StatusItemWindow: Equatable, Sendable, Identifiable {
    public var id: CGWindowID { windowID }

    public let windowID: CGWindowID
    public let ownerPID: pid_t
    public let ownerName: String
    public let title: String
    public let bounds: CGRect
    public let isImmovable: Bool

    public init(
        windowID: CGWindowID,
        ownerPID: pid_t,
        ownerName: String,
        title: String,
        bounds: CGRect,
        isImmovable: Bool
    ) {
        self.windowID = windowID
        self.ownerPID = ownerPID
        self.ownerName = ownerName
        self.title = title
        self.bounds = bounds
        self.isImmovable = isImmovable
    }
}
