import SwiftUI

/// Root settings window with tab navigation.
struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM

    var body: some View {
        TabView {
            TimerSettingsView()
                .tabItem { Label("Timer", systemImage: "timer") }

            SoundSettingsView()
                .tabItem { Label("Sound", systemImage: "speaker.wave.2.fill") }

            NotificationSettingsView()
                .tabItem { Label("Notifications", systemImage: "bell.fill") }

            HotkeySettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard.fill") }

            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush.fill") }
        }
        .frame(minWidth: 460, minHeight: 380)
    }
}
