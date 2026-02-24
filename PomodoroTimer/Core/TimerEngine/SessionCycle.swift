import Foundation

/// Stateless helper that determines the next Pomodoro phase.
enum SessionCycle {

    /// Returns the next phase after `current` completes.
    ///
    /// - Parameters:
    ///   - current: The phase that just finished.
    ///   - completedFocusCount: Total focus sessions completed in this cycle so far
    ///     (already incremented for the session that just ended).
    ///   - longBreakInterval: How many focus sessions trigger a long break.
    static func nextPhase(
        after current: TimerPhase,
        completedFocusCount: Int,
        longBreakInterval: Int
    ) -> TimerPhase {
        switch current {
        case .focus:
            // After every `longBreakInterval` focus sessions, take a long break.
            if completedFocusCount > 0 && completedFocusCount % longBreakInterval == 0 {
                return .longBreak
            }
            return .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }
}
