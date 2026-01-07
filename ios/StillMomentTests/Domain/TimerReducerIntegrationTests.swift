//
//  TimerReducerIntegrationTests.swift
//  Still Moment
//
//  Integration tests verifying complete meditation cycles through the TimerReducer.
//

import XCTest
@testable import StillMoment

final class TimerReducerIntegrationTests: XCTestCase {
    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    private func hasStartTimerEffect(_ effects: [TimerEffect]) -> Bool {
        effects.contains {
            if case .startTimer = $0 {
                return true
            }
            return false
        }
    }

    // MARK: - Full Cycle Tests

    func testMeditationCycle_start_triggers_preparation() {
        var state = TimerDisplayState.initial
        state.selectedMinutes = 1

        let (afterStart, startEffects) = TimerReducer.reduce(
            state: state,
            action: .startPressed,
            settings: self.defaultSettings
        )

        XCTAssertFalse(startEffects.isEmpty)
        XCTAssertTrue(self.hasStartTimerEffect(startEffects))

        let (afterCountdown, _) = TimerReducer.reduce(
            state: afterStart,
            action: .tick(
                remainingSeconds: 60,
                totalSeconds: 60,
                remainingPreparationSeconds: 10,
                progress: 0.0,
                state: .preparation
            ),
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterCountdown.timerState, .preparation)
    }

    func testMeditationCycle_preparation_to_running_to_completed() {
        var state = TimerDisplayState.initial
        state.timerState = .preparation

        let (afterRunning, preparationEffects) = TimerReducer.reduce(
            state: state,
            action: .preparationFinished,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterRunning.timerState, .running)
        XCTAssertTrue(preparationEffects.contains(.playStartGong))

        let (afterCompleted, completedEffects) = TimerReducer.reduce(
            state: afterRunning,
            action: .timerCompleted,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterCompleted.timerState, .completed)
        XCTAssertTrue(completedEffects.contains(.playCompletionSound))
    }

    func testMeditationCycle_completed_to_idle() {
        var state = TimerDisplayState.initial
        state.timerState = .completed

        let (afterReset, resetEffects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterReset.timerState, .idle)
        XCTAssertTrue(resetEffects.contains(.resetTimer))
    }

    // MARK: - Pause/Resume Cycle Tests

    func testPauseResumeCycle_running_to_paused_to_running() {
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.remainingSeconds = 300
        state.totalSeconds = 600

        let (afterPause, pauseEffects) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterPause.timerState, .paused)
        XCTAssertTrue(pauseEffects.contains(.pauseBackgroundAudio))
        XCTAssertTrue(pauseEffects.contains(.pauseTimer))

        let (afterResume, resumeEffects) = TimerReducer.reduce(
            state: afterPause,
            action: .resumePressed,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterResume.timerState, .running)
        XCTAssertTrue(resumeEffects.contains(.resumeBackgroundAudio))
        XCTAssertTrue(resumeEffects.contains(.resumeTimer))
    }

    func testPauseResetCycle_running_to_paused_to_idle() {
        var state = TimerDisplayState.initial
        state.timerState = .running

        let (afterPause, _) = TimerReducer.reduce(
            state: state,
            action: .pausePressed,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterPause.timerState, .paused)

        let (afterReset, _) = TimerReducer.reduce(
            state: afterPause,
            action: .resetPressed,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterReset.timerState, .idle)
    }
}
