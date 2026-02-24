import SwiftUI

@main
struct PomodoroTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The Settings scene provides the macOS Settings… menu item (Cmd+,)
        // and manages the settings window lifecycle automatically.
        Settings {
            SettingsView()
                .environment(appDelegate.settingsVM)
                .environment(appDelegate.statsVM)
                .environment(appDelegate.audioService)
        }
    }
}
