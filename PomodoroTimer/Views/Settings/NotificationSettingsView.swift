import SwiftUI

struct NotificationSettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM

    // Common macOS NSSound names the user can choose from.
    private let soundNames = ["Default", "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass",
                               "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]

    var body: some View {
        @Bindable var vm = settingsVM

        Form {
            Section {
                Toggle("Enable notifications", isOn: $vm.settings.notificationsEnabled)
            }

            if settingsVM.settings.notificationsEnabled {
                Section("Notification Sounds") {
                    Picker("Focus session ends", selection: $vm.settings.focusEndSound) {
                        ForEach(soundNames, id: \.self) { Text($0) }
                    }
                    Picker("Break session ends", selection: $vm.settings.breakEndSound) {
                        ForEach(soundNames, id: \.self) { Text($0) }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
