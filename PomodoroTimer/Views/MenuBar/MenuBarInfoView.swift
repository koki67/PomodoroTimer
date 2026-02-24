import SwiftUI

/// Shown as the top info row inside the NSMenu dropdown.
struct MenuBarInfoView: View {
    @Environment(TimerViewModel.self) private var timerVM

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: phaseIcon)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(timerVM.phase.rawValue)
                    .font(.caption.weight(.semibold))
                Text(timerVM.remainingString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var phaseIcon: String {
        switch timerVM.phase {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "figure.walk"
        }
    }
}
