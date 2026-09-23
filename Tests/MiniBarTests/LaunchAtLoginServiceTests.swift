import Foundation
import Testing
@testable import MiniBar

@MainActor
final class MockLoginItem: LoginItemRegistering {
    var status: LoginItemRegistrationStatus
    var statusAfterRegister: LoginItemRegistrationStatus = .enabled
    var registerError: Error?
    var unregisterError: Error?
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0

    init(status: LoginItemRegistrationStatus) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        if let registerError {
            throw registerError
        }
        status = statusAfterRegister
    }

    func unregister() throws {
        unregisterCallCount += 1
        if let unregisterError {
            throw unregisterError
        }
        status = .notRegistered
    }
}

private struct FakeLoginItemError: Error, Equatable {}

@MainActor
struct LaunchAtLoginServiceTests {
    @Test func setEnabled_true_registersWhenNotRegistered() throws {
        let loginItem = MockLoginItem(status: .notRegistered)
        let service = LaunchAtLoginService(loginItem: loginItem)

        try service.setEnabled(true)

        #expect(loginItem.registerCallCount == 1)
        #expect(loginItem.unregisterCallCount == 0)
        #expect(service.isEnabled)
    }

    @Test func setEnabled_false_unregistersWhenEnabled() throws {
        let loginItem = MockLoginItem(status: .enabled)
        let service = LaunchAtLoginService(loginItem: loginItem)

        try service.setEnabled(false)

        #expect(loginItem.unregisterCallCount == 1)
        #expect(loginItem.registerCallCount == 0)
        #expect(!service.isEnabled)
    }

    @Test func setEnabled_true_skipsRegisterWhenAlreadyEnabled() throws {
        let loginItem = MockLoginItem(status: .enabled)
        let service = LaunchAtLoginService(loginItem: loginItem)

        try service.setEnabled(true)

        #expect(loginItem.registerCallCount == 0)
        #expect(service.isEnabled)
    }

    @Test func setEnabled_false_skipsUnregisterWhenNotRegistered() throws {
        let loginItem = MockLoginItem(status: .notRegistered)
        let service = LaunchAtLoginService(loginItem: loginItem)

        try service.setEnabled(false)

        #expect(loginItem.unregisterCallCount == 0)
        #expect(!service.isEnabled)
    }

    @Test func isEnabled_isFalseWhenRequiresApproval() {
        let service = LaunchAtLoginService(loginItem: MockLoginItem(status: .requiresApproval))
        #expect(!service.isEnabled)
    }

    @Test func setEnabled_false_unregistersWhenRequiresApproval() throws {
        let loginItem = MockLoginItem(status: .requiresApproval)
        let service = LaunchAtLoginService(loginItem: loginItem)

        try service.setEnabled(false)

        #expect(loginItem.unregisterCallCount == 1)
        #expect(!service.isEnabled)
    }

    @Test func setEnabled_true_whenRequiresApproval_registersButStaysDisabled() throws {
        let loginItem = MockLoginItem(status: .requiresApproval)
        loginItem.statusAfterRegister = .requiresApproval
        let service = LaunchAtLoginService(loginItem: loginItem)

        try service.setEnabled(true)

        #expect(loginItem.registerCallCount == 1)
        #expect(!service.isEnabled)
    }

    @Test func setEnabled_true_propagatesRegistrationError() {
        let loginItem = MockLoginItem(status: .notRegistered)
        loginItem.registerError = FakeLoginItemError()
        let service = LaunchAtLoginService(loginItem: loginItem)

        #expect(throws: FakeLoginItemError.self) {
            try service.setEnabled(true)
        }
        #expect(!service.isEnabled)
    }
}
