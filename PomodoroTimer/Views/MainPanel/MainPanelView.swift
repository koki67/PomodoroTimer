import SwiftUI

/// Root view for the floating timer panel.
struct MainPanelView: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(SettingsViewModel.self) private var settingsVM

    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)
            TimerRingView()
            Spacer(minLength: 8)
        }
        .padding(.top, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topLeading) {
            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Timer Ring

struct TimerRingView: View {
    @Environment(TimerViewModel.self) private var timerVM

    private var phaseColor: Color {
        switch timerVM.phase {
        case .focus:      return Color(red: 0.78, green: 0.36, blue: 0.30)
        case .shortBreak: return Color(red: 0.33, green: 0.60, blue: 0.50)
        case .longBreak:  return Color(red: 0.40, green: 0.52, blue: 0.68)
        }
    }

    var body: some View {
        ZStack {
            // Faint track
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 5)
            // Draining progress arc
            Circle()
                .trim(from: 1 - timerVM.progress, to: 1)
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: timerVM.progress)
            // Center content: time + controls
            VStack(spacing: 10) {
                Text(timerVM.remainingString)
                    .font(.system(size: 42, weight: .thin, design: .monospaced))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.3), value: timerVM.remainingString)

                HStack(spacing: 14) {
                    Button(action: timerVM.reset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: timerVM.toggleStartPause) {
                        Image(systemName: timerVM.status == .running ? "pause" : "play.fill")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)

                    Button(action: timerVM.skip) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 156, height: 156)
    }
}
