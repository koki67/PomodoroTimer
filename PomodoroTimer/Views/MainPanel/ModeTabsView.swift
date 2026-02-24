import SwiftUI

/// Tab bar for switching between Focus / Short Break / Long Break.
/// Only active when the timer is idle (not running or paused).
struct ModeTabsView: View {
    @Environment(TimerViewModel.self) private var timerVM

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TimerPhase.allCases) { phase in
                TabButton(phase: phase, selected: timerVM.phase == phase) {
                    timerVM.selectPhase(phase)
                }
            }
        }
    }
}

private struct TabButton: View {
    let phase: TimerPhase
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(phase.shortName)
                .font(.caption.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? Color.accentColor : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    selected
                        ? Color.accentColor.opacity(0.12)
                        : Color.clear,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
