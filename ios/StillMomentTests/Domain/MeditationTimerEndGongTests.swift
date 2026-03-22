//
//  MeditationTimerEndGongTests.swift
//  Still Moment
//
//  Tests for the endGong phase: when the meditation timer reaches zero,
//  it transitions to .endGong (completion gong playing) before .completed.
//

import XCTest
@testable import StillMoment

// MARK: - MeditationTimer endGong Tests

final class MeditationTimerEndGongTests: XCTestCase {
    // MARK: - Timer reaches zero -> endGong (not completed)

    func testRunningTimerReachesZero_transitionsToEndGong() throws {
        // Given - A 1-minute timer with 1 second remaining
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.running)
        for _ in 0..<59 {
            (timer, _) = timer.tick()
        }
        XCTAssertEqual(timer.remainingSeconds, 1)

        // When - Final tick
        (timer, _) = timer.tick()

        // Then - Should be in endGong, NOT completed
        XCTAssertEqual(timer.state, .endGong)
        XCTAssertEqual(timer.remainingSeconds, 0)
    }

    func testStartGongTimerReachesZero_transitionsToEndGong() throws {
        // Given - Timer in startGong state with 1 second remaining
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.startGong)
        for _ in 0..<59 {
            (timer, _) = timer.tick()
        }

        // When - Final tick
        (timer, _) = timer.tick()

        // Then
        XCTAssertEqual(timer.state, .endGong)
        XCTAssertEqual(timer.remainingSeconds, 0)
    }

    func testAttunementTimerReachesZero_transitionsToEndGong() throws {
        // Given - Timer in attunement state with 1 second remaining
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.attunement)
        for _ in 0..<59 {
            (timer, _) = timer.tick()
        }

        // When - Final tick
        (timer, _) = timer.tick()

        // Then
        XCTAssertEqual(timer.state, .endGong)
        XCTAssertEqual(timer.remainingSeconds, 0)
    }

    // MARK: - endGong does not tick further

    func testEndGongState_doesNotTickFurther() throws {
        // Given - Timer in endGong state at 0 seconds
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.endGong)

        // When
        let (ticked, _) = timer.tick()

        // Then - Should remain in endGong, no change
        XCTAssertEqual(ticked.state, .endGong)
        XCTAssertEqual(ticked, timer)
    }

    // MARK: - isCompleted during endGong

    func testEndGongWithZeroSeconds_isCompleted() throws {
        // Given - Timer in endGong state (remainingSeconds = 0 after tick)
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.running)
        for _ in 0..<60 {
            (timer, _) = timer.tick()
        }

        // Then - isCompleted checks remainingSeconds, should be true
        XCTAssertEqual(timer.state, .endGong)
        XCTAssertTrue(timer.isCompleted)
    }
}
