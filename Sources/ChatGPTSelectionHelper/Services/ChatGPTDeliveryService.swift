import AppKit
import Foundation

@MainActor
final class ChatGPTDeliveryService {
    private let clipboard: ClipboardService
    private let events: EventSynthesizer
    private let accessibility: AccessibilityService

    init(clipboard: ClipboardService, events: EventSynthesizer, accessibility: AccessibilityService) {
        self.clipboard = clipboard
        self.events = events
        self.accessibility = accessibility
    }

    func deliverText(_ text: String, to bundleID: String, session: ClipboardSession) async -> DeliveryResult {
        guard let app = await activateOrLaunch(bundleID: bundleID) else {
            return DeliveryResult(
                focusPath: .assumedFocused,
                pasteAttempts: 0,
                pasteResult: .fail,
                errorCode: .chatGPTLaunchFailed,
                changedCountAfterPasteboardWrite: nil
            )
        }

        await sleepMs(220)

        var focusPath: FocusPath = .assumedFocused
        var attempts = 0
        var latestCount: Int?

        if accessibility.focusLikelyInputField(in: app) {
            focusPath = .axFocus
            await sleepMs(80)
        }

        let beforeFirstPasteLength = accessibility.focusedEditableValueLength(in: app)

        attempts += 1
        let firstCount = clipboard.setTemporaryString(text)
        latestCount = firstCount
        session.noteFlowClipboardChange(firstCount)
        events.sendPasteShortcut()
        await sleepMs(150)

        if verifyPasteSucceeded(in: app, beforeLength: beforeFirstPasteLength) {
            return DeliveryResult(
                focusPath: focusPath,
                pasteAttempts: attempts,
                pasteResult: .success,
                errorCode: .none,
                changedCountAfterPasteboardWrite: firstCount
            )
        }

        guard accessibility.focusLikelyInputField(in: app) else {
            return DeliveryResult(
                focusPath: focusPath,
                pasteAttempts: attempts,
                pasteResult: .fail,
                errorCode: .focusFailed,
                changedCountAfterPasteboardWrite: latestCount
            )
        }

        focusPath = .axFocus
        let beforeSecondPasteLength = accessibility.focusedEditableValueLength(in: app)
        attempts += 1
        let secondCount = clipboard.setTemporaryString(text)
        latestCount = secondCount
        session.noteFlowClipboardChange(secondCount)
        events.sendPasteShortcut()
        await sleepMs(150)

        let success = verifyPasteSucceeded(in: app, beforeLength: beforeSecondPasteLength)
        return DeliveryResult(
            focusPath: focusPath,
            pasteAttempts: attempts,
            pasteResult: success ? .success : .fail,
            errorCode: success ? .none : .pasteFailed,
            changedCountAfterPasteboardWrite: latestCount
        )
    }

    private func verifyPasteSucceeded(in app: NSRunningApplication, beforeLength: Int?) -> Bool {
        let afterLength = accessibility.focusedEditableValueLength(in: app)
        if let axDeltaSuccess = pasteValueDeltaSucceeded(beforeLength: beforeLength, afterLength: afterLength) {
            return axDeltaSuccess
        }

        // Webview-backed inputs often do not expose value attributes reliably.
        // Fall back to checking that an editable element in ChatGPT is focused.
        return accessibility.isFocusedElementEditable(in: app)
    }

    private func activateOrLaunch(bundleID: String) async -> NSRunningApplication? {
        if let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
            running.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return running
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        let launchedApp = await withCheckedContinuation { (continuation: CheckedContinuation<NSRunningApplication?, Never>) in
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, _ in
                continuation.resume(returning: app)
            }
        }

        guard let launchedApp else {
            return nil
        }
        launchedApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        return launchedApp
    }

    private func sleepMs(_ ms: UInt64) async {
        try? await Task.sleep(nanoseconds: ms * 1_000_000)
    }
}
