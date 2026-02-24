import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM

    var body: some View {
        @Bindable var vm = settingsVM

        Form {
            Section("Window") {
                Toggle("Always on top", isOn: $vm.settings.alwaysOnTop)
                    .help("Keep the timer panel floating above other windows")

                DurationSliderRow(
                    label: "Blend delay",
                    value: $vm.settings.blendDelay,
                    range: 1...10,
                    step: 1,
                    unit: "s"
                )
            }

            Section("Theme") {
                Picker("Appearance", selection: $vm.settings.themeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct DurationSliderRow: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
            Text("\(Int(value.wrappedValue))\(unit)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 32)
        }
    }
}
