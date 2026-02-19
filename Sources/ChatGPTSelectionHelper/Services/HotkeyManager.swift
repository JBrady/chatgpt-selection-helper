import Carbon
import Foundation

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?
    nonisolated(unsafe) private static weak var activeManager: HotkeyManager?

    func register(_ configuration: HotkeyConfiguration, callback: @escaping () -> Void) {
        unregister()
        self.callback = callback
        HotkeyManager.activeManager = self

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData in
                guard let event else { return noErr }
                _ = userData // unused

                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                if hotKeyID.id == 1 {
                    HotkeyManager.activeManager?.callback?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x43485348), id: 1) // CHSH
        RegisterEventHotKey(
            UInt32(configuration.keyCode),
            configuration.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        if HotkeyManager.activeManager === self {
            HotkeyManager.activeManager = nil
        }
        callback = nil
    }

    deinit {
        unregister()
    }
}
