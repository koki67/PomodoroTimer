import SwiftUI

/// Bottom strip showing today's total focus time and session count vs daily goal.
struct StatusBarView: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(SettingsViewModel.self) private var settingsVM

    var body: some View {
        HStack {
            Label(
                TimeFormatter.formatHM(timerVM.todayFocusTime),
                systemImage: "clock.fill"
            )

            Spacer()

            Text("\(timerVM.todaySessionCount) / \(settingsVM.settings.dailySessionGoal)")
                + Text(" sessions")
                .foregroundStyle(.tertiary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
