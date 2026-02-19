import Foundation

final class CaptureService {
    private let clipboard: ClipboardService
    private let events: EventSynthesizer
    private let accessibility: AccessibilityService

    init(clipboard: ClipboardService, events: EventSynthesizer, accessibility: AccessibilityService) {
        self.clipboard = clipboard
        self.events = events
        self.accessibility = accessibility
    }

    func captureSelection(session: ClipboardSession, timeoutMs: Int = 350) -> CaptureResult {
        let startCount = clipboard.currentChangeCount()
        events.sendCopyShortcut()

        let waitedChange = waitForPasteboardChange(from: startCount, timeoutMs: timeoutMs)
        if let changed = waitedChange {
            session.noteFlowClipboardChange(changed)
        }

        if let text = clipboard.readPlainText() {
            return CaptureResult(
                text: text,
                capturePath: .pasteboard,
                captureLength: text.count,
                errorCode: .none,
                changedCountAfterCapture: waitedChange
            )
        }

        if let fallback = accessibility.selectedTextFromFocusedElement() {
            return CaptureResult(
                text: fallback.0,
                capturePath: fallback.1,
                captureLength: fallback.0.count,
                errorCode: .none,
                changedCountAfterCapture: waitedChange
            )
        }

        return CaptureResult(
            text: nil,
            capturePath: nil,
            captureLength: 0,
            errorCode: .noSelection,
            changedCountAfterCapture: waitedChange
        )
    }

    private func waitForPasteboardChange(from initial: Int, timeoutMs: Int) -> Int? {
        let sleepInterval: useconds_t = 20_000
        let maxAttempts = max(1, timeoutMs / 20)
        for _ in 0..<maxAttempts {
            usleep(sleepInterval)
            let current = clipboard.currentChangeCount()
            if current != initial {
                return current
            }
        }
        return nil
    }
}
