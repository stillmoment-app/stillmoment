//
//  PreparationCountdownTests.swift
//  Still Moment
//
//  Unit tests for PreparationCountdown Value Object
//

import XCTest
@testable import StillMoment

final class PreparationCountdownTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInit_setsPropertiesCorrectly() {
        // When
        let countdown = PreparationCountdown(totalSeconds: 15)

        // Then
        XCTAssertEqual(countdown.totalSeconds, 15)
        XCTAssertEqual(countdown.remainingSeconds, 15)
    }

    func testInit_withCustomRemaining_setsPropertiesCorrectly() {
        // When
        let countdown = PreparationCountdown(totalSeconds: 15, remainingSeconds: 10)

        // Then
        XCTAssertEqual(countdown.totalSeconds, 15)
        XCTAssertEqual(countdown.remainingSeconds, 10)
    }

    // MARK: - Tick Tests

    func testTick_decrementsRemainingSeconds() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10)

        // When
        let ticked = countdown.tick()

        // Then
        XCTAssertEqual(ticked.remainingSeconds, 9)
        XCTAssertEqual(ticked.totalSeconds, 10) // Unchanged
    }

    func testTick_atOne_goesToZero() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10, remainingSeconds: 1)

        // When
        let ticked = countdown.tick()

        // Then
        XCTAssertEqual(ticked.remainingSeconds, 0)
    }

    func testTick_atZero_staysAtZero() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10, remainingSeconds: 0)

        // When
        let ticked = countdown.tick()

        // Then
        XCTAssertEqual(ticked.remainingSeconds, 0)
    }

    func testTick_returnsNewInstance() {
        // Given
        let original = PreparationCountdown(totalSeconds: 10)

        // When
        let ticked = original.tick()

        // Then - Original unchanged (immutability)
        XCTAssertEqual(original.remainingSeconds, 10)
        XCTAssertEqual(ticked.remainingSeconds, 9)
    }

    // MARK: - isFinished Tests

    func testIsFinished_whenRemainingGreaterThanZero_returnsFalse() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10, remainingSeconds: 5)

        // Then
        XCTAssertFalse(countdown.isFinished)
    }

    func testIsFinished_whenRemainingIsOne_returnsFalse() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10, remainingSeconds: 1)

        // Then
        XCTAssertFalse(countdown.isFinished)
    }

    func testIsFinished_whenRemainingIsZero_returnsTrue() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10, remainingSeconds: 0)

        // Then
        XCTAssertTrue(countdown.isFinished)
    }

    // MARK: - Progress Tests

    func testProgress_atStart_isZero() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10)

        // Then
        XCTAssertEqual(countdown.progress, 0, accuracy: 0.01)
    }

    func testProgress_atHalfway_isFiftyPercent() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10, remainingSeconds: 5)

        // Then
        XCTAssertEqual(countdown.progress, 0.5, accuracy: 0.01)
    }

    func testProgress_atEnd_isOne() {
        // Given
        let countdown = PreparationCountdown(totalSeconds: 10, remainingSeconds: 0)

        // Then
        XCTAssertEqual(countdown.progress, 1.0, accuracy: 0.01)
    }

    func testProgress_withZeroTotal_returnsZero() {
        // Given - Edge case: should not happen but handle gracefully
        let countdown = PreparationCountdown(totalSeconds: 0, remainingSeconds: 0)

        // Then
        XCTAssertEqual(countdown.progress, 0)
    }

    // MARK: - Equatable Tests

    func testEquatable_sameValues_areEqual() {
        // Given
        let countdown1 = PreparationCountdown(totalSeconds: 15, remainingSeconds: 10)
        let countdown2 = PreparationCountdown(totalSeconds: 15, remainingSeconds: 10)

        // Then
        XCTAssertEqual(countdown1, countdown2)
    }

    func testEquatable_differentRemaining_areNotEqual() {
        // Given
        let countdown1 = PreparationCountdown(totalSeconds: 15, remainingSeconds: 10)
        let countdown2 = PreparationCountdown(totalSeconds: 15, remainingSeconds: 5)

        // Then
        XCTAssertNotEqual(countdown1, countdown2)
    }

    func testEquatable_differentTotal_areNotEqual() {
        // Given
        let countdown1 = PreparationCountdown(totalSeconds: 15, remainingSeconds: 10)
        let countdown2 = PreparationCountdown(totalSeconds: 20, remainingSeconds: 10)

        // Then
        XCTAssertNotEqual(countdown1, countdown2)
    }

    // MARK: - Full Countdown Cycle Test

    func testFullCountdownCycle() {
        // Given
        var countdown = PreparationCountdown(totalSeconds: 3)

        // Then - Initial state
        XCTAssertEqual(countdown.remainingSeconds, 3)
        XCTAssertFalse(countdown.isFinished)
        XCTAssertEqual(countdown.progress, 0, accuracy: 0.01)

        // Tick 1
        countdown = countdown.tick()
        XCTAssertEqual(countdown.remainingSeconds, 2)
        XCTAssertFalse(countdown.isFinished)
        XCTAssertEqual(countdown.progress, 1.0 / 3.0, accuracy: 0.01)

        // Tick 2
        countdown = countdown.tick()
        XCTAssertEqual(countdown.remainingSeconds, 1)
        XCTAssertFalse(countdown.isFinished)
        XCTAssertEqual(countdown.progress, 2.0 / 3.0, accuracy: 0.01)

        // Tick 3 - Finished
        countdown = countdown.tick()
        XCTAssertEqual(countdown.remainingSeconds, 0)
        XCTAssertTrue(countdown.isFinished)
        XCTAssertEqual(countdown.progress, 1.0, accuracy: 0.01)
    }
}
