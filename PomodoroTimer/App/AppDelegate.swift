import AppKit

/// Application lifecycle manager. Owns and wires together all services,
/// view models, and window controllers.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Services (single instances, owned here)

    let persistence   = PersistenceService()
    let hotkeyService = HotkeyService()

    // Timer engine depends on loaded settings
    private(set) lazy var timerEngine: TimerEngine = {
        let settings = persistence.loadSettings() ?? AppSettings()
        let engine = TimerEngine(settings: settings, persistence: persistence)
        engine.onSessionComplete = { [weak self] session in
            guard let self else { return }
            // Auto-advance if enabled
            if session.wasCompleted {
                let s = self.settingsVM.settings
                let nextPhase = self.timerEngine.phase
                let shouldAutoStart = (nextPhase == .focus && s.autoStartFocus)
                    || (nextPhase != .focus && s.autoStartBreaks)
                if shouldAutoStart {
                    self.timerVM.toggleStartPause()
                }
            }
            // Forced break screen
            if self.settingsVM.settings.forceBreakScreenEnabled {
                if session.phase == .focus {
                    // Focus ended → show overlay; ensure break timer is running
                    self.breakOverlayController?.show()
                    if self.timerEngine.status == .idle {
                        self.timerVM.toggleStartPause()
                    }
                } else {
                    // Break ended → dismiss overlay
                    self.breakOverlayController?.hide()
                }
            }
        }
        return engine
    }()

    // MARK: - ViewModels

    private(set) lazy var settingsVM: SettingsViewModel = {
        let settings = persistence.loadSettings() ?? AppSettings()
        let vm = SettingsViewModel(settings: settings, persistence: persistence)
        vm.onSettingsChanged = { [weak self] newSettings in
            self?.timerEngine.updateSettings(newSettings)
            self?.mainPanelController?.applyAppearance(newSettings.themeMode)
        }
        return vm
    }()

    private(set) lazy var timerVM: TimerViewModel = {
        TimerViewModel(engine: timerEngine)
    }()

    // MARK: - Window Controllers

    private var menuBarController: MenuBarController?
    private var mainPanelController: MainPanelController?
    private var settingsWindowController: SettingsWindowController?
    private var breakOverlayController: BreakOverlayController?

    // MARK: - Observers

    private var sleepWakeObserver: SleepWakeObserver?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock; run as menu bar accessory.
        // LSUIElement in Info.plist also handles this at launch time.
        NSApp.setActivationPolicy(.accessory)

        // Build menu bar + panel
        menuBarController = MenuBarController(timerVM: timerVM, settingsVM: settingsVM)
        menuBarController?.onOpenMainPanel = { [weak self] in
            self?.mainPanelController?.show()
        }
        menuBarController?.onOpenSettings = { [weak self] in
            self?.showSettings()
        }

        mainPanelController = MainPanelController(timerVM: timerVM, settingsVM: settingsVM)
        mainPanelController?.show()

        breakOverlayController = BreakOverlayController(timerVM: timerVM)
        breakOverlayController?.onSkip = { [weak self] in
            self?.timerVM.skip()
            // hide() is called by onSessionComplete when break phase ends;
            // then immediately start the next focus session
            self?.timerVM.toggleStartPause()
        }

        // Sleep/wake observer for timer accuracy
        sleepWakeObserver = SleepWakeObserver { [weak self] event in
            switch event {
            case .wake:  self?.timerEngine.handleWake()
            case .sleep: self?.timerEngine.saveSnapshot()
            }
        }

        // Register global hotkeys
        hotkeyService.register(settings: settingsVM.settings) { [weak self] action in
            self?.handleHotkeyAction(action)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerEngine.saveSnapshot()
        persistence.saveSettings(settingsVM.settings)
        mainPanelController?.saveFrame()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false  // Belt + suspenders alongside LSUIElement
    }

    // MARK: - Settings Window

    func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                settingsVM: settingsVM
            )
        }
        settingsWindowController?.show()
    }

    // MARK: - Hotkey Dispatch

    private func handleHotkeyAction(_ action: HotkeyAction) {
        switch action {
        case .startPause:  timerVM.toggleStartPause()
        case .skip:        timerVM.skip()
        case .reset:       timerVM.reset()
        case .togglePanel: mainPanelController?.toggle()
        }
    }

}
