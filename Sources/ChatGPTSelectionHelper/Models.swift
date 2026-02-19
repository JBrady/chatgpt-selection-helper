import AppKit
import Foundation

enum FormatMode: String, Codable, CaseIterable {
    case plain
    case quotedContext
    case codeFence
}

struct HotkeyConfiguration: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let `default` = HotkeyConfiguration(
        keyCode: 49, // space
        modifiers: UInt32((1 << 8) | (1 << 9)) // command + shift
    )
}

struct AppSettings: Codable, Equatable {
    var hotkey: HotkeyConfiguration
    var formatMode: FormatMode
    var chatGPTBundleID: String
    var showToasts: Bool
    var maxChars: Int

    static let `default` = AppSettings(
        hotkey: .default,
        formatMode: .quotedContext,
        chatGPTBundleID: "com.openai.chat",
        showToasts: true,
        maxChars: 20_000
    )
}

enum CapturePath: String, Codable {
    case pasteboard
    case axSelectedText = "axselectedtext"
    case axRange = "axrange"
}

enum FocusPath: String, Codable {
    case assumedFocused = "assumed_focused"
    case axFocus = "ax_focus"
}

enum PasteResult: String, Codable {
    case success
    case fail
}

enum RestoreOutcome: String, Codable {
    case restored
    case skippedUserChanged = "skipped_user_changed"
    case notNeeded = "not_needed"
}

enum ErrorCode: String, Codable {
    case none
    case permissionMissing = "permission_missing"
    case noSelection = "capture_empty"
    case chatGPTLaunchFailed = "chatgpt_launch_failed"
    case focusFailed = "focus_failed"
    case pasteFailed = "paste_failed"
    case restoreSkippedUserChanged = "restore_skipped_user_changed"
    case internalError = "internal_error"
}

struct StageTimings: Codable {
    var captureMs: Int?
    var deliveryMs: Int?
    var totalMs: Int?
}

struct CaptureResult {
    var text: String?
    var capturePath: CapturePath?
    var captureLength: Int
    var errorCode: ErrorCode
    var changedCountAfterCapture: Int?
}

struct DeliveryResult {
    var focusPath: FocusPath
    var pasteAttempts: Int
    var pasteResult: PasteResult
    var errorCode: ErrorCode
    var changedCountAfterPasteboardWrite: Int?
}

struct RunReport: Codable {
    var timestamp: Date
    var capturePath: String
    var captureLen: Int
    var focusPath: String
    var pasteAttempts: Int
    var pasteResult: String
    var restoreOutcome: String
    var errorCode: String
    var captureMs: Int?
    var deliveryMs: Int?
    var totalMs: Int?

    func debugSummaryLine() -> String {
        [
            "time=\(ISO8601DateFormatter().string(from: timestamp))",
            "capture_path=\(capturePath)",
            "capture_len=\(captureLen)",
            "focus_path=\(focusPath)",
            "paste_attempts=\(pasteAttempts)",
            "paste_result=\(pasteResult)",
            "restore_outcome=\(restoreOutcome)",
            "error_code=\(errorCode)",
            "capture_ms=\(captureMs?.description ?? "nil")",
            "delivery_ms=\(deliveryMs?.description ?? "nil")",
            "total_ms=\(totalMs?.description ?? "nil")"
        ].joined(separator: " ")
    }
}

func formatSelection(_ text: String, mode: FormatMode) -> String {
    switch mode {
    case .plain:
        return text
    case .quotedContext:
        return "Quoted context: \"\(text)\""
    case .codeFence:
        return "```\n\(text)\n```"
    }
}

func truncateSelection(_ text: String, maxChars: Int) -> (output: String, truncated: Bool) {
    guard maxChars > 0 else {
        return ("", !text.isEmpty)
    }
    guard text.count > maxChars else {
        return (text, false)
    }
    let end = text.index(text.startIndex, offsetBy: maxChars)
    return (String(text[..<end]) + "\n\n[truncated]", true)
}

func restoreOutcomeDecision(currentChangeCount: Int, initialChangeCount: Int, latestFlowChangeCount: Int) -> RestoreOutcome {
    if currentChangeCount == initialChangeCount {
        return .notNeeded
    }
    if currentChangeCount == latestFlowChangeCount {
        return .restored
    }
    return .skippedUserChanged
}
