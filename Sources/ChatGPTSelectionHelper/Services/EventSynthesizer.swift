import AppKit
import Carbon
import Foundation

final class EventSynthesizer {
    func sendCopyShortcut() {
        sendKeyboardShortcut(keyCode: CGKeyCode(kVK_ANSI_C), flags: .maskCommand)
    }

    func sendPasteShortcut() {
        sendKeyboardShortcut(keyCode: CGKeyCode(kVK_ANSI_V), flags: .maskCommand)
    }

    private func sendKeyboardShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else {
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
