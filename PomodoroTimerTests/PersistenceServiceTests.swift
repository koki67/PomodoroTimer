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
        settings.ambientSoundEnabled = true
        settings.selectedAmbientSound = .cafe
        service.saveSettings(settings)

        let loaded = service.loadSettings()
        XCTAssertEqual(loaded?.focusDuration, 30 * 60)
        XCTAssertEqual(loaded?.shortBreakDuration, 10 * 60)
        XCTAssertTrue(loaded?.ambientSoundEnabled ?? false)
        XCTAssertEqual(loaded?.selectedAmbientSound, .cafe)
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

    // MARK: - Sessions

    func testAppendAndLoadOneSesssion() {
        let session = makeSession()
        service.appendSession(session)
        let loaded = service.loadAllSessions()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, session.id)
    }

    func testAppendMultipleSessions() {
        (0..<5).forEach { _ in service.appendSession(makeSession()) }
        XCTAssertEqual(service.loadAllSessions().count, 5)
    }

    func testClearSessions() {
        service.appendSession(makeSession())
        service.clearAllSessions()
        XCTAssertTrue(service.loadAllSessions().isEmpty)
    }

    func testLoadSessionsReturnsEmptyWhenNoFile() {
        XCTAssertTrue(service.loadAllSessions().isEmpty)
    }

    // MARK: - Atomic Write Integrity

    func testLastWriteWinsOnRapidSaves() {
        var s1 = AppSettings(); s1.focusDuration = 1200
        var s2 = AppSettings(); s2.focusDuration = 2700
        service.saveSettings(s1)
        service.saveSettings(s2)
        XCTAssertEqual(service.loadSettings()?.focusDuration, 2700)
    }

    // MARK: - CSV Export

    func testCSVExportFormat() {
        let session = Session(
            id: UUID(),
            phase: .focus,
            startedAt: Date(timeIntervalSince1970: 0),
            duration: 1500,
            completedAt: Date(timeIntervalSince1970: 1500),
            wasCompleted: true
        )
        service.appendSession(session)
        let csv = CSVExporter.export(service.loadAllSessions())
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.first, "id,phase,startedAt,completedAt,plannedDurationSec,actualDurationSec,wasCompleted")
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].contains("Focus"))
        XCTAssertTrue(lines[1].contains("true"))
    }

    // MARK: - Helpers

    private func makeSession(phase: TimerPhase = .focus) -> Session {
        Session(
            id: UUID(),
            phase: phase,
            startedAt: Date(),
            duration: 1500,
            completedAt: Date().addingTimeInterval(1500),
            wasCompleted: true
        )
    }
}
