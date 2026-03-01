import SwiftUI

/// Root view for the floating timer panel.
struct MainPanelView: View {
    @Environment(TimerViewModel.self) private var timerVM

    let onClose: () -> Void

    @State private var showClose = false
    @State private var hideTask: DispatchWorkItem?

    var body: some View {
        ZStack {
            TimerRingView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear.contentShape(Rectangle()))
        .onHover { hovering in
            if hovering {
                hideTask?.cancel()
                hideTask = nil
                showClose = true
            } else {
                let work = DispatchWorkItem { showClose = false }
                hideTask = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
            }
        }
        .overlay(alignment: .topLeading) {
            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Circle().fill(.regularMaterial).opacity(0.7))
                    .padding(8)
            }
            .buttonStyle(.plain)
            .opacity(showClose ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: showClose)
        }
    }
}

// MARK: - Timer Ring

struct TimerRingView: View {
    @Environment(TimerViewModel.self) private var timerVM

    private var phaseColor: Color {
        switch timerVM.phase {
        case .focus:      return Color(red: 0.70, green: 0.48, blue: 0.40)
        case .shortBreak: return Color(red: 0.48, green: 0.62, blue: 0.52)
        case .longBreak:  return Color(red: 0.48, green: 0.54, blue: 0.66)
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
