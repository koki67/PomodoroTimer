import Foundation

// MARK: - Stats Period

enum StatsPeriod: String, CaseIterable, Identifiable {
    case day   = "Day"
    case week  = "Week"
    case month = "Month"
    case year  = "Year"

    var id: String { rawValue }
}

// MARK: - Stats Data Point

struct StatsDataPoint: Identifiable, Sendable {
    let id = UUID()
    let label: String
    let date: Date
    let focusMinutes: Double
    let sessionCount: Int
}

// MARK: - Aggregator

/// Stateless helper that buckets a `[Session]` array into chart-ready data points.
enum StatsAggregator {

    static func aggregate(sessions: [Session], period: StatsPeriod) -> [StatsDataPoint] {
        let focus = sessions.filter { $0.phase == .focus && $0.wasCompleted }
        let cal = Calendar.current

        switch period {
        case .day:
            // Last 7 days, one bar per day
            return (0..<7).reversed().compactMap { offset -> StatsDataPoint? in
                guard let date = cal.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
                let start = cal.startOfDay(for: date)
                guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return nil }
                let bucket = focus.filter { $0.startedAt >= start && $0.startedAt < end }
                let label = offset == 0 ? "Today" : DateFormatter.shortWeekday.string(from: date)
                return StatsDataPoint(
                    label: label,
                    date: start,
                    focusMinutes: bucket.reduce(0) { $0 + $1.actualDuration } / 60,
                    sessionCount: bucket.count
                )
            }

        case .week:
            // Last 4 weeks
            return (0..<4).reversed().compactMap { offset -> StatsDataPoint? in
                guard let anchorDate = cal.date(byAdding: .weekOfYear, value: -offset, to: Date()),
                      let interval = cal.dateInterval(of: .weekOfYear, for: anchorDate)
                else { return nil }
                let bucket = focus.filter {
                    $0.startedAt >= interval.start && $0.startedAt < interval.end
                }
                let label = offset == 0 ? "This week" : "–\(offset)w"
                return StatsDataPoint(
                    label: label,
                    date: interval.start,
                    focusMinutes: bucket.reduce(0) { $0 + $1.actualDuration } / 60,
                    sessionCount: bucket.count
                )
            }

        case .month:
            // Last 12 months
            return aggregate(
                sessions: focus,
                component: .month,
                count: 12,
                labelFormatter: DateFormatter.shortMonth
            )

        case .year:
            // Last 3 years
            return aggregate(
                sessions: focus,
                component: .year,
                count: 3,
                labelFormatter: DateFormatter.year
            )
        }
    }

    private static func aggregate(
        sessions: [Session],
        component: Calendar.Component,
        count: Int,
        labelFormatter: DateFormatter
    ) -> [StatsDataPoint] {
        let cal = Calendar.current
        return (0..<count).reversed().compactMap { offset -> StatsDataPoint? in
            guard let date = cal.date(byAdding: component, value: -offset, to: Date()),
                  let interval = cal.dateInterval(of: component, for: date)
            else { return nil }
            let bucket = sessions.filter {
                $0.startedAt >= interval.start && $0.startedAt < interval.end
            }
            return StatsDataPoint(
                label: labelFormatter.string(from: date),
                date: interval.start,
                focusMinutes: bucket.reduce(0) { $0 + $1.actualDuration } / 60,
                sessionCount: bucket.count
            )
        }
    }
}

// MARK: - DateFormatter helpers

private extension DateFormatter {
    static let shortWeekday: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()
    static let shortMonth: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f
    }()
    static let year: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy"; return f
    }()
}
