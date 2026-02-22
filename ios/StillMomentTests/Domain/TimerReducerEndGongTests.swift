//
//  TimerReducerEndGongTests.swift
//  Still Moment
//
//  Tests for the endGong phase in the TimerReducer.
//

import XCTest
@testable import StillMoment

final class TimerReducerEndGongTests: XCTestCase {
    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    // MARK: - timerCompleted action -> endGong state

    func testTimerCompleted_transitionsToEndGong_notCompleted() {
        // Given - Timer is running (tick just set state to endGong in MeditationTimer)
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.remainingSeconds = 0
        state.totalSeconds = 600
        state.progress = 1.0

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .timerCompleted,
            settings: self.defaultSettings
        )

        // Then - Transitions to endGong, plays completion sound
        XCTAssertEqual(newState.timerState, .endGong)
        XCTAssertEqual(newState.progress, 1.0)
        XCTAssertTrue(effects.contains(.playCompletionSound))
        // Should stop background audio in endGong phase
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        // Should NOT deactivate timer session yet (keep-alive stays active)
        XCTAssertFalse(effects.contains(.deactivateTimerSession))
    }

    func testTimerCompleted_duringIntroduction_transitionsToEndGong() {
        // Given - Timer expired during introduction
        var state = TimerDisplayState.initial
        state.timerState = .introduction
        state.remainingSeconds = 0
        state.totalSeconds = 180

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .timerCompleted,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .endGong)
        XCTAssertTrue(effects.contains(.stopIntroduction))
        XCTAssertTrue(effects.contains(.playCompletionSound))
        XCTAssertFalse(effects.contains(.deactivateTimerSession))
    }

    // MARK: - endGongFinished action -> completed state

    func testEndGongFinished_transitionsToCompleted() {
        // Given - Timer is in endGong state (gong was playing)
        var state = TimerDisplayState.initial
        state.timerState = .endGong
        state.remainingSeconds = 0
        state.totalSeconds = 600
        state.progress = 1.0

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .endGongFinished,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .completed)
        XCTAssertEqual(newState.progress, 1.0)
        // Now deactivate the timer session
        XCTAssertTrue(effects.contains(.deactivateTimerSession))
        // Should NOT play any more sounds
        XCTAssertFalse(effects.contains(.playCompletionSound))
    }

    func testEndGongFinished_inWrongPhase_isNoOp() {
        // Given - Timer is running (not in endGong)
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.remainingSeconds = 300

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .endGongFinished,
            settings: self.defaultSettings
        )

        // Then - No change
        XCTAssertEqual(newState.timerState, .running)
        XCTAssertTrue(effects.isEmpty)
    }

    func testEndGongFinished_inIdlePhase_isNoOp() {
        // Given
        let state = TimerDisplayState.initial

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .endGongFinished,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertTrue(effects.isEmpty)
    }

    func testEndGongFinished_inCompletedPhase_isNoOp() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .completed

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .endGongFinished,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .completed)
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - Reset from endGong

    func testResetPressed_fromEndGong_transitionsToIdle() {
        // Given - Timer in endGong (gong is playing)
        var state = TimerDisplayState.initial
        state.timerState = .endGong
        state.remainingSeconds = 0
        state.totalSeconds = 600
        state.progress = 1.0

        // When
        let (newState, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(newState.timerState, .idle)
        XCTAssertEqual(newState.remainingSeconds, 0)
        XCTAssertEqual(newState.progress, 0.0)
        XCTAssertTrue(effects.contains(.deactivateTimerSession))
        XCTAssertTrue(effects.contains(.resetTimer))
    }
}
