import Foundation
import Observation
import SwiftUI

/// Manages user settings with live persistence and validation.
@Observable
@MainActor
final class SettingsViewModel {

    var settings: AppSettings {
        didSet { persistence.saveSettings(settings) }
    }

    private let persistence: PersistenceService

    /// Called when settings change so dependents (TimerEngine, etc.) can update.
    var onSettingsChanged: ((AppSettings) -> Void)?

    init(settings: AppSettings, persistence: PersistenceService) {
        self.settings = settings
        self.persistence = persistence
    }

    // MARK: - Convenience Bindings

    var focusDurationMinutes: Double {
        get { settings.focusDuration / 60 }
        set {
            settings.focusDuration = newValue * 60
            onSettingsChanged?(settings)
        }
    }

    var shortBreakMinutes: Double {
        get { settings.shortBreakDuration / 60 }
        set {
            settings.shortBreakDuration = newValue * 60
            onSettingsChanged?(settings)
        }
    }

    var longBreakMinutes: Double {
        get { settings.longBreakDuration / 60 }
        set {
            settings.longBreakDuration = newValue * 60
            onSettingsChanged?(settings)
        }
    }

    // Preferred color scheme derived from theme setting.
    var preferredColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
