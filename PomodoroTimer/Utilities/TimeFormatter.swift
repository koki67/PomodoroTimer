import Foundation

enum TimeFormatter {
    /// Formats seconds as "MM:SS" (e.g. "25:00", "04:37").
    static func format(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(ceil(seconds)))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Formats seconds as "Xh Ym" or "Ym" (e.g. "1h 20m", "45m").
    static func formatHM(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
