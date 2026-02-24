import SwiftUI

/// Play/Pause (center), Reset (left), Skip (right) controls.
struct TimerControlsView: View {
    @Environment(TimerViewModel.self) private var timerVM

    var body: some View {
        HStack {
            // Reset
            ControlButton(
                systemName: "arrow.counterclockwise",
                size: .secondary,
                action: timerVM.reset
            )

            Spacer()

            // Play / Pause (primary)
            ControlButton(
                systemName: timerVM.status == .running ? "pause.fill" : "play.fill",
                size: .primary,
                action: timerVM.toggleStartPause
            )

            Spacer()

            // Skip
            ControlButton(
                systemName: "forward.end.fill",
                size: .secondary,
                action: timerVM.skip
            )
        }
    }
}

// MARK: - Reusable Control Button

private enum ControlButtonSize { case primary, secondary }

private struct ControlButton: View {
    let systemName: String
    let size: ControlButtonSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(size == .primary ? .title : .title2)
                .foregroundStyle(size == .primary ? Color.accentColor : .secondary)
                .frame(width: size == .primary ? 44 : 32, height: size == .primary ? 44 : 32)
                .background(
                    Circle()
                        .fill(size == .primary
                              ? Color.accentColor.opacity(0.1)
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
