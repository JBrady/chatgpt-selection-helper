import AppKit
import Foundation
import OSLog

final class TelemetryService {
    private let logger = Logger(subsystem: "com.johnbrady.chatgpt-selection-helper", category: "core")
    private var history: [RunReport] = []
    private let maxHistory = 50

    func record(_ report: RunReport) {
        history.append(report)
        if history.count > maxHistory {
            history.removeFirst(history.count - maxHistory)
        }

        logger.info(
            "capture_path=\(report.capturePath, privacy: .public) capture_len=\(report.captureLen) focus_path=\(report.focusPath, privacy: .public) paste_attempts=\(report.pasteAttempts) paste_result=\(report.pasteResult, privacy: .public) restore_outcome=\(report.restoreOutcome, privacy: .public) error_code=\(report.errorCode, privacy: .public) capture_ms=\(report.captureMs ?? -1) delivery_ms=\(report.deliveryMs ?? -1) total_ms=\(report.totalMs ?? -1)"
        )
    }

    func copyRecentDebugInfoToClipboard() {
        let lines = history.suffix(20).map { $0.debugSummaryLine() }
        let body = lines.isEmpty ? "No runs recorded yet." : lines.joined(separator: "\n")

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(body, forType: .string)
    }
}
