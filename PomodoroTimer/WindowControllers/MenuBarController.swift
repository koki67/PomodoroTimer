import AppKit
import SwiftUI

/// Manages the NSStatusItem (menu bar icon + menu).
@MainActor
final class MenuBarController {

    private var statusItem: NSStatusItem!
    private let timerVM: TimerViewModel
    private let settingsVM: SettingsViewModel

    // Weak references to items that need dynamic title updates
    private var startPauseItem: NSMenuItem?
    private var modeItem: NSMenuItem?
    private var remainingItem: NSMenuItem?

    // Callbacks injected from AppDelegate
    var onOpenMainPanel: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    init(timerVM: TimerViewModel, settingsVM: SettingsViewModel) {
        self.timerVM    = timerVM
        self.settingsVM = settingsVM
        buildStatusItem()
        buildMenu()
        startPolling()
    }

    // MARK: - Build

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro Timer")
        button.imagePosition = .imageLeft
        button.title = "  25:00"
    }

    private func buildMenu() {
        let menu = NSMenu()

        // Mode label (read-only, top)
        let modeItem = makeInfoItem("Focus")
        self.modeItem = modeItem
        menu.addItem(modeItem)

        // Remaining time label
        let remainingItem = makeInfoItem("25:00")
        self.remainingItem = remainingItem
        menu.addItem(remainingItem)

        menu.addItem(.separator())

        // Start/Pause
        let startPause = NSMenuItem(
            title: "Start",
            action: #selector(toggleStartPause),
            keyEquivalent: ""
        )
        startPause.target = self
        self.startPauseItem = startPause
        menu.addItem(startPause)

        // Reset
        let reset = NSMenuItem(title: "Reset", action: #selector(reset), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        // Skip
        let skip = NSMenuItem(title: "Skip", action: #selector(skip), keyEquivalent: "")
        skip.target = self
        menu.addItem(skip)

        menu.addItem(.separator())

        let openPanel = NSMenuItem(
            title: "Open Timer Panel",
            action: #selector(openMainPanel),
            keyEquivalent: ""
        )
        openPanel.target = self
        menu.addItem(openPanel)

        let openSettings = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        openSettings.target = self
        menu.addItem(openSettings)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit PomodoroTimer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func makeInfoItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = title
        item.isEnabled = false
        return item
    }

    // MARK: - Update

    func updateDisplay() {
        let remaining = timerVM.remainingString
        let phase     = timerVM.phase.rawValue
        let isRunning = timerVM.status == .running

        // Status bar button title
        statusItem.button?.title = "  \(remaining)"

        // Menu items
        modeItem?.title      = phase
        remainingItem?.title = remaining
        startPauseItem?.title = isRunning ? "Pause" : "Start"
    }

    // MARK: - Polling

    /// Poll timer state every 0.5s to update the menu bar title.
    private func startPolling() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateDisplay() }
        }
    }

    // MARK: - Actions

    @objc private func toggleStartPause() { timerVM.toggleStartPause() }
    @objc private func reset()            { timerVM.reset() }
    @objc private func skip()             { timerVM.skip() }
    @objc private func openMainPanel()    { onOpenMainPanel?() }
    @objc private func openSettings()     { onOpenSettings?() }
}
