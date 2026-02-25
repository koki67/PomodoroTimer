import Foundation
import Observation

/// Bridges TimerEngine to the SwiftUI view layer.
/// All actions (start/pause/reset/skip/phase select) go through here.
@Observable
@MainActor
final class TimerViewModel {

    // MARK: - Forwarded Engine State (SwiftUI observes these)

    var phase: TimerPhase   { engine.phase }
    var status: TimerStatus { engine.status }
    var remaining: TimeInterval { engine.remaining }
    var cycleFocusCount: Int { engine.cycleFocusCount }

    var remainingString: String { TimeFormatter.format(engine.remaining) }

    /// Fraction of the current session remaining (1.0 = just started, 0.0 = done).
    var progress: Double {
        let total: TimeInterval
        switch engine.phase {
        case .focus:      total = engine.settings.focusDuration
        case .shortBreak: total = engine.settings.shortBreakDuration
        case .longBreak:  total = engine.settings.longBreakDuration
        }
        guard total > 0 else { return 1.0 }
        return max(0, min(1, engine.remaining / total))
    }

    // MARK: - Stats Forwarding

    var todayFocusTime: TimeInterval { statsStore.todayFocusTime }
    var todaySessionCount: Int { statsStore.todaySessionCount }

    // MARK: - Dependencies

    let engine: TimerEngine
    private let statsStore: StatsStore

    // MARK: - Init

    init(engine: TimerEngine, statsStore: StatsStore) {
        self.engine     = engine
        self.statsStore = statsStore
    }

    // MARK: - Timer Controls

    func toggleStartPause() {
        switch engine.status {
        case .idle, .paused: engine.start()
        case .running:       engine.pause()
        }
    }

    func reset() {
        engine.reset()
    }

    func skip() {
        engine.skip()
    }

    func selectPhase(_ phase: TimerPhase) {
        engine.selectPhase(phase)
    }
}
