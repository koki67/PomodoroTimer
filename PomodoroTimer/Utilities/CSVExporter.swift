import Foundation

enum CSVExporter {
    nonisolated(unsafe) private static let iso8601 = ISO8601DateFormatter()

    /// Converts sessions to a CSV string with a header row.
    static func export(_ sessions: [Session]) -> String {
        var lines = ["id,phase,startedAt,completedAt,plannedDurationSec,actualDurationSec,wasCompleted"]
        for s in sessions {
            let row = [
                s.id.uuidString,
                s.phase.rawValue,
                iso8601.string(from: s.startedAt),
                iso8601.string(from: s.completedAt),
                String(format: "%.0f", s.duration),
                String(format: "%.0f", s.actualDuration),
                s.wasCompleted ? "true" : "false",
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    /// Writes the CSV string to the user's Downloads folder and returns the file URL.
    @discardableResult
    static func saveToDownloads(_ csv: String, filename: String = "pomodoro_sessions.csv") -> URL? {
        guard let downloads = FileManager.default.urls(
            for: .downloadsDirectory, in: .userDomainMask
        ).first else { return nil }
        let url = downloads.appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("CSVExporter: failed to write file: \(error)")
            return nil
        }
    }
}
