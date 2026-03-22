//
//  TimerReducerTests.swift
//  Still Moment
//
//  Behavior-driven tests for TimerReducer effect mapping.
//  Tests verify the reducer as a pure function: same inputs always produce same outputs.
//

import XCTest
@testable import StillMoment

final class TimerReducerTests: XCTestCase {
    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    private var emptyResolver: MockAttunementResolver {
        MockAttunementResolver()
    }

    // MARK: - StartPressed Tests

    func testStartPressed_producesCorrectEffects() {
        // Given
        let settings = MeditationSettings(
            intervalGongsEnabled: false,
            intervalMinutes: 5,
            backgroundSoundId: "forest",
            durationMinutes: 5
        )

        // When
        let effects = TimerReducer.reduce(
            action: .startPressed,
            timerState: .idle,
            selectedMinutes: 10,
            settings: settings,
            attunementResolver: self.emptyResolver
        )

        // Then - Background audio is NOT started here; it starts in startGongFinished
        XCTAssertEqual(effects.count, 2)
        XCTAssertEqual(effects[0], .activateTimerSession)
        XCTAssertEqual(effects[1], .startTimer(durationMinutes: 10))
    }

    func testStartPressed_producesStartTimerEffect() {
        // When
        let effects = TimerReducer.reduce(
            action: .startPressed,
            timerState: .idle,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertTrue(effects.contains(.startTimer(durationMinutes: 10)))
    }

    func testStartPressed_withZeroMinutes_producesNoEffects() {
        // When
        let effects = TimerReducer.reduce(
            action: .startPressed,
            timerState: .idle,
            selectedMinutes: 0,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertTrue(effects.isEmpty, "Should not start with 0 minutes")
    }

    // MARK: - PreparationFinished Tests

    func testPreparationFinished_playsStartGong() {
        // When
        let effects = TimerReducer.reduce(
            action: .preparationFinished,
            timerState: .preparation,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertEqual(effects, [.playStartGong])
    }

    func testStartGongFinished_fromStartGong_withoutAttunement_startsBackgroundAudio() {
        // When
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: self.defaultSettings.backgroundSoundId,
            volume: self.defaultSettings.backgroundSoundVolume
        )))
    }

    func testStartGongFinished_fromStartGong_withoutAttunement_transitionsToRunning() {
        // Given - no attunement configured
        // When
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then - must transition to running so interval gongs can fire
        XCTAssertTrue(effects.contains(.beginRunningPhase))
    }

    // MARK: - TimerCompleted Tests

    func testTimerCompleted_playsCompletionSoundAndStopsBackgroundAudio() {
        // When
        let effects = TimerReducer.reduce(
            action: .timerCompleted,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertEqual(effects, [.playCompletionSound, .stopBackgroundAudio])
    }

    // MARK: - IntervalGong Tests

    func testIntervalGongTriggered_whenEnabled_playsGongWithVolume() {
        // Given
        let settings = MeditationSettings(intervalGongsEnabled: true, intervalGongVolume: 0.6)

        // When
        let effects = TimerReducer.reduce(
            action: .intervalGongTriggered,
            timerState: .running,
            selectedMinutes: 10,
            settings: settings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertEqual(effects, [.playIntervalGong(soundId: GongSound.defaultIntervalSoundId, volume: 0.6)])
    }

    func testIntervalGongTriggered_whenDisabled_producesNoEffects() {
        // Given
        let settings = MeditationSettings(intervalGongsEnabled: false)

        // When
        let effects = TimerReducer.reduce(
            action: .intervalGongTriggered,
            timerState: .running,
            selectedMinutes: 10,
            settings: settings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }
}
