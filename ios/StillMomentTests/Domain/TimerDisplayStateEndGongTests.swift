//
//  TimerDisplayStateEndGongTests.swift
//  Still Moment
//
//  Tests for TimerDisplayState computed properties during endGong phase.
//

import XCTest
@testable import StillMoment

final class TimerDisplayStateEndGongTests: XCTestCase {
    func testIsRunning_includesEndGong() {
        // Given - Timer in endGong state (ring full, time at 00:00)
        var state = TimerDisplayState.initial
        state.timerState = .endGong

        // Then - Session is visually "running" (ring full, no completion screen yet)
        XCTAssertTrue(state.isRunning)
    }

    func testCanStart_falseInEndGong() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .endGong

        // Then
        XCTAssertFalse(state.canStart)
    }

    func testFormattedTime_inEndGong_showsZero() {
        // Given
        var state = TimerDisplayState.initial
        state.timerState = .endGong
        state.remainingSeconds = 0

        // Then - Should show 00:00
        XCTAssertEqual(state.formattedTime, "00:00")
    }
}
