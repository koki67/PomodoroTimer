import SwiftUI

struct TimerSettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM

    var body: some View {
        @Bindable var vm = settingsVM

        Form {
            Section("Focus") {
                DurationSlider(
                    label: "Focus duration",
                    value: Binding(
                        get: { settingsVM.focusDurationMinutes },
                        set: { settingsVM.focusDurationMinutes = $0 }
                    ),
                    range: 5...90,
                    step: 5
                )
            }

            Section("Breaks") {
                DurationSlider(
                    label: "Short break",
                    value: Binding(
                        get: { settingsVM.shortBreakMinutes },
                        set: { settingsVM.shortBreakMinutes = $0 }
                    ),
                    range: 1...30,
                    step: 1
                )

                DurationSlider(
                    label: "Long break",
                    value: Binding(
                        get: { settingsVM.longBreakMinutes },
                        set: { settingsVM.longBreakMinutes = $0 }
                    ),
                    range: 5...60,
                    step: 5
                )

                Stepper(
                    "Long break after \(vm.settings.longBreakInterval) sessions",
                    value: $vm.settings.longBreakInterval,
                    in: 2...8
                )
            }

            Section("Auto-advance") {
                Toggle("Start breaks automatically", isOn: $vm.settings.autoStartBreaks)
                Toggle("Start focus automatically", isOn: $vm.settings.autoStartFocus)
            }

            Section("Daily Goal") {
                Stepper(
                    "\(vm.settings.dailySessionGoal) sessions",
                    value: $vm.settings.dailySessionGoal,
                    in: 1...20
                )
                Stepper(
                    "\(vm.settings.dailyFocusGoalMinutes) minutes of focus",
                    value: $vm.settings.dailyFocusGoalMinutes,
                    in: 15...480,
                    step: 15
                )
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Duration Slider Helper

private struct DurationSlider: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(Int(value.wrappedValue)) min")
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 60, alignment: .trailing)
        }
        Slider(value: value, in: range, step: step)
    }
}
