import Foundation
import Carbon.HIToolbox

// MARK: - Hotkey Setting

/// Stores a Carbon virtual key code and modifier flags.
struct HotkeySetting: Codable, Sendable {
    var keyCode: Int
    /// Carbon modifier flags (controlKey, shiftKey, optionKey, cmdKey).
    var modifiers: Int

    // Sensible defaults reference Carbon constants directly.
    // controlKey = 4096, shiftKey = 512, optionKey = 2048
    static let defaultStartPause  = HotkeySetting(keyCode: 35, modifiers: Int(controlKey))              // Ctrl+P
    static let defaultSkip        = HotkeySetting(keyCode: 1,  modifiers: Int(controlKey | shiftKey))   // Ctrl+Shift+S
    static let defaultReset       = HotkeySetting(keyCode: 15, modifiers: Int(controlKey))              // Ctrl+R
    static let defaultTogglePanel = HotkeySetting(keyCode: 35, modifiers: Int(controlKey | optionKey))  // Ctrl+Opt+P

    var displayString: String {
        var parts: [String] = []
        if modifiers & Int(controlKey) != 0 { parts.append("⌃") }
        if modifiers & Int(optionKey)  != 0 { parts.append("⌥") }
        if modifiers & Int(shiftKey)   != 0 { parts.append("⇧") }
        if modifiers & Int(cmdKey)     != 0 { parts.append("⌘") }
        // Map common key codes to symbols
        let keyMap: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M",
        ]
        parts.append(keyMap[keyCode] ?? "(\(keyCode))")
        return parts.joined()
    }
}

// MARK: - App Settings

/// All user-configurable preferences, persisted as settings.json.
struct AppSettings: Codable, Sendable {

    // MARK: Timer Durations
    var focusDuration: TimeInterval      = 25 * 60
    var shortBreakDuration: TimeInterval = 5 * 60
    var longBreakDuration: TimeInterval  = 15 * 60
    /// Number of consecutive focus sessions before a long break.
    var longBreakInterval: Int           = 4

    // MARK: Auto-advance
    /// Automatically start break timers after a focus session completes.
    var autoStartBreaks: Bool   = false
    /// Automatically start focus timer after a break session completes.
    var autoStartFocus: Bool    = false

    // MARK: Ambient Sound
    var ambientSoundEnabled: Bool       = false
    var selectedAmbientSound: AmbientSound = .rain
    var ambientVolume: Float            = 0.5

    // MARK: Notifications
    var notificationsEnabled: Bool = true
    /// NSSound name for focus-session-end notification. Empty = default.
    var focusEndSound: String      = "Blow"
    /// NSSound name for break-session-end notification. Empty = default.
    var breakEndSound: String      = "Glass"

    // MARK: UI Behavior
    var alwaysOnTop: Bool       = true
    var themeMode: ThemeMode    = .system
    var blendDelay: TimeInterval = 3.0  // seconds after start before auto-shrink

    // MARK: Goals
    var dailySessionGoal: Int        = 8
    var dailyFocusGoalMinutes: Int   = 120

    // MARK: Hotkeys
    var hotkeyStartPause:   HotkeySetting = .defaultStartPause
    var hotkeySkip:         HotkeySetting = .defaultSkip
    var hotkeyReset:        HotkeySetting = .defaultReset
    var hotkeyTogglePanel:  HotkeySetting = .defaultTogglePanel
}
