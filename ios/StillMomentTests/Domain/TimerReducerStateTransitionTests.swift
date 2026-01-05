//
//  TimerReducerStateTransitionTests.swift
//  Still Moment
//
//  Tests for PausePressed, ResumePressed, and ResetPressed state transitions.
//

import XCTest
@testable import StillMoment

final class TimerReducerStateTransitionTests: XCTestCase {
    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    // MARK: - PausePressed State Transitions

    func testPausePressed_transitionsTimerFromRunningToPaused() {
        var state = TimerDisplayState.initial
        state.timerState = .running

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .paused)
        XCTAssertEqual(effects, [.pauseBackgroundAudio, .pauseTimer])
    }

    func testPausePressed_fromIdle_doesNotTransition() {
        var state = TimerDisplayState.initial
        state.timerState = .idle

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertTrue(effects.isEmpty)
    }

    func testPausePressed_fromCountdown_doesNotTransition() {
        var state = TimerDisplayState.initial
        state.timerState = .countdown

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .countdown)
        XCTAssertTrue(effects.isEmpty)
    }

    func testPausePressed_fromPaused_doesNotTransition() {
        var state = TimerDisplayState.initial
        state.timerState = .paused

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .paused)
        XCTAssertTrue(effects.isEmpty)
    }

    func testPausePressed_fromCompleted_doesNotTransition() {
        var state = TimerDisplayState.initial
        state.timerState = .completed

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .completed)
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - ResumePressed State Transitions

    func testResumePressed_transitionsTimerFromPausedToRunning() {
        var state = TimerDisplayState.initial
        state.timerState = .paused

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resumePressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .running)
        XCTAssertEqual(effects, [.resumeBackgroundAudio, .resumeTimer])
    }

    func testResumePressed_fromRunning_doesNotTransition() {
        var state = TimerDisplayState.initial
        state.timerState = .running

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resumePressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .running)
        XCTAssertTrue(effects.isEmpty)
    }

    func testResumePressed_fromIdle_doesNotTransition() {
        var state = TimerDisplayState.initial
        state.timerState = .idle

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resumePressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - ResetPressed State Transitions

    func testResetPressed_transitionsTimerFromRunningToIdle() {
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.remainingSeconds = 300
        state.totalSeconds = 600
        state.progress = 0.5

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertEqual(newState.remainingSeconds, 0)
        XCTAssertEqual(newState.totalSeconds, 0)
        XCTAssertEqual(newState.progress, 0.0)
        XCTAssertEqual(effects, [.stopBackgroundAudio, .resetTimer])
    }

    func testResetPressed_transitionsTimerFromPausedToIdle() {
        var state = TimerDisplayState.initial
        state.timerState = .paused

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertFalse(effects.isEmpty)
    }

    func testResetPressed_transitionsTimerFromCompletedToIdle() {
        var state = TimerDisplayState.initial
        state.timerState = .completed

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertFalse(effects.isEmpty)
    }

    func testResetPressed_transitionsTimerFromCountdownToIdle() {
        var state = TimerDisplayState.initial
        state.timerState = .countdown

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertFalse(effects.isEmpty)
    }

    func testResetPressed_fromIdle_doesNotTransition() {
        let state = TimerDisplayState.initial

        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertTrue(effects.isEmpty)
    }

    func testResetPressed_resetsIntervalGongFlag() {
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.intervalGongPlayedForCurrentInterval = true

        let (newState, _) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        XCTAssertFalse(newState.intervalGongPlayedForCurrentInterval)
    }
}
