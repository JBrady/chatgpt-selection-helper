import AppKit
import Carbon
import Foundation

final class SettingsWindowController: NSWindowController {
    private let onSave: (AppSettings) -> Void
    private var settings: AppSettings

    private let bundleField = NSTextField(string: "")
    private let maxCharsField = NSTextField(string: "")
    private let formatPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let keyCodeField = NSTextField(string: "")
    private let modifiersField = NSTextField(string: "")

    init(settings: AppSettings, onSave: @escaping (AppSettings) -> Void) {
        self.settings = settings
        self.onSave = onSave

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        super.init(window: window)

        setupUI()
        populateFields()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let content = window?.contentView else { return }

        let labels = [
            ("ChatGPT Bundle ID", NSRect(x: 20, y: 225, width: 170, height: 20)),
            ("Max Characters", NSRect(x: 20, y: 180, width: 170, height: 20)),
            ("Format", NSRect(x: 20, y: 135, width: 170, height: 20)),
            ("Hotkey KeyCode", NSRect(x: 20, y: 90, width: 170, height: 20)),
            ("Hotkey Modifiers", NSRect(x: 20, y: 45, width: 170, height: 20))
        ]

        for (text, frame) in labels {
            let label = NSTextField(labelWithString: text)
            label.frame = frame
            content.addSubview(label)
        }

        bundleField.frame = NSRect(x: 195, y: 220, width: 210, height: 24)
        maxCharsField.frame = NSRect(x: 195, y: 175, width: 210, height: 24)
        formatPopup.frame = NSRect(x: 195, y: 130, width: 210, height: 26)
        keyCodeField.frame = NSRect(x: 195, y: 85, width: 210, height: 24)
        modifiersField.frame = NSRect(x: 195, y: 40, width: 210, height: 24)

        formatPopup.addItems(withTitles: ["Quoted context", "Plain", "Code fence"])

        [bundleField, maxCharsField, formatPopup, keyCodeField, modifiersField].forEach { content.addSubview($0) }

        let saveButton = NSButton(title: "Save", target: self, action: #selector(savePressed))
        saveButton.frame = NSRect(x: 320, y: 8, width: 85, height: 28)
        content.addSubview(saveButton)
    }

    private func populateFields() {
        bundleField.stringValue = settings.chatGPTBundleID
        maxCharsField.stringValue = String(settings.maxChars)
        keyCodeField.stringValue = String(settings.hotkey.keyCode)
        modifiersField.stringValue = String(settings.hotkey.modifiers)

        switch settings.formatMode {
        case .quotedContext:
            formatPopup.selectItem(at: 0)
        case .plain:
            formatPopup.selectItem(at: 1)
        case .codeFence:
            formatPopup.selectItem(at: 2)
        }
    }

    @objc
    private func savePressed() {
        let maxChars = Int(maxCharsField.stringValue) ?? settings.maxChars
        let keyCode = UInt32(keyCodeField.stringValue) ?? settings.hotkey.keyCode
        let modifiers = UInt32(modifiersField.stringValue) ?? settings.hotkey.modifiers

        let formatMode: FormatMode
        switch formatPopup.indexOfSelectedItem {
        case 1:
            formatMode = .plain
        case 2:
            formatMode = .codeFence
        default:
            formatMode = .quotedContext
        }

        settings.chatGPTBundleID = bundleField.stringValue.isEmpty ? AppSettings.default.chatGPTBundleID : bundleField.stringValue
        settings.maxChars = max(200, maxChars)
        settings.hotkey = HotkeyConfiguration(keyCode: keyCode, modifiers: modifiers)
        settings.formatMode = formatMode

        onSave(settings)
        close()
    }
}
