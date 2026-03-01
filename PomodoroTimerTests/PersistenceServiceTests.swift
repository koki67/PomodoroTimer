import XCTest

final class PersistenceServiceTests: XCTestCase {

    var service: PersistenceService!
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        service = PersistenceService(baseURL: tempDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Settings

    func testRoundtripDefaultSettings() {
        let settings = AppSettings()
        service.saveSettings(settings)
        let loaded = service.loadSettings()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.focusDuration, settings.focusDuration)
        XCTAssertEqual(loaded?.longBreakInterval, settings.longBreakInterval)
    }

    func testRoundtripModifiedSettings() {
        var settings = AppSettings()
        settings.focusDuration = 30 * 60
        settings.shortBreakDuration = 10 * 60
        service.saveSettings(settings)

        let loaded = service.loadSettings()
        XCTAssertEqual(loaded?.focusDuration, 30 * 60)
        XCTAssertEqual(loaded?.shortBreakDuration, 10 * 60)
    }

    func testLoadSettingsReturnsNilWhenNoFile() {
        XCTAssertNil(service.loadSettings())
    }

    // MARK: - Timer Snapshot

    func testRoundtripTimerSnapshot() {
        let snap = TimerSnapshot(
            phase: .shortBreak,
            status: .paused,
            remainingSeconds: 300,
            completedFocusSessions: 2,
            savedAt: Date()
        )
        service.saveTimerSnapshot(snap)
        let loaded = service.loadTimerSnapshot()
        XCTAssertEqual(loaded?.phase, .shortBreak)
        XCTAssertEqual(loaded?.status, .paused)
        XCTAssertEqual(loaded?.remainingSeconds, 300)
        XCTAssertEqual(loaded?.completedFocusSessions, 2)
    }

    // MARK: - Atomic Write Integrity

    func testLastWriteWinsOnRapidSaves() {
        var s1 = AppSettings(); s1.focusDuration = 1200
        var s2 = AppSettings(); s2.focusDuration = 2700
        service.saveSettings(s1)
        service.saveSettings(s2)
        XCTAssertEqual(service.loadSettings()?.focusDuration, 2700)
    }
}
