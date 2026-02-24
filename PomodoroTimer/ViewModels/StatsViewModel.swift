import Foundation
import Observation

/// Provides aggregated statistics for the Stats views.
@Observable
@MainActor
final class StatsViewModel {

    private let store: StatsStore
    private let persistence: PersistenceService

    var selectedPeriod: StatsPeriod = .day

    init(store: StatsStore, persistence: PersistenceService) {
        self.store = store
        self.persistence = persistence
    }

    // MARK: - Data Access

    var sessions: [Session] { store.sessions }

    var allSessions: [Session] {
        store.sessions.sorted { $0.startedAt > $1.startedAt }
    }

    func dataPoints(for period: StatsPeriod) -> [StatsDataPoint] {
        StatsAggregator.aggregate(sessions: store.sessions, period: period)
    }

    // MARK: - Actions

    func clearHistory() {
        store.clearAll()
    }

    func exportCSV() -> URL? {
        let csv = CSVExporter.export(store.sessions)
        return CSVExporter.saveToDownloads(csv)
    }
}
