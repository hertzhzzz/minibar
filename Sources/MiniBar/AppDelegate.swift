import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let popoverCoordinator = PopoverCoordinator()
    private lazy var coordinator = StatusItemCoordinator(
        statusBar: NSStatusBarInstaller(),
        popoverCoordinator: popoverCoordinator
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.register()
    }
}
