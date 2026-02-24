import XCTest

@MainActor
final class TimerEngineTests: XCTestCase {

    var engine: TimerEngine!
    var persistence: PersistenceService!
    var recordedSessions: [Session] = []
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        persistence = PersistenceService(baseURL: tempDir)

        recordedSessions = []
        var settings = AppSettings()
        settings.focusDuration      = 1500  // 25 min
        settings.shortBreakDuration = 300   // 5 min
        settings.longBreakDuration  = 900   // 15 min
        settings.longBreakInterval  = 4

        engine = TimerEngine(settings: settings, persistence: persistence)
        engine.onSessionComplete = { [weak self] session in
            self?.recordedSessions.append(session)
        }
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    // MARK: - Start / Pause / Reset

    func testInitialStateIsIdle() {
        XCTAssertEqual(engine.status, .idle)
        XCTAssertEqual(engine.phase,  .focus)
        XCTAssertEqual(engine.remaining, 1500, accuracy: 0.1)
    }

    func testStartTransitionsToRunning() {
        engine.start()
        XCTAssertEqual(engine.status, .running)
    }

    func testPauseFromRunning() {
        engine.start()
        engine.pause()
        XCTAssertEqual(engine.status, .paused)
    }

    func testResumeFromPaused() {
        engine.start()
        engine.pause()
        engine.start()
        XCTAssertEqual(engine.status, .running)
    }

    func testResetReturnsToIdleWithFullDuration() {
        engine.start()
        engine.reset()
        XCTAssertEqual(engine.status, .idle)
        XCTAssertEqual(engine.remaining, 1500, accuracy: 0.5)
    }

    func testPausePreservesRemainingApprox() {
        engine.start()
        let before = engine.remaining
        engine.pause()
        XCTAssertEqual(engine.remaining, before, accuracy: 1.0)
    }

    // MARK: - Skip

    func testSkipFromRunningRecordsPartialSession() {
        engine.start()
        engine.skip()
        XCTAssertEqual(recordedSessions.count, 1)
        XCTAssertFalse(recordedSessions[0].wasCompleted)
        XCTAssertEqual(recordedSessions[0].phase, .focus)
    }

    func testSkipFromIdleDoesNotRecordSession() {
        engine.skip()
        XCTAssertEqual(recordedSessions.count, 0)
    }

    // MARK: - Cycle Logic

    func testFocusAdvancesToShortBreak() {
        engine.start()
        engine.skip()
        XCTAssertEqual(engine.phase, .shortBreak)
        XCTAssertEqual(engine.status, .idle)
    }

    func testShortBreakAdvancesToFocus() {
        // Advance to short break first
        engine.start(); engine.skip()
        XCTAssertEqual(engine.phase, .shortBreak)
        engine.start(); engine.skip()
        XCTAssertEqual(engine.phase, .focus)
    }

    func testLongBreakAfterConfiguredInterval() {
        var settings = AppSettings()
        settings.focusDuration      = 1500
        settings.shortBreakDuration = 300
        settings.longBreakDuration  = 900
        settings.longBreakInterval  = 2

        engine = TimerEngine(settings: settings, persistence: persistence)
        engine.onSessionComplete = { [weak self] s in self?.recordedSessions.append(s) }

        // Focus 1 → short break
        engine.start(); engine.skip()
        XCTAssertEqual(engine.phase, .shortBreak)
        // Short break → focus
        engine.start(); engine.skip()
        XCTAssertEqual(engine.phase, .focus)
        // Focus 2 (cycleFocusCount = 1 after skip, then 2 after this) → long break
        engine.start(); engine.skip()
        XCTAssertEqual(engine.phase, .longBreak)
    }

    // MARK: - Phase Selection

    func testSelectPhaseWhenIdle() {
        engine.selectPhase(.shortBreak)
        XCTAssertEqual(engine.phase, .shortBreak)
        XCTAssertEqual(engine.remaining, 300, accuracy: 0.1)
    }

    func testSelectPhaseIgnoredWhenRunning() {
        let originalPhase = engine.phase
        engine.start()
        engine.selectPhase(.longBreak)
        XCTAssertEqual(engine.phase, originalPhase) // unchanged
    }

    // MARK: - Snapshot Persistence

    func testSaveAndRestoreSnapshotAsPaused() {
        engine.start()
        // Simulate engine running for "1 second" by saving a fresh snapshot
        engine.saveSnapshot()
        let snap = persistence.loadTimerSnapshot()
        XCTAssertNotNil(snap)
        XCTAssertEqual(snap?.status, .running)
    }

    func testRestoreAdjustsForElapsedTime() {
        // Manually inject a snapshot that was saved 60s ago with 1500s remaining
        let snap = TimerSnapshot(
            phase: .focus,
            status: .running,
            remainingSeconds: 1500,
            completedFocusSessions: 0,
            savedAt: Date().addingTimeInterval(-60)
        )
        persistence.saveTimerSnapshot(snap)

        let newEngine = TimerEngine(settings: AppSettings(), persistence: persistence)
        newEngine.restoreSnapshot()

        XCTAssertEqual(newEngine.status, .paused)
        XCTAssertEqual(newEngine.remaining, 1440, accuracy: 2.0)
    }

    func testRestoreWhenSessionExpiredDuringQuit() {
        // Snapshot from 2000s ago with only 1500s remaining → expired
        let snap = TimerSnapshot(
            phase: .focus,
            status: .running,
            remainingSeconds: 1500,
            completedFocusSessions: 0,
            savedAt: Date().addingTimeInterval(-2000)
        )
        persistence.saveTimerSnapshot(snap)

        let newEngine = TimerEngine(settings: AppSettings(), persistence: persistence)
        newEngine.restoreSnapshot()

        // Should have advanced to the next phase (short break)
        XCTAssertEqual(newEngine.status, .idle)
        XCTAssertEqual(newEngine.phase, .shortBreak)
    }
}
