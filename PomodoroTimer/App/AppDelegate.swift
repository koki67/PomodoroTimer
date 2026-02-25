import AppKit
import Combine

/// Application lifecycle manager. Owns and wires together all services,
/// view models, and window controllers.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Services (single instances, owned here)

    let persistence     = PersistenceService()
    let audioService    = AudioService()
    let hotkeyService   = HotkeyService()
    let notificationService = NotificationService.shared

    // Stats store depends on persistence
    private(set) lazy var statsStore = StatsStore(persistence: persistence)

    // Timer engine depends on loaded settings
    private(set) lazy var timerEngine: TimerEngine = {
        let settings = persistence.loadSettings() ?? AppSettings()
        let engine = TimerEngine(settings: settings, persistence: persistence)
        engine.onSessionComplete = { [weak self] session in
            guard let self else { return }
            self.statsStore.record(session)
            // Fire notification
            let soundName = session.phase == .focus
                ? self.settingsVM.settings.focusEndSound
                : self.settingsVM.settings.breakEndSound
            if self.settingsVM.settings.notificationsEnabled {
                self.notificationService.send(for: session.phase, soundName: soundName)
            }
            // Stop ambient sound at session boundary (next start re-triggers it)
            self.audioService.stop()
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
        TimerViewModel(engine: timerEngine, audio: audioService, statsStore: statsStore)
    }()

    private(set) lazy var statsVM: StatsViewModel = {
        StatsViewModel(store: statsStore, persistence: persistence)
    }()

    // MARK: - Window Controllers

    private var menuBarController: MenuBarController?
    private var mainPanelController: MainPanelController?
    private var settingsWindowController: SettingsWindowController?

    // MARK: - Observers

    private var sleepWakeObserver: SleepWakeObserver?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock; run as menu bar accessory.
        // LSUIElement in Info.plist also handles this at launch time.
        NSApp.setActivationPolicy(.accessory)

        // Request notification permission
        notificationService.requestAuthorization()

        // Restore timer state from last session
        timerEngine.restoreSnapshot()

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
                settingsVM: settingsVM,
                statsVM: statsVM,
                audio: audioService
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
