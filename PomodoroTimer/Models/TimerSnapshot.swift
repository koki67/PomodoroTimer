import Foundation

/// Timer state persisted to disk on app quit/sleep, restored on next launch.
struct TimerSnapshot: Codable, Sendable {
    var phase: TimerPhase
    var status: TimerStatus
    /// Seconds remaining when the snapshot was taken.
    var remainingSeconds: TimeInterval
    /// Number of completed focus sessions in the current cycle (resets after long break).
    var completedFocusSessions: Int
    /// Wall-clock time when this snapshot was saved, used to compute elapsed time on restore.
    var savedAt: Date
}
