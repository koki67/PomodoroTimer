import Foundation
import Observation

/// Bridges TimerEngine and AudioService to the SwiftUI view layer.
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

    // MARK: - Stats Forwarding

    var todayFocusTime: TimeInterval { statsStore.todayFocusTime }
    var todaySessionCount: Int { statsStore.todaySessionCount }

    // MARK: - Dependencies

    let engine: TimerEngine
    private let audio: AudioService
    private let statsStore: StatsStore

    // MARK: - Init

    init(engine: TimerEngine, audio: AudioService, statsStore: StatsStore) {
        self.engine = engine
        self.audio  = audio
        self.statsStore = statsStore
    }

    // MARK: - Timer Controls

    func toggleStartPause() {
        switch engine.status {
        case .idle, .paused:
            engine.start()
            playAmbientIfEnabled()
        case .running:
            engine.pause()
            audio.stop()
        }
    }

    func reset() {
        engine.reset()
        audio.stop()
    }

    func skip() {
        engine.skip()
        // Ambient sound continues into the next session only if still running.
        // AudioService.stop() is not called here; next start() call will handle it.
    }

    func selectPhase(_ phase: TimerPhase) {
        engine.selectPhase(phase)
    }

    // MARK: - Audio

    func playAmbientIfEnabled() {
        let settings = engine.settings
        guard settings.ambientSoundEnabled else { return }
        audio.play(sound: settings.selectedAmbientSound, volume: settings.ambientVolume)
    }

    func stopAmbient() {
        audio.stop()
    }
}
