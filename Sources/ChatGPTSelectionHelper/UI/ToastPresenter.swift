import AppKit
import Foundation

@MainActor
final class ToastPresenter {
    private var toastWindow: NSWindow?

    func show(_ message: String, duration: TimeInterval = 1.7) {
        toastWindow?.close()

        let label = NSTextField(labelWithString: message)
        label.textColor = .white
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.alignment = .center
        label.maximumNumberOfLines = 3
        label.frame = NSRect(x: 14, y: 10, width: 320, height: 56)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 348, height: 76))
        content.wantsLayer = true
        content.layer?.cornerRadius = 10
        content.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.82).cgColor
        content.addSubview(label)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 348, height: 76),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.contentView = content
        window.ignoresMouseEvents = true

        if let screen = NSScreen.main?.visibleFrame {
            let x = screen.midX - 174
            let y = screen.minY + 70
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.orderFrontRegardless()
        toastWindow = window

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            window.close()
            if self.toastWindow === window {
                self.toastWindow = nil
            }
        }
    }
}
