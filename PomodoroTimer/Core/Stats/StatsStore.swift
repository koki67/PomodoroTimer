import Foundation
import Observation

/// In-memory session store backed by PersistenceService.
/// Provides today's summary and exposes the full session history for charts.
@Observable
@MainActor
final class StatsStore {

    private let persistence: PersistenceService
    private(set) var sessions: [Session] = []

    init(persistence: PersistenceService) {
        self.persistence = persistence
        sessions = persistence.loadAllSessions()
    }

    // MARK: - Writing

    func record(_ session: Session) {
        sessions.append(session)
        persistence.appendSession(session)
    }

    func clearAll() {
        sessions.removeAll()
        persistence.clearAllSessions()
    }

    // MARK: - Today's Summary (focus sessions only)

    var todayFocusSessions: [Session] {
        let start = Calendar.current.startOfDay(for: Date())
        return sessions.filter {
            $0.phase == .focus && $0.wasCompleted && $0.startedAt >= start
        }
    }

    var todayFocusTime: TimeInterval {
        todayFocusSessions.reduce(0) { $0 + $1.actualDuration }
    }

    var todaySessionCount: Int { todayFocusSessions.count }
}
