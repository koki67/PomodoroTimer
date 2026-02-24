import SwiftUI

/// Root view for the floating timer panel.
struct MainPanelView: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(SettingsViewModel.self) private var settingsVM

    var body: some View {
        VStack(spacing: 0) {
            ModeTabsView()
                .padding(.top, 14)
                .padding(.horizontal, 16)

            Spacer(minLength: 8)

            TimerDisplayView()

            Spacer(minLength: 8)

            TimerControlsView()
                .padding(.horizontal, 24)

            Divider()
                .padding(.top, 12)

            StatusBarView()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Timer Display

struct TimerDisplayView: View {
    @Environment(TimerViewModel.self) private var timerVM

    var body: some View {
        Text(timerVM.remainingString)
            .font(.system(size: 54, weight: .thin, design: .monospaced))
            .foregroundStyle(.primary)
            .contentTransition(.numericText(countsDown: true))
            .animation(.linear(duration: 0.3), value: timerVM.remainingString)
    }
}
