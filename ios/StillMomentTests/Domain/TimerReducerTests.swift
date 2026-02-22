//
//  TimerReducerTests.swift
//  Still Moment
//
//  Behavior-driven tests for TimerReducer state transitions.
//  Tests verify the reducer as a pure function: same inputs always produce same outputs.
//

import XCTest
@testable import StillMoment

final class TimerReducerTests: XCTestCase {
    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    // MARK: - SelectDuration Tests

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

    func testSelectDuration_clampsToMinimum() {
        // Given
        let state = TimerDisplayState.initial

        // When
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .selectDuration(minutes: 0),
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.selectedMinutes, 1)
    }

    func testSelectDuration_clampsToMaximum() {
        // Given
        let state = TimerDisplayState.initial

        // When
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .selectDuration(minutes: 100),
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.selectedMinutes, 60)
    }

    func testSelectDuration_withIntroduction_clampsToMinimum() {
        // Given - Settings with breath introduction (minimum 3 minutes)
        let state = TimerDisplayState.initial
        let settings = MeditationSettings(introductionId: "breath")

        // When - Trying to select 1 minute (below minimum)
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .selectDuration(minutes: 1),
            settings: settings
        )

        // Then - Clamped to minimum (3 minutes for breath intro)
        XCTAssertEqual(newState.selectedMinutes, MeditationSettings.minimumDuration(for: "breath"))
    }

    func testSelectDuration_withIntroduction_preservesValidDuration() {
        // Given - Settings with breath introduction
        let state = TimerDisplayState.initial
        let settings = MeditationSettings(introductionId: "breath")

        // When - Selecting duration above minimum
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .selectDuration(minutes: 10),
            settings: settings
        )

        // Then - Duration preserved
        XCTAssertEqual(newState.selectedMinutes, 10)
    }

    // MARK: - StartPressed State Transitions

    func testStartPressed_transitionsTimerFromIdleToPreparation() {
        // Given
        var state = TimerDisplayState.initial
        state.selectedMinutes = 10

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: self.defaultSettings
        )

        // Then - Timer transitions to preparation, not directly to running
        // Note: iOS architecture delegates preparation state to TimerService via effects
        // The state transition happens via tick updates from the service
        XCTAssertFalse(effects.isEmpty, "StartPressed should produce effects")
        XCTAssertTrue(effects.contains(.startTimer(durationMinutes: 10)))
    }

    func testStartPressed_producesCorrectEffects() {
        // Given
        var state = TimerDisplayState.initial
        state.selectedMinutes = 10
        let settings = MeditationSettings(
            intervalGongsEnabled: false,
            intervalMinutes: 5,
            backgroundSoundId: "forest",
            durationMinutes: 5
        )

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: settings
        )

        // Then - Background audio is NOT started here; it starts in preparationFinished
        var expectedSettings = settings
        expectedSettings.durationMinutes = 10

        XCTAssertEqual(effects.count, 3)
        XCTAssertEqual(effects[0], .activateTimerSession)
        XCTAssertEqual(effects[1], .startTimer(durationMinutes: 10))
        XCTAssertEqual(effects[2], .saveSettings(expectedSettings))
    }

    func testStartPressed_rotatesAffirmationIndex() {
        // Given
        var state = TimerDisplayState.initial
        state.currentAffirmationIndex = 4

        // When
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: self.defaultSettings
        )

        // Then - wraps around: 4 + 1 = 5, 5 % 5 = 0
        XCTAssertEqual(newState.currentAffirmationIndex, 0)
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

    func testStartPressed_withZeroMinutes_doesNotTransition() {
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

    // MARK: - Tick Tests

    func testTick_updatesStateFromTimerService() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .tick(
                remainingSeconds: 540,
                totalSeconds: 600,
                remainingPreparationSeconds: 0,
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
        XCTAssertTrue(effects.isEmpty, "Tick should not produce effects")
    }

    func testTick_canTransitionState() {
        // Given - preparation state
        var state = TimerDisplayState.initial
        state.timerState = .preparation

        // When - tick with running state (from TimerService after preparation)
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .tick(
                remainingSeconds: 600,
                totalSeconds: 600,
                remainingPreparationSeconds: 10,
                progress: 0.0,
                state: .running
            ),
            settings: self.defaultSettings
        )

        // Then - state is updated from tick
        XCTAssertEqual(newState.timerState, .running)
    }

    // MARK: - PreparationFinished State Transitions

    func testPreparationFinished_transitionsTimerFromPreparationToStartGong() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .preparation

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .preparationFinished,
            settings: self.defaultSettings
        )

        // Then - Transitions to startGong with gong effect only.
        // Background audio starts later when gong finishes (startGongFinished).
        XCTAssertEqual(newState.timerState, .startGong)
        XCTAssertEqual(effects, [.playStartGong])
    }

    func testStartGongFinished_fromStartGong_withoutIntro_transitionsToRunningWithBackgroundAudio() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .startGong

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .startGongFinished,
            settings: self.defaultSettings
        )

        // Then - Transitions to running with background audio
        XCTAssertEqual(newState.timerState, .running)
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: self.defaultSettings.backgroundSoundId,
            volume: self.defaultSettings.backgroundSoundVolume
        )))
    }

    // MARK: - TimerCompleted State Transitions

    func testTimerCompleted_transitionsTimerFromRunningToCompleted() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.progress = 0.99

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .timerCompleted,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .completed)
        XCTAssertEqual(newState.progress, 1.0)
        XCTAssertEqual(effects, [.playCompletionSound, .stopBackgroundAudio, .deactivateTimerSession])
    }

    // MARK: - IntervalGong Tests

    func testIntervalGongTriggered_whenEnabled_playsGongWithVolume() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.intervalGongPlayedForCurrentInterval = false
        let settings = MeditationSettings(intervalGongsEnabled: true, intervalGongVolume: 0.6)

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .intervalGongTriggered,
            settings: settings
        )

        // Then
        XCTAssertEqual(effects, [.playIntervalGong(soundId: GongSound.defaultIntervalSoundId, volume: 0.6)])
        XCTAssertTrue(newState.intervalGongPlayedForCurrentInterval)
    }

    func testIntervalGongTriggered_whenDisabled_doesNotPlayGong() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running
        let settings = MeditationSettings(intervalGongsEnabled: false)

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .intervalGongTriggered,
            settings: settings
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
        XCTAssertEqual(newState, state)
    }

    func testIntervalGongTriggered_whenAlreadyPlayed_doesNotPlayAgain() {
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
