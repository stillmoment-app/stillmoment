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

    func testMeditationCycle_preparation_to_startGong_to_running_to_completed() {
        var state = TimerDisplayState.initial
        state.timerState = .preparation

        // preparation → startGong (plays start gong)
        let (afterStartGong, preparationEffects) = TimerReducer.reduce(
            state: state,
            action: .preparationFinished,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterStartGong.timerState, .startGong)
        XCTAssertTrue(preparationEffects.contains(.playStartGong))

        // startGong → running (gong finished, no introduction configured)
        let (afterRunning, gongEffects) = TimerReducer.reduce(
            state: afterStartGong,
            action: .startGongFinished,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterRunning.timerState, .running)
        XCTAssertTrue(gongEffects.contains { effect in
            if case .startBackgroundAudio = effect {
                return true
            }
            return false
        })

        // running → completed
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

    // MARK: - Running to Idle (Close Button)

    func testRunningToIdle_viaReset() {
        var state = TimerDisplayState.initial
        state.timerState = .running

        let (afterReset, effects) = TimerReducer.reduce(
            state: state,
            action: .resetPressed,
            settings: self.defaultSettings
        )
        XCTAssertEqual(afterReset.timerState, .idle)
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        XCTAssertTrue(effects.contains(.resetTimer))
    }
}
