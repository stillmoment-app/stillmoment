//
//  MeditationTimerEventTests.swift
//  Still Moment
//
//  Tests for TimerEvent emission from MeditationTimer.tick()
//

import XCTest
@testable import StillMoment

final class MeditationTimerEventTests: XCTestCase {
    // MARK: - Preparation Events

    func testPreparationCountdownReachesZero_emitsPreparationCompleted() throws {
        // Given - Timer in preparation with 1 second remaining
        var timer = try MeditationTimer(durationMinutes: 10, preparationTimeSeconds: 1)
        timer = timer.startPreparation()

        // When - Final preparation tick
        let (newTimer, events) = timer.tick()

        // Then - preparationCompleted event emitted, timer transitions to startGong
        XCTAssertEqual(events, [.preparationCompleted])
        XCTAssertEqual(newTimer.state, .startGong)
    }

    func testPreparationCountdownStillRunning_emitsNoEvents() throws {
        // Given - Timer in preparation with 5 seconds remaining
        var timer = try MeditationTimer(durationMinutes: 10, preparationTimeSeconds: 5)
        timer = timer.startPreparation()

        // When - One tick (4 seconds remaining)
        let (newTimer, events) = timer.tick()

        // Then - No events, still in preparation
        XCTAssertEqual(events, [])
        XCTAssertEqual(newTimer.state, .preparation)
        XCTAssertEqual(newTimer.remainingPreparationSeconds, 4)
    }

    // MARK: - Meditation Completed Events

    func testRunningTimerReachesZero_emitsMeditationCompleted() throws {
        // Given - Timer running with 1 second remaining
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.running)
        for _ in 0..<59 {
            let (ticked, _) = timer.tick()
            timer = ticked
        }
        XCTAssertEqual(timer.remainingSeconds, 1)

        // When - Final tick
        let (newTimer, events) = timer.tick()

        // Then - meditationCompleted event emitted, timer transitions to endGong
        XCTAssertEqual(events, [.meditationCompleted])
        XCTAssertEqual(newTimer.state, .endGong)
        XCTAssertEqual(newTimer.remainingSeconds, 0)
    }

    func testRunningTimerStillRunning_emitsNoEvents() throws {
        // Given - Timer running with plenty of time
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        // When
        let (newTimer, events) = timer.tick()

        // Then - No events, still running
        XCTAssertEqual(events, [])
        XCTAssertEqual(newTimer.state, .running)
    }

    func testStartGongTimerReachesZero_emitsMeditationCompleted() throws {
        // Given - Timer in startGong state with 1 second remaining
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.startGong)
        for _ in 0..<59 {
            let (ticked, _) = timer.tick()
            timer = ticked
        }

        // When - Final tick
        let (newTimer, events) = timer.tick()

        // Then
        XCTAssertEqual(events, [.meditationCompleted])
        XCTAssertEqual(newTimer.state, .endGong)
    }

    func testAttunementTimerReachesZero_emitsMeditationCompleted() throws {
        // Given - Timer in attunement state with 1 second remaining
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.attunement)
        for _ in 0..<59 {
            let (ticked, _) = timer.tick()
            timer = ticked
        }

        // When - Final tick
        let (newTimer, events) = timer.tick()

        // Then
        XCTAssertEqual(events, [.meditationCompleted])
        XCTAssertEqual(newTimer.state, .endGong)
    }

    // MARK: - Interval Gong Events

    func testIntervalGongDue_emitsIntervalGongDue() throws {
        // Given - 10 min timer, 5 min repeating interval, exactly at interval point
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)
        let intervalSettings = IntervalSettings(intervalMinutes: 5, mode: .repeating)

        // Tick to just before interval (299 ticks = 299 seconds elapsed)
        for _ in 0..<299 {
            let (ticked, _) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
        }

        // When - Tick at 300 seconds elapsed (5 min interval)
        let (newTimer, events) = timer.tick(intervalSettings: intervalSettings)

        // Then - intervalGongDue emitted, timer marks gong internally
        XCTAssertEqual(events, [.intervalGongDue])
        XCTAssertEqual(newTimer.state, .running)
        XCTAssertNotNil(newTimer.lastIntervalGongAt)
    }

    func testIntervalGongNotYetDue_emitsNoEvents() throws {
        // Given - 10 min timer, 5 min interval, only 4 min elapsed
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)
        let intervalSettings = IntervalSettings(intervalMinutes: 5, mode: .repeating)

        for _ in 0..<239 {
            let (ticked, _) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
        }

        // When - 240th second (4 min)
        let (_, events) = timer.tick(intervalSettings: intervalSettings)

        // Then - No interval gong yet
        XCTAssertEqual(events, [])
    }

    func testNoIntervalSettings_neverEmitsIntervalGongDue() throws {
        // Given - 10 min timer, exactly at 5 min mark, but no interval settings
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)

        for _ in 0..<300 {
            let (ticked, _) = timer.tick()
            timer = ticked
        }

        // When - At 5 min mark without interval settings
        let (_, events) = timer.tick()

        // Then - No interval gong events
        XCTAssertEqual(events, [])
    }

    // MARK: - Interval Modes

    func testAfterStartMode_emitsOnceOnly() throws {
        // Given - 20 min timer, 5 min afterStart interval
        var timer = try MeditationTimer(durationMinutes: 20)
        timer = timer.withState(.running)
        let intervalSettings = IntervalSettings(intervalMinutes: 5, mode: .afterStart)

        // Tick to 5 min
        for _ in 0..<300 {
            let (ticked, _) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
        }

        // First gong emitted and marked
        XCTAssertNotNil(timer.lastIntervalGongAt)

        // Tick to 10 min
        for _ in 0..<300 {
            let (ticked, events) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
            // No second gong in afterStart mode
            XCTAssertFalse(events.contains(.intervalGongDue))
        }
    }

    func testBeforeEndMode_emitsAtCorrectTime() throws {
        // Given - 20 min timer, 5 min beforeEnd interval
        var timer = try MeditationTimer(durationMinutes: 20)
        timer = timer.withState(.running)
        let intervalSettings = IntervalSettings(intervalMinutes: 5, mode: .beforeEnd)

        // Tick to 15 min elapsed (5 min remaining = 300 seconds)
        for _ in 0..<899 {
            let (ticked, _) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
        }

        // When - At exactly 300 seconds remaining
        let (newTimer, events) = timer.tick(intervalSettings: intervalSettings)

        // Then
        XCTAssertEqual(events, [.intervalGongDue])
        XCTAssertNotNil(newTimer.lastIntervalGongAt)
    }

    // MARK: - 5-Second Protection

    func testFiveSecondProtection_noIntervalGongInLastFiveSeconds() throws {
        // Given - 1 min timer, 1 min interval (but interval >= total → no gong anyway)
        // Use 2 min timer, 1 min interval
        var timer = try MeditationTimer(durationMinutes: 2)
        timer = timer.withState(.running)
        let intervalSettings = IntervalSettings(intervalMinutes: 1, mode: .repeating)

        // Tick first interval at 1 min
        for _ in 0..<60 {
            let (ticked, _) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
        }

        // Mark was set at first interval, now tick to 5 seconds remaining
        for _ in 0..<55 {
            let (ticked, _) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
        }

        XCTAssertEqual(timer.remainingSeconds, 5)

        // When - Tick at 5 seconds remaining
        let (_, events) = timer.tick(intervalSettings: intervalSettings)

        // Then - No interval gong due to 5-second protection
        XCTAssertFalse(events.contains(.intervalGongDue))
    }

    // MARK: - Complete Session Event Sequence

    func testFullSessionEventSequence() throws {
        // Given - 1 min timer with 2-second preparation
        var timer = try MeditationTimer(durationMinutes: 1, preparationTimeSeconds: 2)
        timer = timer.startPreparation()
        var allEvents: [TimerEvent] = []

        // Preparation phase: tick 2 times
        for _ in 0..<2 {
            let (ticked, events) = timer.tick()
            timer = ticked
            allEvents.append(contentsOf: events)
        }

        // Should have emitted preparationCompleted
        XCTAssertEqual(allEvents, [.preparationCompleted])
        XCTAssertEqual(timer.state, .startGong)

        // Simulate: ViewModel dispatches preparationFinished → reducer → startGongFinished → running
        // For this test we just set state to running (reducer logic tested elsewhere)
        timer = timer.withState(.running)

        // Running phase: tick 60 times
        for _ in 0..<60 {
            let (ticked, events) = timer.tick()
            timer = ticked
            allEvents.append(contentsOf: events)
        }

        // Then - Full sequence: preparationCompleted, then meditationCompleted
        XCTAssertEqual(allEvents, [.preparationCompleted, .meditationCompleted])
        XCTAssertEqual(timer.state, .endGong)
    }

    // MARK: - Idle/EndGong/Completed States

    func testIdleState_emitsNoEvents() throws {
        // Given
        let timer = try MeditationTimer(durationMinutes: 10)

        // When
        let (newTimer, events) = timer.tick()

        // Then
        XCTAssertEqual(events, [])
        XCTAssertEqual(newTimer, timer) // No change
    }

    func testEndGongState_emitsNoEvents() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.endGong)

        // When
        let (newTimer, events) = timer.tick()

        // Then
        XCTAssertEqual(events, [])
        XCTAssertEqual(newTimer, timer)
    }

    func testCompletedState_emitsNoEvents() throws {
        // Given
        var timer = try MeditationTimer(durationMinutes: 1)
        timer = timer.withState(.completed)

        // When
        let (newTimer, events) = timer.tick()

        // Then
        XCTAssertEqual(events, [])
        XCTAssertEqual(newTimer, timer)
    }

    // MARK: - Repeating Interval: Multiple Gongs

    func testRepeatingMode_emitsMultipleIntervalGongs() throws {
        // Given - 10 min timer, 3 min repeating intervals
        var timer = try MeditationTimer(durationMinutes: 10)
        timer = timer.withState(.running)
        let intervalSettings = IntervalSettings(intervalMinutes: 3, mode: .repeating)
        var gongCount = 0

        // When - Tick through entire meditation
        for _ in 0..<594 { // Stop before 5-second protection zone
            let (ticked, events) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
            if events.contains(.intervalGongDue) {
                gongCount += 1
            }
        }

        // Then - Should have emitted 3 gongs (at 3, 6, 9 minutes)
        XCTAssertEqual(gongCount, 3)
    }
}
