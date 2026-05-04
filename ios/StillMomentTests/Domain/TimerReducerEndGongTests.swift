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

    // MARK: - timerCompleted action

    func testTimerCompleted_playsCompletionSoundAndStopsBackgroundAudio() {
        // Given - Timer is running
        // When
        let effects = TimerReducer.reduce(
            action: .timerCompleted,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertTrue(effects.contains(.playCompletionSound))
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        // Should NOT deactivate timer session yet (keep-alive stays active)
        XCTAssertFalse(effects.contains(.deactivateTimerSession))
    }

    // MARK: - endGongFinished action

    func testEndGongFinished_transitionsToCompletedAndDeactivates() {
        // When
        let effects = TimerReducer.reduce(
            action: .endGongFinished,
            timerState: .endGong,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(effects, [.transitionToCompleted, .deactivateTimerSession])
    }

    func testEndGongFinished_inWrongPhase_isNoOp() {
        // Given - Timer is running (not in endGong)
        let effects = TimerReducer.reduce(
            action: .endGongFinished,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        // Then - No effects
        XCTAssertTrue(effects.isEmpty)
    }

    func testEndGongFinished_inIdlePhase_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .endGongFinished,
            timerState: .idle,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        XCTAssertTrue(effects.isEmpty)
    }

    func testEndGongFinished_inCompletedPhase_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .endGongFinished,
            timerState: .completed,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - Reset from endGong

    func testResetPressed_fromEndGong_producesResetAndDeactivateEffects() {
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .endGong,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        XCTAssertTrue(effects.contains(.resetTimer))
        XCTAssertTrue(effects.contains(.clearTimer))
        XCTAssertTrue(effects.contains(.deactivateTimerSession))
    }
}
