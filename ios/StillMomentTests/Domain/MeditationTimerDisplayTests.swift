//
//  MeditationTimerDisplayTests.swift
//  Still Moment
//
//  Tests for MeditationTimer display extensions.
//

import XCTest
@testable import StillMoment

final class MeditationTimerDisplayTests: XCTestCase {
    // MARK: - isPreparation Tests

    func testIsPreparation_whenPreparationState_returnsTrue() {
        let timer = MeditationTimer.stub(state: .preparation, remainingPreparationSeconds: 10)

        XCTAssertTrue(timer.isPreparation)
    }

    func testIsPreparation_whenRunningState_returnsFalse() {
        let timer = MeditationTimer.stub(state: .running)

        XCTAssertFalse(timer.isPreparation)
    }

    func testIsPreparation_whenIdleState_returnsFalse() {
        let timer = MeditationTimer.stub(state: .idle)

        XCTAssertFalse(timer.isPreparation)
    }

    // MARK: - isRunning Tests

    func testIsRunning_whenRunning_returnsTrue() {
        let timer = MeditationTimer.stub(state: .running)

        XCTAssertTrue(timer.isRunning)
    }

    func testIsRunning_whenStartGong_returnsTrue() {
        let timer = MeditationTimer.stub(state: .startGong)

        XCTAssertTrue(timer.isRunning)
    }

    func testIsRunning_whenAttunement_returnsTrue() {
        let timer = MeditationTimer.stub(state: .attunement)

        XCTAssertTrue(timer.isRunning)
    }

    func testIsRunning_whenEndGong_returnsTrue() {
        let timer = MeditationTimer.stub(state: .endGong)

        XCTAssertTrue(timer.isRunning)
    }

    func testIsRunning_whenIdle_returnsFalse() {
        let timer = MeditationTimer.stub(state: .idle)

        XCTAssertFalse(timer.isRunning)
    }

    func testIsRunning_whenPreparation_returnsFalse() {
        let timer = MeditationTimer.stub(state: .preparation)

        XCTAssertFalse(timer.isRunning)
    }

    func testIsRunning_whenCompleted_returnsFalse() {
        let timer = MeditationTimer.stub(state: .completed)

        XCTAssertFalse(timer.isRunning)
    }

    // MARK: - formattedTime Tests

    func testFormattedTime_whenPreparation_showsPreparationSeconds() {
        let timer = MeditationTimer.stub(
            state: .preparation,
            remainingPreparationSeconds: 12
        )

        XCTAssertEqual(timer.formattedTime, "12")
    }

    func testFormattedTime_whenRunning_showsMinutesAndSeconds() {
        let timer = MeditationTimer.stub(remainingSeconds: 125, state: .running)

        XCTAssertEqual(timer.formattedTime, "02:05")
    }

    func testFormattedTime_withZeroSeconds_showsZeroPadded() {
        let timer = MeditationTimer.stub(remainingSeconds: 0, state: .running)

        XCTAssertEqual(timer.formattedTime, "00:00")
    }

    func testFormattedTime_withFullHour_showsCorrectly() {
        let timer = MeditationTimer.stub(
            durationMinutes: 60,
            remainingSeconds: 3600,
            state: .running
        )

        XCTAssertEqual(timer.formattedTime, "60:00")
    }

    func testFormattedTime_whenEndGong_showsZero() {
        let timer = MeditationTimer.stub(remainingSeconds: 0, state: .endGong)

        XCTAssertEqual(timer.formattedTime, "00:00")
    }

    func testFormattedTime_preparationWithOneSecond_showsOne() {
        let timer = MeditationTimer.stub(
            state: .preparation,
            remainingPreparationSeconds: 1
        )

        XCTAssertEqual(timer.formattedTime, "1")
    }
}
