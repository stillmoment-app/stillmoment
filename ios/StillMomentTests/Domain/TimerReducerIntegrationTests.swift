//
//  TimerReducerIntegrationTests.swift
//  Still Moment
//
//  Integration tests verifying complete meditation effect chains through the TimerReducer.
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

    func testMeditationCycle_start_triggersTimerAndSessionEffects() {
        let effects = TimerReducer.reduce(
            action: .startPressed,
            timerState: .idle,
            selectedMinutes: 1,
            settings: self.defaultSettings
        )

        XCTAssertFalse(effects.isEmpty)
        XCTAssertTrue(self.hasStartTimerEffect(effects))
        XCTAssertTrue(effects.contains(.activateTimerSession))
    }

    func testMeditationCycle_preparation_to_startGong_to_running_to_completed() {
        // preparation → startGong (plays start gong)
        let preparationEffects = TimerReducer.reduce(
            action: .preparationFinished,
            timerState: .preparation,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )
        XCTAssertTrue(preparationEffects.contains(.playStartGong))

        // startGong → running (gong finished)
        let gongEffects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )
        XCTAssertTrue(gongEffects.contains { effect in
            if case .startBackgroundAudio = effect {
                return true
            }
            return false
        })

        // running → endGong (completion gong plays)
        let endGongEffects = TimerReducer.reduce(
            action: .timerCompleted,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )
        XCTAssertTrue(endGongEffects.contains(.playCompletionSound))

        // endGong → completed (gong finished)
        let completedEffects = TimerReducer.reduce(
            action: .endGongFinished,
            timerState: .endGong,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )
        XCTAssertTrue(completedEffects.contains(.transitionToCompleted))
        XCTAssertTrue(completedEffects.contains(.deactivateTimerSession))
    }

    func testMeditationCycle_completed_to_idle() {
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .completed,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )
        XCTAssertTrue(effects.contains(.resetTimer))
    }

    // MARK: - Running to Idle (Close Button)

    func testRunningToIdle_viaReset() {
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        XCTAssertTrue(effects.contains(.resetTimer))
    }
}
