import AppKit
import Foundation

struct PasteboardItemSnapshot {
    let typesToData: [NSPasteboard.PasteboardType: Data]
}

struct ClipboardSnapshot {
    let items: [PasteboardItemSnapshot]
    let initialChangeCount: Int
}

final class ClipboardSession {
    let snapshot: ClipboardSnapshot
    private(set) var latestFlowChangeCount: Int

    init(snapshot: ClipboardSnapshot) {
        self.snapshot = snapshot
        self.latestFlowChangeCount = snapshot.initialChangeCount
    }

    func noteFlowClipboardChange(_ changeCount: Int) {
        if changeCount > latestFlowChangeCount {
            latestFlowChangeCount = changeCount
        }
    }
}

final class ClipboardService {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func beginSession() -> ClipboardSession {
        ClipboardSession(snapshot: snapshotClipboard())
    }

    func currentChangeCount() -> Int {
        pasteboard.changeCount
    }

    func readPlainText() -> String? {
        if let string = pasteboard.string(forType: .string), !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return string
        }
        if let string = pasteboard.string(forType: NSPasteboard.PasteboardType("public.utf8-plain-text")),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return string
        }
        return nil
    }

    @discardableResult
    func setTemporaryString(_ value: String) -> Int {
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        return pasteboard.changeCount
    }

    func restoreClipboard(for session: ClipboardSession) -> RestoreOutcome {
        let current = pasteboard.changeCount
        let initial = session.snapshot.initialChangeCount
        let latestFlow = session.latestFlowChangeCount

        let decision = restoreOutcomeDecision(
            currentChangeCount: current,
            initialChangeCount: initial,
            latestFlowChangeCount: latestFlow
        )

        if decision == .notNeeded {
            return .notNeeded
        }

        guard decision == .restored else {
            return .skippedUserChanged
        }

        pasteboard.clearContents()
        var restoredItems: [NSPasteboardItem] = []
        for item in session.snapshot.items {
            let pbItem = NSPasteboardItem()
            for (type, data) in item.typesToData {
                pbItem.setData(data, forType: type)
            }
            restoredItems.append(pbItem)
        }

        if restoredItems.isEmpty {
            _ = pasteboard.clearContents()
        } else {
            pasteboard.writeObjects(restoredItems)
        }
        return .restored
    }

    private func snapshotClipboard() -> ClipboardSnapshot {
        let initial = pasteboard.changeCount
        let items = (pasteboard.pasteboardItems ?? []).map { item in
            var map: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    map[type] = data
                }
            }
            return PasteboardItemSnapshot(typesToData: map)
        }
        return ClipboardSnapshot(items: items, initialChangeCount: initial)
    }
}
