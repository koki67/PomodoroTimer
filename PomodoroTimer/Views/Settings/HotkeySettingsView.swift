import SwiftUI

struct HotkeySettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM

    var body: some View {
        Form {
            Section("Global Shortcuts") {
                ShortcutRow(label: "Start / Pause", setting: settingsVM.settings.hotkeyStartPause)
                ShortcutRow(label: "Skip session",   setting: settingsVM.settings.hotkeySkip)
                ShortcutRow(label: "Reset timer",    setting: settingsVM.settings.hotkeyReset)
                ShortcutRow(label: "Show / Hide panel", setting: settingsVM.settings.hotkeyTogglePanel)
            }

            Section {
                Text("Shortcuts use Carbon hotkeys and are active system-wide. Changes take effect after restarting the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct ShortcutRow: View {
    let label: String
    let setting: HotkeySetting

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(setting.displayString)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
        }
    }
}
