import SwiftUI

/// Content displayed on the full-screen break overlay.
/// Ultra-minimal: just the break countdown centered on the blurred screen.
struct BreakOverlayView: View {
    @Environment(TimerViewModel.self) private var timerVM
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text(timerVM.remainingString)
                    .font(.system(size: 80, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.3), value: timerVM.remainingString)

                Button("skip") { onSkip() }
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.tertiary)
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
