import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = StatusItemCoordinator(statusBar: NSStatusBarInstaller())

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.register()
    }
}
