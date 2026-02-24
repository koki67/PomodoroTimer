import AppKit
import SwiftUI

/// Opens and manages the Settings window (a regular, activating NSWindow).
@MainActor
final class SettingsWindowController: NSWindowController {

    convenience init(settingsVM: SettingsViewModel, statsVM: StatsViewModel, audio: AudioService) {
        let rootView = SettingsView()
            .environment(settingsVM)
            .environment(statsVM)
            .environment(audio)

        let hosting = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hosting)
        window.title = "PomodoroTimer Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 480, height: 500))
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
