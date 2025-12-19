//
//  TimerReducerTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

final class TimerReducerTests: XCTestCase {
    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    // MARK: - selectDuration Tests

    func testSelectDuration_updatesSelectedMinutes() {
        // Given
        let state = TimerDisplayState.initial

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .selectDuration(minutes: 20),
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.selectedMinutes, 20)
        XCTAssertTrue(effects.isEmpty, "selectDuration should not produce effects")
    }

    func testSelectDuration_clampsToValidRange() {
        // Given
        let state = TimerDisplayState.initial

        // When - over 60
        let (newState1, _) = TimerReducer.reduce(
            state: state,
            action: .selectDuration(minutes: 100),
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState1.selectedMinutes, 60)

        // When - under 1
        let (newState2, _) = TimerReducer.reduce(
            state: state,
            action: .selectDuration(minutes: 0),
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState2.selectedMinutes, 1)
    }

    // MARK: - startPressed Tests

    func testStartPressed_fromIdle_producesCorrectEffects() {
        // Given
        var state = TimerDisplayState.initial
        state.selectedMinutes = 10
        let settings = MeditationSettings(
            intervalGongsEnabled: false,
            intervalMinutes: 5,
            backgroundSoundId: "forest",
            durationMinutes: 5 // Different from selectedMinutes to test update
        )

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: settings
        )

        // Then - settings should be updated with selectedMinutes
        var expectedSettings = settings
        expectedSettings.durationMinutes = 10

        XCTAssertEqual(effects.count, 4)
        XCTAssertEqual(effects[0], .configureAudioSession)
        XCTAssertEqual(effects[1], .startBackgroundAudio(soundId: "forest"))
        XCTAssertEqual(effects[2], .startTimer(durationMinutes: 10))
        XCTAssertEqual(effects[3], .saveSettings(expectedSettings))
    }

    func testStartPressed_rotatesAffirmationIndex() {
        // Given
        var state = TimerDisplayState.initial
        state.currentAffirmationIndex = 2

        // When
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.currentAffirmationIndex, 3)
    }

    func testStartPressed_resetsIntervalGongFlag() {
        // Given
        var state = TimerDisplayState.initial
        state.intervalGongPlayedForCurrentInterval = true

        // When
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertFalse(newState.intervalGongPlayedForCurrentInterval)
    }

    func testStartPressed_withZeroMinutes_producesNoEffects() {
        // Given
        var state = TimerDisplayState.initial
        state.selectedMinutes = 0

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertTrue(effects.isEmpty, "Should not start with 0 minutes")
        XCTAssertEqual(newState.timerState, .idle)
    }

    // MARK: - pausePressed Tests

    func testPausePressed_fromRunning_producesPauseEffect() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(effects, [.pauseTimer])
    }

    func testPausePressed_fromNonRunning_producesNoEffect() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .idle

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - resumePressed Tests

    func testResumePressed_fromPaused_producesResumeEffect() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .paused

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .resumePressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(effects, [.resumeTimer])
    }

    func testResumePressed_fromNonPaused_producesNoEffect() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .resumePressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - resetPressed Tests

    func testResetPressed_producesResetEffects() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.remainingSeconds = 300

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(effects, [.stopBackgroundAudio, .resetTimer])
        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertEqual(newState.remainingSeconds, 0)
        XCTAssertEqual(newState.progress, 0.0)
        XCTAssertEqual(newState.countdownSeconds, 0)
    }

    func testResetPressed_fromIdle_producesNoEffect() {
        // Given
        let state = TimerDisplayState.initial

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - tick Tests

    func testTick_updatesStateFromTimerService() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running

        // When
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .tick(
                remainingSeconds: 540,
                totalSeconds: 600,
                countdownSeconds: 0,
                progress: 0.1,
                state: .running
            ),
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.remainingSeconds, 540)
        XCTAssertEqual(newState.totalSeconds, 600)
        XCTAssertEqual(newState.progress, 0.1)
        XCTAssertEqual(newState.timerState, .running)
    }

    // MARK: - countdownFinished Tests

    func testCountdownFinished_playsStartGong() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .countdown

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .countdownFinished,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .running)
        XCTAssertEqual(effects, [.playStartGong])
    }

    // MARK: - timerCompleted Tests

    func testTimerCompleted_playsCompletionAndStopsAudio() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .timerCompleted,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .completed)
        XCTAssertEqual(newState.progress, 1.0)
        XCTAssertEqual(effects, [.playCompletionSound, .stopBackgroundAudio])
    }

    // MARK: - intervalGongTriggered Tests

    func testIntervalGongTriggered_whenEnabled_playsGong() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.intervalGongPlayedForCurrentInterval = false
        let settings = MeditationSettings(intervalGongsEnabled: true)

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .intervalGongTriggered,
            settings: settings
        )

        // Then
        XCTAssertEqual(effects, [.playIntervalGong])
        XCTAssertTrue(newState.intervalGongPlayedForCurrentInterval)
    }

    func testIntervalGongTriggered_whenDisabled_producesNoEffect() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running
        let settings = MeditationSettings(intervalGongsEnabled: false)

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .intervalGongTriggered,
            settings: settings
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }

    func testIntervalGongTriggered_whenAlreadyPlayed_producesNoEffect() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.intervalGongPlayedForCurrentInterval = true
        let settings = MeditationSettings(intervalGongsEnabled: true)

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .intervalGongTriggered,
            settings: settings
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - intervalGongPlayed Tests

    func testIntervalGongPlayed_resetsFlag() {
        // Given
        var state = TimerDisplayState.initial
        state.intervalGongPlayedForCurrentInterval = true

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .intervalGongPlayed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertFalse(newState.intervalGongPlayedForCurrentInterval)
        XCTAssertTrue(effects.isEmpty)
    }
}
