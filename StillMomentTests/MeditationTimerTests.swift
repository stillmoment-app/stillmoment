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
}
