import Foundation

/// JSON-backed persistence for settings, timer snapshot, and session history.
///
/// All files are stored in `~/Library/Application Support/<bundle-id>/`.
/// Writes use `Data.write(options: .atomic)` to prevent partial-write corruption.
final class PersistenceService: Sendable {

    let baseURL: URL

    init(baseURL: URL? = nil) {
        if let url = baseURL {
            self.baseURL = url
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            self.baseURL = appSupport.appendingPathComponent(
                Bundle.main.bundleIdentifier ?? "com.koki.PomodoroTimer"
            )
        }
        try? FileManager.default.createDirectory(
            at: self.baseURL, withIntermediateDirectories: true
        )
    }

    // MARK: - Settings

    func saveSettings(_ settings: AppSettings) {
        write(settings, to: "settings.json")
    }

    func loadSettings() -> AppSettings? {
        read(AppSettings.self, from: "settings.json")
    }

    // MARK: - Timer Snapshot

    func saveTimerSnapshot(_ snap: TimerSnapshot) {
        write(snap, to: "timer_snapshot.json")
    }

    func loadTimerSnapshot() -> TimerSnapshot? {
        read(TimerSnapshot.self, from: "timer_snapshot.json")
    }

    // MARK: - Sessions

    func appendSession(_ session: Session) {
        var existing = loadAllSessions()
        existing.append(session)
        write(existing, to: "sessions.json")
    }

    func loadAllSessions() -> [Session] {
        read([Session].self, from: "sessions.json") ?? []
    }

    func clearAllSessions() {
        let url = baseURL.appendingPathComponent("sessions.json")
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Generic Helpers

    func write<T: Encodable>(_ value: T, to filename: String) {
        let url = baseURL.appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(value)
            // Atomic write prevents corruption on crash or force-quit.
            try data.write(to: url, options: .atomic)
        } catch {
            print("PersistenceService write error (\(filename)): \(error)")
        }
    }

    func read<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = baseURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("PersistenceService read error (\(filename)): \(error)")
            return nil
        }
    }
}
