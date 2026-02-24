import Foundation

/// A single completed (or skipped) timer session.
struct Session: Identifiable, Codable, Sendable {
    let id: UUID
    let phase: TimerPhase
    let startedAt: Date
    /// The planned duration in seconds (from settings at session start time).
    let duration: TimeInterval
    let completedAt: Date
    /// `true` if the session ran to zero; `false` if the user skipped early.
    var wasCompleted: Bool

    /// Actual elapsed seconds between start and completion.
    var actualDuration: TimeInterval {
        completedAt.timeIntervalSince(startedAt)
    }
}
