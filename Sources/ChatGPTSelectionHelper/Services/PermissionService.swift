import AppKit
import ApplicationServices
import Foundation

final class PermissionService {
    private let accessibilitySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

    func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    func openAccessibilitySettings() {
        guard let url = accessibilitySettingsURL else { return }
        NSWorkspace.shared.open(url)
    }
}
