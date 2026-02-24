import Foundation
import Observation

// MARK: - TimerEngine

/// The single source of truth for all timer state.
///
/// Uses a date-diff approach for countdown accuracy: remaining time is computed
/// as `remainingAtPause - elapsed` on every tick, making the timer immune to
/// CPU throttling, system sleep, and RunLoop stalls.
@Observable
@MainActor
final class TimerEngine {

    // MARK: - Observable State

    private(set) var phase: TimerPhase = .focus
    private(set) var status: TimerStatus = .idle
    private(set) var remaining: TimeInterval = 0
    /// Completed focus sessions in the current cycle (resets after long break).
    private(set) var cycleFocusCount: Int = 0

    // MARK: - Callbacks

    /// Called whenever a session ends (naturally or via skip).
    var onSessionComplete: ((Session) -> Void)?

    // MARK: - Dependencies

    private(set) var settings: AppSettings
    private let persistence: PersistenceService

    // MARK: - Internal Timer Machinery

    private var timer: Timer?
    /// Wall-clock time when the current run started (or resumed from pause).
    private var sessionRunStartDate: Date?
    /// Remaining seconds at the moment the timer was last started or resumed.
    private var remainingAtRunStart: TimeInterval = 0
    /// Wall-clock time when the *entire* session began (survives pause/resume).
    private var sessionStartDate: Date?

    // MARK: - Init

    init(settings: AppSettings, persistence: PersistenceService) {
        self.settings = settings
        self.persistence = persistence
        self.remaining = settings.focusDuration
    }

    // MARK: - Public API

    func start() {
        guard status == .idle || status == .paused else { return }
        if status == .idle {
            // Brand-new session: record wall-clock start and full planned duration.
            sessionStartDate = Date()
            remainingAtRunStart = remaining
        } else {
            // Resuming from pause: keep sessionStartDate, update run-start reference.
            remainingAtRunStart = remaining
        }
        sessionRunStartDate = Date()
        status = .running
        scheduleTimer()
    }

    func pause() {
        guard status == .running else { return }
        timer?.invalidate()
        timer = nil
        // Snap remaining to precise value before pausing.
        syncRemaining()
        sessionRunStartDate = nil
        status = .paused
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        sessionRunStartDate = nil
        sessionStartDate = nil
        status = .idle
        remaining = plannedDuration(for: phase)
    }

    func skip() {
        // Record the partial session if one was in progress.
        if (status == .running || status == .paused), let start = sessionStartDate {
            let session = Session(
                id: UUID(),
                phase: phase,
                startedAt: start,
                duration: plannedDuration(for: phase),
                completedAt: Date(),
                wasCompleted: false
            )
            // Advance phase FIRST so any callback reading timerEngine.phase
            // sees the correct next phase (consistent with handleSessionComplete).
            advanceCycle(completed: false)
            onSessionComplete?(session)
        } else {
            advanceCycle(completed: false)
        }
    }

    /// Force-select a phase (only allowed when idle).
    func selectPhase(_ newPhase: TimerPhase) {
        guard status == .idle else { return }
        phase = newPhase
        remaining = plannedDuration(for: newPhase)
    }

    func updateSettings(_ newSettings: AppSettings) {
        let wasIdle = status == .idle
        settings = newSettings
        // If idle, apply new duration immediately.
        if wasIdle {
            remaining = plannedDuration(for: phase)
        }
    }

    // MARK: - Sleep / Wake

    /// Called by SleepWakeObserver when the system wakes from sleep.
    func handleWake() {
        guard status == .running, let runStart = sessionRunStartDate else { return }
        let elapsed = Date().timeIntervalSince(runStart)
        if elapsed >= remainingAtRunStart {
            // Session expired while sleeping — complete it immediately.
            handleSessionComplete()
        }
        // Otherwise the next tick() call will catch up naturally via date-diff.
    }

    // MARK: - Persistence

    func saveSnapshot() {
        let snap = TimerSnapshot(
            phase: phase,
            status: status,
            remainingSeconds: remaining,
            completedFocusSessions: cycleFocusCount,
            savedAt: Date()
        )
        persistence.saveTimerSnapshot(snap)
    }

    func restoreSnapshot() {
        guard let snap = persistence.loadTimerSnapshot() else {
            remaining = plannedDuration(for: phase)
            return
        }
        phase = snap.phase
        cycleFocusCount = snap.completedFocusSessions

        switch snap.status {
        case .running:
            // Compute how much time passed while the app was closed.
            let elapsed = Date().timeIntervalSince(snap.savedAt)
            let adjusted = snap.remainingSeconds - elapsed
            if adjusted <= 0 {
                // Session expired while app was quit — silently advance cycle.
                advanceCycle(completed: true)
            } else {
                // Restore as paused; let the user decide to resume.
                remaining = adjusted
                status = .paused
            }
        case .paused:
            remaining = snap.remainingSeconds
            status = .paused
        case .idle:
            remaining = snap.remainingSeconds
            status = .idle
        }
    }

    // MARK: - Private

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        // .common mode fires even during scroll/tracking event loops.
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        syncRemaining()
        if remaining <= 0 {
            handleSessionComplete()
        }
    }

    private func syncRemaining() {
        guard let runStart = sessionRunStartDate else { return }
        let elapsed = Date().timeIntervalSince(runStart)
        remaining = max(0, remainingAtRunStart - elapsed)
    }

    private func handleSessionComplete() {
        timer?.invalidate()
        timer = nil

        // Capture session data using the OLD phase before advancing the cycle.
        let session = Session(
            id: UUID(),
            phase: phase,
            startedAt: sessionStartDate ?? Date(),
            duration: plannedDuration(for: phase),
            completedAt: Date(),
            wasCompleted: true
        )
        // Advance the cycle FIRST so timerEngine.phase reflects the NEXT phase
        // when the callback runs. AppDelegate reads phase to decide which
        // auto-start setting (autoStartBreaks vs autoStartFocus) applies.
        advanceCycle(completed: true)
        onSessionComplete?(session)
    }

    private func advanceCycle(completed: Bool) {
        timer?.invalidate()
        timer = nil
        sessionRunStartDate = nil
        sessionStartDate = nil

        // Count focus sessions toward the long-break interval regardless of skip/complete.
        // wasCompleted on Session is for stats only; cycle advancement is unconditional.
        if phase == .focus {
            cycleFocusCount += 1
        }
        // Reset cycle count once a long break ends (skip or complete).
        if phase == .longBreak {
            cycleFocusCount = 0
        }

        let next = SessionCycle.nextPhase(
            after: phase,
            completedFocusCount: cycleFocusCount,
            longBreakInterval: settings.longBreakInterval
        )
        phase = next
        status = .idle
        remaining = plannedDuration(for: next)
    }

    private func plannedDuration(for phase: TimerPhase) -> TimeInterval {
        switch phase {
        case .focus:      return settings.focusDuration
        case .shortBreak: return settings.shortBreakDuration
        case .longBreak:  return settings.longBreakDuration
        }
    }
}
