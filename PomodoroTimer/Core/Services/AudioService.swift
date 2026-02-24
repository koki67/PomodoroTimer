import AVFoundation
import Foundation
import Observation

/// Manages ambient sound playback using AVAudioPlayer.
///
/// On macOS, background audio works automatically when the app uses
/// `.accessory` activation policy — no AVAudioSession configuration needed.
@Observable
@MainActor
final class AudioService {

    private var player: AVAudioPlayer?
    private(set) var currentSound: AmbientSound?
    private(set) var isPlaying: Bool = false
    private var previewTask: Task<Void, Never>?

    // MARK: - Playback

    func play(sound: AmbientSound, volume: Float) {
        // If already playing the same sound, just update volume.
        if currentSound == sound, let p = player, p.isPlaying {
            p.volume = volume
            return
        }
        stop()
        guard let url = Bundle.main.url(
            forResource: sound.fileName,
            withExtension: sound.fileExtension
        ) else {
            print("AudioService: missing file \(sound.fileName).\(sound.fileExtension)")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1  // loop indefinitely
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
            currentSound = sound
            isPlaying = true
        } catch {
            print("AudioService: failed to create player: \(error)")
        }
    }

    func stop() {
        previewTask?.cancel()
        previewTask = nil
        player?.stop()
        player = nil
        currentSound = nil
        isPlaying = false
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    // MARK: - Preview

    /// Plays the given sound for `duration` seconds then stops.
    func preview(sound: AmbientSound, volume: Float, duration: TimeInterval = 4.0) {
        play(sound: sound, volume: volume)
        previewTask?.cancel()
        previewTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                stop()
            }
        }
    }
}
