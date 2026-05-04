//
//  IntervalModeTests.swift
//  Still Moment
//
//  Tests for IntervalMode enum and MeditationTimer interval gong logic
//

import XCTest
@testable import StillMoment

final class IntervalModeTests: XCTestCase {
    // MARK: - IntervalMode Enum Tests

    func testIntervalMode_allCases() {
        XCTAssertEqual(IntervalMode.allCases.count, 3)
        XCTAssertTrue(IntervalMode.allCases.contains(.repeating))
        XCTAssertTrue(IntervalMode.allCases.contains(.afterStart))
        XCTAssertTrue(IntervalMode.allCases.contains(.beforeEnd))
    }

    func testIntervalMode_codable() throws {
        // Given
        let modes: [IntervalMode] = [.repeating, .afterStart, .beforeEnd]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for mode in modes {
            // When
            let data = try encoder.encode(mode)
            let decoded = try decoder.decode(IntervalMode.self, from: data)

            // Then
            XCTAssertEqual(decoded, mode)
        }
    }

    func testIntervalMode_rawValues() {
        XCTAssertEqual(IntervalMode.repeating.rawValue, "repeating")
        XCTAssertEqual(IntervalMode.afterStart.rawValue, "afterStart")
        XCTAssertEqual(IntervalMode.beforeEnd.rawValue, "beforeEnd")
    }

    // MARK: - Repeating Mode Tests

    func testRepeatingMode_playsAtEachInterval() throws {
        // Given: 20 min meditation, 5 min interval
        var timer = try MeditationTimer(durationMinutes: 20)
        timer = timer.withState(.running)

        // When: 5 minutes elapsed (300 seconds)
        for _ in 0..<300 {
            (timer, _) = timer.tick()
        }

        // Then: should play first gong
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .repeating))

        // When: mark played, advance to 10 minutes
        timer = timer.markIntervalGongPlayed()
        for _ in 0..<300 {
            (timer, _) = timer.tick()
        }

        // Then: should play second gong
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .repeating))

        // When: mark played, advance to 15 minutes
        timer = timer.markIntervalGongPlayed()
        for _ in 0..<300 {
            (timer, _) = timer.tick()
        }

        // Then: should play third gong
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .repeating))
    }

    func testRepeatingMode_noGongBeforeInterval() throws {
        // Given: 10 min meditation, 5 min interval
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // When: only 4 minutes elapsed
        for _ in 0..<240 {
            (timer, _) = timer.tick()
        }

        // Then: no gong yet
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .repeating))
    }

    // MARK: - After Start Mode Tests

    func testAfterStartMode_playsExactlyOnce() throws {
        // Given: 20 min meditation, 5 min interval
        var timer = try MeditationTimer(durationMinutes: 20)
        timer = timer.withState(.running)

        // When: 5 minutes elapsed
        for _ in 0..<300 {
            (timer, _) = timer.tick()
        }

        // Then: should play
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .afterStart))

        // When: mark played, advance 5 more minutes
        timer = timer.markIntervalGongPlayed()
        for _ in 0..<300 {
            (timer, _) = timer.tick()
        }

        // Then: should NOT play again
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .afterStart))
    }

    func testAfterStartMode_noGongBeforeInterval() throws {
        // Given: 20 min meditation, 5 min interval
        var timer = try MeditationTimer(durationMinutes: 20)
        timer = timer.withState(.running)

        // When: only 4 minutes elapsed
        for _ in 0..<240 {
            (timer, _) = timer.tick()
        }

        // Then: no gong
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .afterStart))
    }

    // MARK: - Before End Mode Tests

    func testBeforeEndMode_playsExactlyOnce() throws {
        // Given: 20 min meditation, 5 min before end = at 15:00 elapsed
        var timer = try MeditationTimer(durationMinutes: 20)
        timer = timer.withState(.running)

        // When: 15 minutes elapsed (remaining = 300 seconds = 5 min)
        for _ in 0..<900 {
            (timer, _) = timer.tick()
        }

        // Then: should play (remaining <= intervalSeconds)
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .beforeEnd))

        // When: mark played, advance more
        timer = timer.markIntervalGongPlayed()
        for _ in 0..<60 {
            (timer, _) = timer.tick()
        }

        // Then: should NOT play again
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .beforeEnd))
    }

    func testBeforeEndMode_noGongTooEarly() throws {
        // Given: 20 min meditation, 5 min before end
        var timer = try MeditationTimer(durationMinutes: 20)
        timer = timer.withState(.running)

        // When: only 14 minutes elapsed (remaining = 360 sec > 300 sec)
        for _ in 0..<840 {
            (timer, _) = timer.tick()
        }

        // Then: no gong yet (6 min remaining > 5 min interval)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .beforeEnd))
    }

    // MARK: - 5 Second Protection Tests

    func testFiveSecondProtection_noGongInLastFiveSeconds() throws {
        // Given: 1 min meditation, 1 min interval (repeating)
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.running)

        // When: tick to exactly 5 seconds remaining
        for _ in 0..<55 {
            (timer, _) = timer.tick()
        }

        // Then: remaining = 5, should NOT play (5-second protection)
        XCTAssertEqual(timer.remainingSeconds, 5)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 1, mode: .repeating))
    }

    func testFiveSecondProtection_beforeEndMode() throws {
        // Given: 1 min meditation, 1 min before end
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.running)

        // When: tick to 5 seconds remaining
        for _ in 0..<55 {
            (timer, _) = timer.tick()
        }

        // Then: would normally trigger but 5-second protection prevents it
        XCTAssertEqual(timer.remainingSeconds, 5)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 1, mode: .beforeEnd))
    }

    func testFiveSecondProtection_sixSecondsRemainingIsAllowed() throws {
        // Given: 2 min meditation, 1 min before end (interval < meditation)
        var timer = try MeditationTimer(durationMinutes: 2)
        timer = timer.withState(.running)

        // When: 114 seconds elapsed (6 remaining)
        for _ in 0..<114 {
            (timer, _) = timer.tick()
        }

        // Then: remaining = 6, should be allowed for beforeEnd (6 > 5 protection threshold)
        XCTAssertEqual(timer.remainingSeconds, 6)
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 1, mode: .beforeEnd))
    }

    // MARK: - Edge Cases

    func testIntervalLongerThanMeditation_noGongEarlyInTimer() throws {
        // Given: 5 min meditation, 10 min interval — only a few seconds elapsed
        var timer = try MeditationTimer(durationMinutes: 5)
        timer = timer.withState(.running)

        // When: only 10 seconds elapsed (remaining = 290, well above 5-second protection)
        for _ in 0..<10 {
            (timer, _) = timer.tick()
        }

        // Then: no gong for any mode — interval >= meditation should never trigger
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 10, mode: .repeating))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 10, mode: .afterStart))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 10, mode: .beforeEnd))
    }

    func testIntervalLongerThanMeditation_noGongLateInTimer() throws {
        // Given: 5 min meditation, 10 min interval — near the end
        var timer = try MeditationTimer(durationMinutes: 5)
        timer = timer.withState(.running)

        // When: 295 seconds elapsed (remaining = 5)
        for _ in 0..<295 {
            (timer, _) = timer.tick()
        }

        // Then: no gong for any mode
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 10, mode: .repeating))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 10, mode: .afterStart))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 10, mode: .beforeEnd))
    }

    func testIntervalEqualsMeditation_noGong() throws {
        // Given: 5 min meditation, 5 min interval
        var timer = try MeditationTimer(durationMinutes: 5)
        timer = timer.withState(.running)

        // When: only a few seconds elapsed
        for _ in 0..<10 {
            (timer, _) = timer.tick()
        }

        // Then: no gong for any mode — interval >= meditation should never trigger
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .repeating))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .afterStart))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .beforeEnd))
    }

    func testNotRunning_noGong() throws {
        // Given: timer in idle state
        let timer = try MeditationTimer(durationMinutes: 10)

        // Then: no gong for any mode
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .repeating))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .afterStart))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5, mode: .beforeEnd))
    }

    func testZeroInterval_noGong() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // Then
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 0, mode: .repeating))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: -1, mode: .afterStart))
    }

    // MARK: - MeditationSettings Validation Tests

    func testValidateInterval_clampsToMinimum() {
        XCTAssertEqual(MeditationSettings.validateInterval(0), 1)
        XCTAssertEqual(MeditationSettings.validateInterval(-5), 1)
    }

    func testValidateInterval_clampsToMaximum() {
        XCTAssertEqual(MeditationSettings.validateInterval(61), 60)
        XCTAssertEqual(MeditationSettings.validateInterval(100), 60)
    }

    func testValidateInterval_passesValidValues() {
        XCTAssertEqual(MeditationSettings.validateInterval(1), 1)
        XCTAssertEqual(MeditationSettings.validateInterval(5), 5)
        XCTAssertEqual(MeditationSettings.validateInterval(30), 30)
        XCTAssertEqual(MeditationSettings.validateInterval(60), 60)
    }

    // MARK: - MeditationSettings New Fields Tests

    func testSettings_defaultIntervalMode() {
        let settings = MeditationSettings.default

        XCTAssertEqual(settings.intervalMode, .repeating)
    }

    func testSettings_defaultIntervalSoundId() {
        let settings = MeditationSettings.default

        XCTAssertEqual(settings.intervalSoundId, GongSound.defaultIntervalSoundId)
    }

    func testSettings_customIntervalMode() {
        let settings = MeditationSettings(intervalMode: .beforeEnd)

        XCTAssertEqual(settings.intervalMode, .beforeEnd)
    }

    func testSettings_customIntervalSoundId() {
        let settings = MeditationSettings(intervalSoundId: "temple-bell")

        XCTAssertEqual(settings.intervalSoundId, "temple-bell")
    }

    func testSettings_codable_newFields() throws {
        // Given
        let original = MeditationSettings(
            intervalMode: .afterStart,
            intervalSoundId: "classic-bowl"
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MeditationSettings.self, from: data)

        // Then
        XCTAssertEqual(decoded.intervalMode, .afterStart)
        XCTAssertEqual(decoded.intervalSoundId, "classic-bowl")
    }

    func testSettings_keys_containsNewKeys() {
        XCTAssertEqual(MeditationSettings.Keys.intervalMode, "intervalMode")
        XCTAssertEqual(MeditationSettings.Keys.intervalSoundId, "intervalSoundId")
    }

    // MARK: - GongSound Interval Sounds Tests

    func testGongSound_allIntervalSounds_hasSixSounds() {
        XCTAssertEqual(GongSound.allIntervalSounds.count, 6)
    }

    func testGongSound_allIntervalSounds_containsSoftIntervalTone() {
        let softTone = GongSound.allIntervalSounds.first { $0.id == "soft-interval" }
        XCTAssertNotNil(softTone)
        XCTAssertEqual(softTone?.filename, "interval.mp3")
        XCTAssertFalse(softTone?.name.isEmpty ?? true, "Soft interval tone should have a name")
    }

    func testGongSound_allIntervalSounds_containsAllStandardSounds() {
        let standardIds = ["temple-bell", "classic-bowl", "deep-resonance", "clear-strike"]
        for id in standardIds {
            XCTAssertNotNil(
                GongSound.allIntervalSounds.first { $0.id == id },
                "Expected interval sound with id '\(id)' to exist"
            )
        }
    }

    func testGongSound_defaultIntervalSoundId() {
        XCTAssertEqual(GongSound.defaultIntervalSoundId, "soft-interval")
    }

    func testGongSound_find_findsIntervalSound() {
        let sound = GongSound.find(byId: "soft-interval")
        XCTAssertNotNil(sound)
        XCTAssertEqual(sound?.id, "soft-interval")
    }

    // MARK: - TimerReducer Interval Effect Tests

    func testReducer_intervalGongTriggered_includesSoundId() {
        // Given
        let settings = MeditationSettings(
            intervalGongsEnabled: true,
            intervalSoundId: "classic-bowl",
            intervalGongVolume: 0.7
        )

        // When
        let effects = TimerReducer.reduce(
            action: .intervalGongTriggered,
            timerState: .running,
            selectedMinutes: 10,
            settings: settings
        )

        // Then
        XCTAssertEqual(effects, [.playIntervalGong(soundId: "classic-bowl", volume: 0.7)])
    }
}
