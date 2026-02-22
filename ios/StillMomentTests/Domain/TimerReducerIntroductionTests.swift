//
//  TimerReducerIntroductionTests.swift
//  Still Moment
//
//  Tests for TimerReducer introduction-related state transitions and effects.
//

import XCTest
@testable import StillMoment

final class TimerReducerIntroductionTests: XCTestCase {
    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // Force German locale so "breath" introduction is always available
        Introduction.languageOverride = "de"
    }

    override func tearDown() {
        Introduction.languageOverride = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    /// Settings with introduction configured
    private var settingsWithIntroduction: MeditationSettings {
        MeditationSettings(introductionId: "breath")
    }

    // MARK: - StartPressed with Introduction

    func testStartPressed_withoutIntroduction_doesNotIncludeBackgroundAudio() {
        // Given - No introduction configured (default)
        var state = TimerDisplayState.initial
        state.selectedMinutes = 10

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: self.defaultSettings
        )

        // Then - Background audio is NOT started here; it starts in startGongFinished
        let hasBackgroundAudio = effects.contains { effect in
            if case .startBackgroundAudio = effect {
                return true
            }
            return false
        }
        XCTAssertFalse(hasBackgroundAudio, "Background audio should start in startGongFinished, not startPressed")
    }

    func testStartPressed_withIntroduction_delaysBackgroundAudio() {
        // Given - Introduction configured
        var state = TimerDisplayState.initial
        state.selectedMinutes = 10
        let settings = self.settingsWithIntroduction

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: settings
        )

        // Then - No background audio yet (delayed until introduction finishes)
        let hasBackgroundAudio = effects.contains { effect in
            if case .startBackgroundAudio = effect {
                return true
            }
            return false
        }
        XCTAssertFalse(hasBackgroundAudio, "Background audio should be delayed when introduction is active")
    }

    // MARK: - PreparationFinished with Introduction

    func testPreparationFinished_withIntroduction_transitionsToStartGong() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .preparation
        let settings = self.settingsWithIntroduction

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .preparationFinished,
            settings: settings
        )

        // Then - Transition to startGong, play start gong only.
        // Background audio decision deferred to startGongFinished.
        XCTAssertEqual(newState.timerState, .startGong)
        XCTAssertEqual(effects, [.playStartGong])
    }

    func testPreparationFinished_withoutIntroduction_transitionsToStartGong() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .preparation

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .preparationFinished,
            settings: self.defaultSettings
        )

        // Then - Same: transition to startGong with gong effect only
        XCTAssertEqual(newState.timerState, .startGong)
        XCTAssertEqual(effects, [.playStartGong])
    }

    // MARK: - StartGongFinished

    func testStartGongFinished_withIntroduction_transitionsToIntroduction() {
        // Given - In startGong state, introduction configured
        var state = TimerDisplayState.initial
        state.timerState = .startGong
        let settings = self.settingsWithIntroduction

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .startGongFinished,
            settings: settings
        )

        // Then - Transition to introduction and play audio
        XCTAssertEqual(newState.timerState, .introduction)
        XCTAssertEqual(effects, [.playIntroduction(introductionId: "breath")])
    }

    func testStartGongFinished_withoutIntroduction_transitionsToRunning() {
        // Given - In startGong state, no introduction configured
        var state = TimerDisplayState.initial
        state.timerState = .startGong

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .startGongFinished,
            settings: self.defaultSettings
        )

        // Then - Transition to running with background audio
        XCTAssertEqual(newState.timerState, .running)
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: self.defaultSettings.backgroundSoundId,
            volume: self.defaultSettings.backgroundSoundVolume
        )))
    }

    func testStartGongFinished_duringCompleted_isNoOp() {
        // Given - Timer already completed
        var state = TimerDisplayState.initial
        state.timerState = .completed

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .startGongFinished,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }

    func testStartGongFinished_duringIntroduction_isNoOp() {
        // Given - Already in introduction state (shouldn't happen, but defensive)
        var state = TimerDisplayState.initial
        state.timerState = .introduction

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .startGongFinished,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }

    func testStartGongFinished_duringRunning_isNoOp() {
        // Given - Already in running state
        var state = TimerDisplayState.initial
        state.timerState = .running

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .startGongFinished,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - IntroductionFinished

    func testIntroductionFinished_transitionsToRunning() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .introduction
        let settings = self.settingsWithIntroduction

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .introductionFinished,
            settings: settings
        )

        // Then
        XCTAssertEqual(newState.timerState, .running)
        XCTAssertTrue(effects.contains(.stopIntroduction))
        XCTAssertTrue(effects.contains(.endIntroductionPhase))
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: settings.backgroundSoundId,
            volume: settings.backgroundSoundVolume
        )))
    }

    func testIntroductionFinished_startsBackgroundAudio() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .introduction
        let settings = MeditationSettings(
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3,
            introductionId: "breath"
        )

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .introductionFinished,
            settings: settings
        )

        // Then - Background audio starts with correct settings
        XCTAssertTrue(effects.contains(.startBackgroundAudio(soundId: "forest", volume: 0.3)))
    }

    func testIntroductionFinished_fromNonIntroductionState_isNoOp() {
        // Given - Not in introduction state
        var state = TimerDisplayState.initial
        state.timerState = .running

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .introductionFinished,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertEqual(newState.timerState, .running)
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - TimerCompleted with Introduction

    func testTimerCompleted_fromIntroduction_stopsIntroduction() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .introduction
        let settings = self.settingsWithIntroduction

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .timerCompleted,
            settings: settings
        )

        // Then - Transitions to endGong (not completed), keeps session active
        XCTAssertEqual(newState.timerState, .endGong)
        XCTAssertEqual(newState.progress, 1.0)
        XCTAssertTrue(effects.contains(.playCompletionSound))
        XCTAssertTrue(effects.contains(.stopIntroduction))
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        XCTAssertFalse(effects.contains(.deactivateTimerSession))
    }

    func testTimerCompleted_fromRunning_doesNotStopIntroduction() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .running

        // When
        let (_, effects) = TimerReducer.reduce(
            state: state,
            action: .timerCompleted,
            settings: self.defaultSettings
        )

        // Then - No stopIntroduction effect, no deactivation (endGong phase keeps session active)
        XCTAssertFalse(effects.contains(.stopIntroduction))
        XCTAssertEqual(effects, [.playCompletionSound, .stopBackgroundAudio])
    }

    // MARK: - ResetPressed with Introduction

    func testResetPressed_fromIntroduction_stopsIntroduction() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .introduction
        let settings = self.settingsWithIntroduction

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: settings
        )

        // Then
        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertTrue(effects.contains(.stopIntroduction))
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        XCTAssertTrue(effects.contains(.resetTimer))
    }

    func testResetPressed_fromStartGong_doesNotStopIntroduction() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .startGong

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertFalse(effects.contains(.stopIntroduction))
        XCTAssertEqual(effects, [.stopBackgroundAudio, .resetTimer, .deactivateTimerSession])
    }

    func testResetPressed_fromIntroduction_resetsAllState() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .introduction
        state.remainingSeconds = 500
        state.totalSeconds = 600
        state.progress = 0.17

        // When
        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertEqual(newState.remainingSeconds, 0)
        XCTAssertEqual(newState.totalSeconds, 0)
        XCTAssertEqual(newState.progress, 0.0)
    }
}
