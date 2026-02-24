import Foundation

// MARK: - Timer Phase

/// The three phases in the Pomodoro cycle.
enum TimerPhase: String, Codable, CaseIterable, Identifiable {
    case focus      = "Focus"
    case shortBreak = "Short Break"
    case longBreak  = "Long Break"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .focus:      return "Focus"
        case .shortBreak: return "Short"
        case .longBreak:  return "Long"
        }
    }
}

// MARK: - Timer Status

/// The running state of the timer at any point in time.
enum TimerStatus: String, Codable {
    case idle       // Never started or was reset; showing full duration
    case running    // Actively counting down
    case paused     // Paused mid-session
}

// MARK: - Theme Mode

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var id: String { rawValue }
}
