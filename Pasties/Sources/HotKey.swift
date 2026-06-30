import AppKit
import Carbon.HIToolbox

/// Registers a single global hotkey using the Carbon Hot Key API.
/// This does NOT require Accessibility permission (only *simulating* a
/// keystroke does — see Paster). The callback fires on the main thread.
final class HotKey {
    private var ref: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    /// Kept alive and reachable from the C event handler.
    private static var instances: [UInt32: HotKey] = [:]
    private static var nextID: UInt32 = 1

    /// - Parameters:
    ///   - keyCode: a virtual key code, e.g. `kVK_ANSI_V` (0x09).
    ///   - modifiers: Carbon modifier mask, e.g. `cmdKey | shiftKey`.
    init(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.action = action

        let id = HotKey.nextID
        HotKey.nextID += 1
        HotKey.instances[id] = self

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            HotKey.instances[hkID.id]?.action()
            return noErr
        }, 1, &eventSpec, nil, &handlerRef)

        let hotKeyID = EventHotKeyID(signature: OSType(0x53505154) /* 'SPQT' */, id: id)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                            GetApplicationEventTarget(), 0, &ref)
    }
}
