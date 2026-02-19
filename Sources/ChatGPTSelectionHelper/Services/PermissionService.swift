import AppKit
import ApplicationServices
import Foundation

final class PermissionService {
    private let accessibilitySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

    @MainActor
    func hasAccessibilityPermission(promptIfNeeded: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": promptIfNeeded] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        guard let url = accessibilitySettingsURL else { return }
        NSWorkspace.shared.open(url)
    }

    func runningAppIdentitySummary() -> String {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown.bundle.id"
        let bundlePath = Bundle.main.bundlePath
        let executablePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments.first ?? "unknown"
        return "Bundle ID: \(bundleID)\nBundle Path: \(bundlePath)\nExecutable: \(executablePath)"
    }
}
