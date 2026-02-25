import SwiftUI

/// Root view for the floating timer panel.
struct MainPanelView: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(PanelDisplayState.self) private var panelState

    let onClose: () -> Void
    let onBlend: () -> Void
    let onAlwaysOnTopToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !panelState.isCompact {
                ModeTabsView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer(minLength: 8)

            TimerRingView()

            Spacer(minLength: 8)
        }
        .animation(.easeInOut(duration: 0.4), value: panelState.isCompact)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topLeading) {
            TrafficLightRow(
                onClose: onClose,
                onBlend: onBlend,
                onAlwaysOnTopToggle: onAlwaysOnTopToggle
            )
            .padding(10)
        }
    }
}

// MARK: - Traffic Lights

struct TrafficLightRow: View {
    let onClose: () -> Void
    let onBlend: () -> Void
    let onAlwaysOnTopToggle: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            TrafficLightButton(
                color: Color(red: 1.00, green: 0.37, blue: 0.34),
                icon: "xmark",
                isGroupHovered: isHovering,
                action: onClose
            )
            TrafficLightButton(
                color: Color(red: 0.99, green: 0.74, blue: 0.18),
                icon: "minus",
                isGroupHovered: isHovering,
                action: onBlend
            )
            TrafficLightButton(
                color: Color(red: 0.16, green: 0.78, blue: 0.25),
                icon: "plus",
                isGroupHovered: isHovering,
                action: onAlwaysOnTopToggle
            )
        }
        .onHover { isHovering = $0 }
    }
}

struct TrafficLightButton: View {
    let color: Color
    let icon: String
    let isGroupHovered: Bool
    let action: () -> Void

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay {
                if isGroupHovered {
                    Image(systemName: icon)
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(.black.opacity(0.5))
                }
            }
            .onTapGesture { action() }
    }
}

// MARK: - Timer Ring

struct TimerRingView: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(PanelDisplayState.self) private var panelState

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

                if panelState.isCompact {
                    Button { timerVM.toggleStartPause() } label: {
                        Image(systemName: timerVM.status == .running ? "pause" : "play.fill")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                } else {
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
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: panelState.isCompact)
        }
        .frame(width: 156, height: 156)
    }
}
