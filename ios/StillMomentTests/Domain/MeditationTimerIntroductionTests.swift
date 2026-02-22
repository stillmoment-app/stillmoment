//
//  MeditationTimerIntroductionTests.swift
//  Still Moment
//
//  Tests for MeditationTimer introduction phase behavior
//

import XCTest
@testable import StillMoment

final class MeditationTimerIntroductionTests: XCTestCase {
    // MARK: - Preparation → StartGong

    func testTick_preparationFinished_transitionsToStartGong() throws {
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 1
        )
        timer = timer.startPreparation()

        // Tick once to finish preparation (1 second)
        let (ticked, _) = timer.tick()

        XCTAssertEqual(ticked.state, .startGong)
        XCTAssertEqual(ticked.remainingSeconds, 600) // Main timer unchanged during last prep tick
    }

    // MARK: - Tick During StartGong

    func testTick_duringStartGong_decrementsRemainingSeconds() throws {
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.startGong)

        XCTAssertEqual(timer.remainingSeconds, 600)

        let (ticked, _) = timer.tick()

        XCTAssertEqual(ticked.state, .startGong)
        XCTAssertEqual(ticked.remainingSeconds, 599)
    }

    func testTick_duringStartGong_multipleTicksDecrementCorrectly() throws {
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.startGong)

        // Tick 3 times during gong period
        (timer, _) = timer.tick() // 599
        (timer, _) = timer.tick() // 598
        (timer, _) = timer.tick() // 597

        XCTAssertEqual(timer.state, .startGong)
        XCTAssertEqual(timer.remainingSeconds, 597)
    }

    // MARK: - Introduction Phase (Event-Driven)

    func testTick_duringIntroduction_neverAutoTransitionsToRunning() throws {
        var timer = try MeditationTimer(
            durationMinutes: 1, // 60 seconds
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.introduction)

        // Tick many times - should stay in introduction (event-driven transition)
        for _ in 0..<55 {
            (timer, _) = timer.tick()
        }

        XCTAssertEqual(timer.state, .introduction)
        XCTAssertEqual(timer.remainingSeconds, 5)
    }

    func testTick_duringIntroduction_decrementsRemainingSeconds() throws {
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.introduction)

        let (ticked, _) = timer.tick()

        XCTAssertEqual(ticked.state, .introduction)
        XCTAssertEqual(ticked.remainingSeconds, 599)
    }

    // MARK: - Timer Expires During Introduction

    func testTick_timerExpiresDuringIntroduction_transitionsToCompleted() throws {
        var timer = try MeditationTimer(
            durationMinutes: 1, // 60 seconds
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.introduction)

        // Tick 60 times (timer duration)
        for _ in 0..<60 {
            (timer, _) = timer.tick()
        }

        XCTAssertEqual(timer.state, .endGong)
        XCTAssertEqual(timer.remainingSeconds, 0)
    }

    // MARK: - endIntroduction

    func testEndIntroduction_transitionsToRunning() throws {
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.introduction)

        // Simulate some ticks during introduction
        (timer, _) = timer.tick() // 599
        (timer, _) = timer.tick() // 598
        (timer, _) = timer.tick() // 597

        let ended = timer.endIntroduction()

        XCTAssertEqual(ended.state, .running)
        XCTAssertEqual(ended.remainingSeconds, 597)
    }

    func testEndIntroduction_setsSilentPhaseStartRemaining() throws {
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.introduction)

        // Tick 95 times during introduction
        for _ in 0..<95 {
            (timer, _) = timer.tick()
        }

        let ended = timer.endIntroduction()

        XCTAssertEqual(ended.state, .running)
        XCTAssertEqual(ended.silentPhaseStartRemaining, 505) // 600 - 95
    }

    // MARK: - Introduction Counts Toward Total Duration

    func testIntroduction_countsTowardTotalDuration() throws {
        var timer = try MeditationTimer(
            durationMinutes: 1, // 60 seconds total
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.introduction)

        XCTAssertEqual(timer.remainingSeconds, 60)
        XCTAssertEqual(timer.totalSeconds, 60)

        // Tick 30 times through introduction
        for _ in 0..<30 {
            (timer, _) = timer.tick()
        }

        // End introduction via event callback
        timer = timer.endIntroduction()

        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.remainingSeconds, 30) // 60 - 30 = 30 seconds left
    }

    // MARK: - Gong Period: Main Timer Ticks

    func testStartGong_mainTimerTicks() throws {
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 1
        )
        timer = timer.startPreparation()
        (timer, _) = timer.tick() // prep → startGong

        XCTAssertEqual(timer.state, .startGong)
        XCTAssertEqual(timer.remainingSeconds, 600)

        // Tick 3 times during gong period
        (timer, _) = timer.tick() // 599
        (timer, _) = timer.tick() // 598
        (timer, _) = timer.tick() // 597

        XCTAssertEqual(timer.state, .startGong)
        XCTAssertEqual(timer.remainingSeconds, 597)
    }

    // MARK: - Interval Gongs After Introduction

    func testIntervalGong_afterIntroduction_usesEffectiveStart() throws {
        // 10 min timer, 5 min intervals
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.introduction)

        // Tick 95 times during introduction, then end it
        for _ in 0..<95 {
            (timer, _) = timer.tick()
        }
        timer = timer.endIntroduction()

        XCTAssertEqual(timer.state, .running)
        let silentStart = try XCTUnwrap(timer.silentPhaseStartRemaining)

        // Before first interval: no gong
        XCTAssertFalse(timer.shouldPlayIntervalGong(intervalMinutes: 5))

        // Tick until 5 minutes elapsed in silent phase
        let silentElapsed = 5 * 60
        for _ in 0..<silentElapsed {
            (timer, _) = timer.tick()
        }

        // Now interval gong should trigger (5 min after silent phase start)
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5))

        // Verify: remaining is silentStart - 300
        XCTAssertEqual(timer.remainingSeconds, silentStart - silentElapsed)
    }

    func testIntervalGong_withoutIntroduction_usesTotalSeconds() throws {
        // 10 min timer, no introduction, 5 min intervals
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.running)

        XCTAssertNil(timer.silentPhaseStartRemaining)

        // Tick 5 minutes
        for _ in 0..<(5 * 60) {
            (timer, _) = timer.tick()
        }

        // Interval gong should trigger at 5 min
        XCTAssertTrue(timer.shouldPlayIntervalGong(intervalMinutes: 5))
    }

    // MARK: - Reset

    func testReset_clearsState() throws {
        var timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )
        timer = timer.withState(.introduction)

        let resetTimer = timer.reset()

        XCTAssertEqual(resetTimer.state, .idle)
        XCTAssertNil(resetTimer.silentPhaseStartRemaining)
    }

    // MARK: - withState

    func testWithState_preservesRemainingSeconds() throws {
        let timer = try MeditationTimer(
            durationMinutes: 10,
            preparationTimeSeconds: 0
        )

        let running = timer.withState(.running)

        XCTAssertEqual(running.state, .running)
        XCTAssertEqual(running.remainingSeconds, 600)
    }
}
