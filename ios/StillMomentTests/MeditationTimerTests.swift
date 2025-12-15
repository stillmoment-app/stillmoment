//
//  MeditationTimerTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

final class MeditationTimerTests: XCTestCase {
    func testInitialization() throws {
        // Given
        let duration = 10

        // When
        let timer = try MeditationTimer(durationMinutes: duration)

        // Then
        XCTAssertEqual(timer.durationMinutes, 10)
        XCTAssertEqual(timer.totalSeconds, 600)
        XCTAssertEqual(timer.remainingSeconds, 600)
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.progress, 0.0)
        XCTAssertFalse(timer.isCompleted)
    }

    func testInitializationWithInvalidDuration() {
        // Given - Test zero minutes
        XCTAssertThrowsError(try MeditationTimer(durationMinutes: 0)) { error in
            guard case let MeditationTimerError.invalidDuration(minutes) = error else {
                XCTFail("Expected MeditationTimerError.invalidDuration")
                return
            }
            XCTAssertEqual(minutes, 0)
        }

        // Given - Test negative minutes
        XCTAssertThrowsError(try MeditationTimer(durationMinutes: -5)) { error in
            guard case MeditationTimerError.invalidDuration = error else {
                XCTFail("Expected MeditationTimerError.invalidDuration")
                return
            }
        }

        // Given - Test over 60 minutes
        XCTAssertThrowsError(try MeditationTimer(durationMinutes: 61)) { error in
            guard case let MeditationTimerError.invalidDuration(minutes) = error else {
                XCTFail("Expected MeditationTimerError.invalidDuration")
                return
            }
            XCTAssertEqual(minutes, 61)
        }
    }

    func testInitializationEdgeCases() throws {
        // Test minimum valid duration
        let minTimer = try MeditationTimer(durationMinutes: 1)
        XCTAssertEqual(minTimer.durationMinutes, 1)

        // Test maximum valid duration
        let maxTimer = try MeditationTimer(durationMinutes: 60)
        XCTAssertEqual(maxTimer.durationMinutes, 60)
    }

    func testTick() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.running)

        // When
        let tickedTimer = timer.tick()

        // Then
        XCTAssertEqual(tickedTimer.remainingSeconds, 59)
        XCTAssertEqual(tickedTimer.state, .running)
    }

    func testTickToCompletion() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.running)

        // When - Tick down to 1 second
        for _ in 0..<59 {
            timer = timer.tick()
        }

        // Then - Should still be running
        XCTAssertEqual(timer.remainingSeconds, 1)
        XCTAssertEqual(timer.state, .running)

        // When - Final tick
        timer = timer.tick()

        // Then - Should be completed
        XCTAssertEqual(timer.remainingSeconds, 0)
        XCTAssertEqual(timer.state, .completed)
        XCTAssertTrue(timer.isCompleted)
    }

    func testProgress() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 10) // 600 seconds
        timer = timer.withState(.running)

        // When - No time elapsed
        XCTAssertEqual(timer.progress, 0.0, accuracy: 0.001)

        // When - Half time elapsed
        for _ in 0..<300 {
            timer = timer.tick()
        }
        XCTAssertEqual(timer.progress, 0.5, accuracy: 0.001)

        // When - Complete
        for _ in 0..<300 {
            timer = timer.tick()
        }
        XCTAssertEqual(timer.progress, 1.0, accuracy: 0.001)
    }

    func testWithState() throws {
        // Given
        let timer = try MeditationTimer(durationMinutes: 5)

        // When
        let runningTimer = timer.withState(.running)

        // Then
        XCTAssertEqual(runningTimer.state, .running)
        XCTAssertEqual(runningTimer.remainingSeconds, timer.remainingSeconds)
        XCTAssertEqual(runningTimer.durationMinutes, timer.durationMinutes)
    }

    func testReset() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // Tick a few times
        for _ in 0..<100 {
            timer = timer.tick()
        }

        // When
        let resetTimer = timer.reset()

        // Then
        XCTAssertEqual(resetTimer.state, .idle)
        XCTAssertEqual(resetTimer.remainingSeconds, 600)
        XCTAssertEqual(resetTimer.durationMinutes, 10)
        XCTAssertEqual(resetTimer.progress, 0.0)
    }

    func testEquatable() throws {
        // Given
        let timer1 = try MeditationTimer(durationMinutes: 10)
        let timer2 = try MeditationTimer(durationMinutes: 10)
        let timer3 = try MeditationTimer(durationMinutes: 5)

        // Then
        XCTAssertEqual(timer1, timer2)
        XCTAssertNotEqual(timer1, timer3)
    }

    // MARK: - Interval Gong Tests

    func testShouldPlayIntervalGong_NotRunning_ReturnsFalse() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 10)
        let intervalMinutes = 5

        // When/Then - idle state
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: intervalMinutes))

        // When/Then - paused state
        timer = timer.withState(.paused)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: intervalMinutes))

        // When/Then - completed state
        timer = timer.withState(.completed)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: intervalMinutes))
    }

    func testShouldPlayIntervalGong_ZeroInterval_ReturnsFalse() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // When/Then
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 0))
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: -1))
    }

    func testShouldPlayIntervalGong_FirstInterval_BeforeIntervalTime() throws {
        // Given - 10 minute timer, 5 minute intervals
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // When - Only 4 minutes elapsed (240 seconds)
        for _ in 0..<240 {
            timer = timer.tick()
        }

        // Then - Should not play yet (need 5 minutes = 300 seconds)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5))
    }

    func testShouldPlayIntervalGong_FirstInterval_ExactlyAtIntervalTime() throws {
        // Given - 10 minute timer, 5 minute intervals
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // When - Exactly 5 minutes elapsed (300 seconds)
        for _ in 0..<300 {
            timer = timer.tick()
        }

        // Then - Should play
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5))
    }

    func testShouldPlayIntervalGong_FirstInterval_AfterIntervalTime() throws {
        // Given - 10 minute timer, 5 minute intervals
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // When - 6 minutes elapsed (360 seconds)
        for _ in 0..<360 {
            timer = timer.tick()
        }

        // Then - Should still play (missed interval, play now)
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5))
    }

    func testShouldPlayIntervalGong_RemainingSecondsZero_ReturnsFalse() throws {
        // Given - Timer completed
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.running)

        // When - Tick to completion
        for _ in 0..<60 {
            timer = timer.tick()
        }

        // Then - Should not play (remainingSeconds = 0)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 1))
    }

    func testMarkIntervalGongPlayed_SetsTimestamp() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // When - Tick for 5 minutes and mark gong played
        for _ in 0..<300 {
            timer = timer.tick()
        }
        timer = timer.markIntervalGongPlayed()

        // Then
        XCTAssertEqual(timer.lastIntervalGongAt, 300) // 600 - 300 = 300 remaining
        XCTAssertEqual(timer.state, .running) // State unchanged
        XCTAssertEqual(timer.durationMinutes, 10) // Duration unchanged
    }

    func testShouldPlayIntervalGong_SecondInterval_NotEnoughTimePassed() throws {
        // Given - 15 minute timer, 5 minute intervals
        var timer = try MeditationTimer(durationMinutes: 15)
        timer = timer.withState(.running)

        // When - First interval at 5 minutes
        for _ in 0..<300 {
            timer = timer.tick()
        }
        timer = timer.markIntervalGongPlayed()

        // When - Only 2 more minutes passed (120 seconds)
        for _ in 0..<120 {
            timer = timer.tick()
        }

        // Then - Should not play yet (need 5 minutes since last gong)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5))
    }

    func testShouldPlayIntervalGong_SecondInterval_ExactlyEnoughTimePassed() throws {
        // Given - 15 minute timer, 5 minute intervals
        var timer = try MeditationTimer(durationMinutes: 15)
        timer = timer.withState(.running)

        // When - First interval at 5 minutes
        for _ in 0..<300 {
            timer = timer.tick()
        }
        timer = timer.markIntervalGongPlayed()

        // When - Exactly 5 more minutes passed (300 seconds)
        for _ in 0..<300 {
            timer = timer.tick()
        }

        // Then - Should play second interval
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5))
    }

    func testShouldPlayIntervalGong_MultipleIntervals_ThreeMinuteInterval() throws {
        // Given - 10 minute timer, 3 minute intervals (should play at 3, 6, 9 minutes)
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // When - Reach first interval (3 minutes = 180 seconds)
        for _ in 0..<180 {
            timer = timer.tick()
        }

        // Then - Should play first gong
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 3))

        // When - Mark played and continue to 6 minutes
        timer = timer.markIntervalGongPlayed()
        for _ in 0..<180 {
            timer = timer.tick()
        }

        // Then - Should play second gong
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 3))

        // When - Mark played and continue to 9 minutes
        timer = timer.markIntervalGongPlayed()
        for _ in 0..<180 {
            timer = timer.tick()
        }

        // Then - Should play third gong
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 3))
    }

    func testShouldPlayIntervalGong_TenMinuteInterval_LongerThanTimer() throws {
        // Given - 5 minute timer, 10 minute intervals (interval longer than timer)
        var timer = try MeditationTimer(durationMinutes: 5)
        timer = timer.withState(.running)

        // When - Run entire timer
        for _ in 0..<300 {
            timer = timer.tick()
        }

        // Then - Should never play (interval never reached)
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 10))
    }
}
