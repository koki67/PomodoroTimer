import Carbon.HIToolbox
import Foundation

// MARK: - HotkeyAction

enum HotkeyAction: Sendable {
    case startPause
    case skip
    case reset
    case togglePanel
}

// MARK: - HotkeyService

/// Registers global keyboard shortcuts using Carbon's RegisterEventHotKey API.
///
/// IMPORTANT: This service requires App Sandbox to be DISABLED.
/// Carbon hotkeys fire system-wide regardless of which app has focus.
///
/// The event handler uses the standard `Unmanaged` trampoline pattern to bridge
/// a C callback to a Swift instance method.
final class HotkeyService {

    // Maps hotkey signature ID → action
    private static let idToAction: [UInt32: HotkeyAction] = [
        1: .startPause,
        2: .skip,
        3: .reset,
        4: .togglePanel,
    ]
    // Signature 'PMTR' (Pomodoro Timer)
    private static let signature: OSType = 0x504D5452

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    var callback: (@MainActor (HotkeyAction) -> Void)?

    deinit { unregisterAll() }

    // MARK: - Public API

    func register(settings: AppSettings, callback: @escaping @MainActor (HotkeyAction) -> Void) {
        self.callback = callback
        unregisterAll()
        installEventHandler()
        registerHotkey(id: 1, setting: settings.hotkeyStartPause)
        registerHotkey(id: 2, setting: settings.hotkeySkip)
        registerHotkey(id: 3, setting: settings.hotkeyReset)
        registerHotkey(id: 4, setting: settings.hotkeyTogglePanel)
    }

    func unregisterAll() {
        hotKeyRefs.forEach { UnregisterEventHotKey($0) }
        hotKeyRefs.removeAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    // MARK: - Private

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData, let event else { return OSStatus(eventNotHandledErr) }
                let svc = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                if let action = HotkeyService.idToAction[hkID.id] {
                    let cb = svc.callback
                    Task { @MainActor in cb?(action) }
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    private func registerHotkey(id: UInt32, setting: HotkeySetting) {
        var hkID = EventHotKeyID(signature: HotkeyService.signature, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(setting.keyCode),
            UInt32(setting.modifiers),
            hkID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr, let ref {
            hotKeyRefs.append(ref)
        } else {
            print("HotkeyService: failed to register hotkey id=\(id), status=\(status)")
        }
    }
}
