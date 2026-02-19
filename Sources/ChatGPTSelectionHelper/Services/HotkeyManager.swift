import Carbon
import Foundation

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?

    func register(_ configuration: HotkeyConfiguration, callback: @escaping () -> Void) {
        unregister()
        self.callback = callback

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                if hotKeyID.id == 1 {
                    manager.callback?()
                }
                return noErr
            },
            1,
            &eventType,
            userData,
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
        callback = nil
    }

    deinit {
        unregister()
    }
}
