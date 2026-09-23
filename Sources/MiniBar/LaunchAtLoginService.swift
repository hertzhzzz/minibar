import Foundation
import ServiceManagement

/// Registration state of the main app as a login item, mirroring `SMAppService.Status`.
public enum LoginItemRegistrationStatus: Equatable, Sendable {
    case enabled
    case notRegistered
    case requiresApproval
    case notFound
}

/// Seam over `SMAppService.mainApp` so tests never touch the real login-item registry.
@MainActor
public protocol LoginItemRegistering: AnyObject {
    var status: LoginItemRegistrationStatus { get }
    func register() throws
    func unregister() throws
}

/// Preference toggle for launching MiniBar at login.
@MainActor
public final class LaunchAtLoginService {
    private let loginItem: LoginItemRegistering

    public init(loginItem: LoginItemRegistering = SMAppServiceLoginItem()) {
        self.loginItem = loginItem
    }

    public var isEnabled: Bool {
        loginItem.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard loginItem.status != .enabled else { return }
            try loginItem.register()
        } else {
            switch loginItem.status {
            case .notRegistered, .notFound:
                return
            case .enabled, .requiresApproval:
                try loginItem.unregister()
            }
        }
    }
}

/// Production adapter over `SMAppService.mainApp`.
@MainActor
public final class SMAppServiceLoginItem: LoginItemRegistering {
    public init() {}

    public var status: LoginItemRegistrationStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        case .notRegistered:
            return .notRegistered
        @unknown default:
            return .notRegistered
        }
    }

    public func register() throws {
        try SMAppService.mainApp.register()
    }

    public func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}
