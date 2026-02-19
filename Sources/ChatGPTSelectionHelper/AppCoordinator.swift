import AppKit
import Foundation

final class AppCoordinator: NSObject {
    private let settingsStore = AppSettingsStore()
    private let permissionService = PermissionService()
    private let clipboardService = ClipboardService()
    private let eventSynthesizer = EventSynthesizer()
    private let accessibilityService = AccessibilityService()
    private let telemetry = TelemetryService()
    private let toast = ToastPresenter()
    private let hotkeyManager = HotkeyManager()

    private lazy var captureService = CaptureService(
        clipboard: clipboardService,
        events: eventSynthesizer,
        accessibility: accessibilityService
    )

    private lazy var deliveryService = ChatGPTDeliveryService(
        clipboard: clipboardService,
        events: eventSynthesizer,
        accessibility: accessibilityService
    )

    private var statusItem: NSStatusItem?
    private var settings: AppSettings
    private var isRunning = false
    private var settingsWindowController: SettingsWindowController?

    override init() {
        self.settings = settingsStore.load()
        super.init()
    }

    @MainActor
    func start() {
        setupMenuBar()
        registerHotkey()
    }

    @MainActor
    private func setupMenuBar() {
        let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "Ch"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Send Selection to ChatGPT", action: #selector(sendSelection), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Copy Debug Info", action: #selector(copyDebugInfo), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        status.menu = menu
        self.statusItem = status
    }

    @MainActor
    private func registerHotkey() {
        hotkeyManager.register(settings.hotkey) { [weak self] in
            Task { @MainActor in
                self?.sendSelection()
            }
        }
    }

    @objc
    @MainActor
    private func sendSelection() {
        guard !isRunning else {
            return
        }
        isRunning = true

        let totalStart = Date()
        let session = clipboardService.beginSession()

        var restoreOutcome: RestoreOutcome = .notNeeded
        var capturePath: String = "none"
        var captureLen = 0
        var focusPath: String = FocusPath.assumedFocused.rawValue
        var pasteAttempts = 0
        var pasteResult: PasteResult = .fail
        var errorCode: ErrorCode = .none
        var captureMs: Int?
        var deliveryMs: Int?

        defer {
            let outcome = clipboardService.restoreClipboard(for: session)
            restoreOutcome = outcome
            if outcome == .skippedUserChanged && errorCode == .none {
                errorCode = .restoreSkippedUserChanged
            }

            let total = Int(Date().timeIntervalSince(totalStart) * 1000)
            let report = RunReport(
                timestamp: Date(),
                capturePath: capturePath,
                captureLen: captureLen,
                focusPath: focusPath,
                pasteAttempts: pasteAttempts,
                pasteResult: pasteResult.rawValue,
                restoreOutcome: restoreOutcome.rawValue,
                errorCode: errorCode.rawValue,
                captureMs: captureMs,
                deliveryMs: deliveryMs,
                totalMs: total
            )
            telemetry.record(report)
            isRunning = false
        }

        guard permissionService.hasAccessibilityPermission() else {
            errorCode = .permissionMissing
            showAccessibilityPermissionPrompt()
            return
        }

        let captureStart = Date()
        let captureResult = captureService.captureSelection(session: session)
        captureMs = Int(Date().timeIntervalSince(captureStart) * 1000)

        capturePath = captureResult.capturePath?.rawValue ?? "none"
        captureLen = captureResult.captureLength
        errorCode = captureResult.errorCode

        guard let captured = captureResult.text, captureResult.errorCode == .none else {
            if settings.showToasts {
                toast.show("No text selected")
            }
            return
        }

        var transformed = formatSelection(captured, mode: settings.formatMode)
        let truncated = truncateSelection(transformed, maxChars: settings.maxChars)
        transformed = truncated.output
        if truncated.truncated, settings.showToasts {
            toast.show("Selection truncated to \(settings.maxChars) characters")
        }

        let deliveryStart = Date()
        let deliveryResult = deliveryService.deliverText(transformed, to: settings.chatGPTBundleID, session: session)
        deliveryMs = Int(Date().timeIntervalSince(deliveryStart) * 1000)

        focusPath = deliveryResult.focusPath.rawValue
        pasteAttempts = deliveryResult.pasteAttempts
        pasteResult = deliveryResult.pasteResult
        errorCode = deliveryResult.errorCode

        if settings.showToasts {
            if deliveryResult.pasteResult == .success {
                toast.show("Sent selection to ChatGPT")
            } else {
                toast.show("Could not insert into ChatGPT prompt")
            }
        }
    }

    @MainActor
    private func showAccessibilityPermissionPrompt() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Enable Accessibility for this app in System Settings -> Privacy & Security -> Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            permissionService.openAccessibilitySettings()
        }
    }

    @objc
    @MainActor
    private func copyDebugInfo() {
        telemetry.copyRecentDebugInfoToClipboard()
        if settings.showToasts {
            toast.show("Copied debug info")
        }
    }

    @objc
    @MainActor
    private func openSettings() {
        let controller = SettingsWindowController(settings: settings) { [weak self] updated in
            guard let self else { return }
            self.settings = updated
            self.settingsStore.save(updated)
            self.registerHotkey()
        }
        settingsWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc
    @MainActor
    private func quit() {
        NSApp.terminate(nil)
    }
}
