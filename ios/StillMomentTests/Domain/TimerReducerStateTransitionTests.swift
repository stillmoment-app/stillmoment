//
//  TimerReducerStateTransitionTests.swift
//  Still Moment
//
//  Tests for ResetPressed state transitions.
//

import XCTest
@testable import StillMoment

final class TimerReducerStateTransitionTests: XCTestCase {
    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
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

    func testResetPressed_transitionsTimerFromPreparationToIdle() {
        var state = TimerDisplayState.initial
        state.timerState = .preparation

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
