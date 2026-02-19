import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = AppCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        coordinator.start()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
withExtendedLifetime(delegate) {
    app.delegate = delegate
    app.run()
}
