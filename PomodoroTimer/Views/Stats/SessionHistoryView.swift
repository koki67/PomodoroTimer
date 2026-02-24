import SwiftUI

struct SessionHistoryView: View {
    @Environment(StatsViewModel.self) private var statsVM

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        if statsVM.allSessions.isEmpty {
            ContentUnavailableView(
                "No sessions recorded",
                systemImage: "clock.arrow.circlepath"
            )
        } else {
            List(statsVM.allSessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.phase.rawValue)
                            .font(.body.weight(.medium))
                        Text(dateFormatter.string(from: session.startedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(TimeFormatter.formatHM(session.actualDuration))
                            .font(.body.monospacedDigit())
                        Text(session.wasCompleted ? "Completed" : "Skipped")
                            .font(.caption)
                            .foregroundStyle(session.wasCompleted ? .green : .secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            .listStyle(.plain)
        }
    }
}
