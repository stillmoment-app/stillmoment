//
//  TimerReducerStateTransitionTests.swift
//  Still Moment
//
//  Tests for ResetPressed effect mapping.
//

import XCTest
@testable import StillMoment

final class TimerReducerStateTransitionTests: XCTestCase {
    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    // MARK: - ResetPressed Effect Mapping

    func testResetPressed_fromRunning_producesStopAndResetEffects() {
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        XCTAssertEqual(effects, [.stopBackgroundAudio, .resetTimer, .clearTimer, .deactivateTimerSession])
    }

    func testResetPressed_fromCompleted_producesResetEffects() {
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .completed,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        XCTAssertFalse(effects.isEmpty)
        XCTAssertTrue(effects.contains(.resetTimer))
    }

    func testResetPressed_fromPreparation_producesResetEffects() {
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .preparation,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        XCTAssertFalse(effects.isEmpty)
        XCTAssertTrue(effects.contains(.resetTimer))
    }

    func testResetPressed_fromIdle_producesNoEffects() {
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .idle,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        XCTAssertTrue(effects.isEmpty)
    }

    func testResetPressed_fromStartGong_producesResetEffects() {
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        XCTAssertFalse(effects.isEmpty)
        XCTAssertTrue(effects.contains(.resetTimer))
    }
}
