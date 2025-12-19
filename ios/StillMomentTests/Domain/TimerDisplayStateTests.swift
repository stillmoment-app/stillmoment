//
//  TimerDisplayStateTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

final class TimerDisplayStateTests: XCTestCase {
    // MARK: - isCountdown Tests

    func testIsCountdown_whenCountdownState_returnsTrue() {
        var state = TimerDisplayState.initial
        state.timerState = .countdown

        XCTAssertTrue(state.isCountdown)
    }

    func testIsCountdown_whenRunningState_returnsFalse() {
        var state = TimerDisplayState.initial
        state.timerState = .running

        XCTAssertFalse(state.isCountdown)
    }

    // MARK: - canStart Tests

    func testCanStart_whenIdleWithMinutes_returnsTrue() {
        var state = TimerDisplayState.initial
        state.timerState = .idle
        state.selectedMinutes = 10

        XCTAssertTrue(state.canStart)
    }

    func testCanStart_whenIdleWithZeroMinutes_returnsFalse() {
        var state = TimerDisplayState.initial
        state.timerState = .idle
        state.selectedMinutes = 0

        XCTAssertFalse(state.canStart)
    }

    func testCanStart_whenRunning_returnsFalse() {
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.selectedMinutes = 10

        XCTAssertFalse(state.canStart)
    }

    // MARK: - canPause Tests

    func testCanPause_whenRunning_returnsTrue() {
        var state = TimerDisplayState.initial
        state.timerState = .running

        XCTAssertTrue(state.canPause)
    }

    func testCanPause_whenPaused_returnsFalse() {
        var state = TimerDisplayState.initial
        state.timerState = .paused

        XCTAssertFalse(state.canPause)
    }

    // MARK: - canResume Tests

    func testCanResume_whenPaused_returnsTrue() {
        var state = TimerDisplayState.initial
        state.timerState = .paused

        XCTAssertTrue(state.canResume)
    }

    func testCanResume_whenRunning_returnsFalse() {
        var state = TimerDisplayState.initial
        state.timerState = .running

        XCTAssertFalse(state.canResume)
    }

    // MARK: - canReset Tests

    func testCanReset_whenIdle_returnsFalse() {
        var state = TimerDisplayState.initial
        state.timerState = .idle

        XCTAssertFalse(state.canReset)
    }

    func testCanReset_whenRunning_returnsTrue() {
        var state = TimerDisplayState.initial
        state.timerState = .running

        XCTAssertTrue(state.canReset)
    }

    func testCanReset_whenCompleted_returnsTrue() {
        var state = TimerDisplayState.initial
        state.timerState = .completed

        XCTAssertTrue(state.canReset)
    }

    // MARK: - formattedTime Tests

    func testFormattedTime_whenCountdown_showsCountdownSeconds() {
        var state = TimerDisplayState.initial
        state.timerState = .countdown
        state.countdownSeconds = 12

        XCTAssertEqual(state.formattedTime, "12")
    }

    func testFormattedTime_whenRunning_showsMinutesAndSeconds() {
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.remainingSeconds = 125 // 2:05

        XCTAssertEqual(state.formattedTime, "02:05")
    }

    func testFormattedTime_withZeroSeconds_showsZeroPadded() {
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.remainingSeconds = 0

        XCTAssertEqual(state.formattedTime, "00:00")
    }

    func testFormattedTime_withFullHour_showsCorrectly() {
        var state = TimerDisplayState.initial
        state.timerState = .running
        state.remainingSeconds = 3600 // 60:00

        XCTAssertEqual(state.formattedTime, "60:00")
    }

    // MARK: - Static Factory Tests

    func testInitial_hasCorrectDefaults() {
        let state = TimerDisplayState.initial

        XCTAssertEqual(state.timerState, .idle)
        XCTAssertEqual(state.selectedMinutes, 10)
        XCTAssertEqual(state.remainingSeconds, 0)
        XCTAssertEqual(state.totalSeconds, 0)
        XCTAssertEqual(state.countdownSeconds, 0)
        XCTAssertEqual(state.progress, 0.0)
        XCTAssertEqual(state.currentAffirmationIndex, 0)
        XCTAssertFalse(state.intervalGongPlayedForCurrentInterval)
    }

    func testWithDuration_setsValidMinutes() {
        let state = TimerDisplayState.withDuration(minutes: 25)

        XCTAssertEqual(state.selectedMinutes, 25)
        XCTAssertEqual(state.timerState, .idle)
    }

    func testWithDuration_clampsInvalidMinutes() {
        let stateOver = TimerDisplayState.withDuration(minutes: 100)
        XCTAssertEqual(stateOver.selectedMinutes, 60)

        let stateUnder = TimerDisplayState.withDuration(minutes: -5)
        XCTAssertEqual(stateUnder.selectedMinutes, 1)
    }
}
