//
//  TimerServiceTests.swift
//  Still Moment
//

import Combine
import XCTest
@testable import StillMoment

final class TimerServiceTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        self.sut = TimerService()
        self.cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        self.sut.stop()
        self.cancellables = nil
        self.sut = nil
        super.tearDown()
    }

    func testStartTimer() {
        // Given
        let expectation = expectation(description: "Timer starts")
        var receivedTimer: MeditationTimer?

        self.sut.timerPublisher
            .first()
            .sink { timer in
                receivedTimer = timer
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 5, preparationTimeSeconds: 0)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedTimer)
        XCTAssertEqual(receivedTimer?.state, .running) // No preparation (preparationTimeSeconds: 0)
        XCTAssertEqual(receivedTimer?.durationMinutes, 5)
        XCTAssertEqual(receivedTimer?.remainingSeconds, 300)
    }

    func testPauseTimer() {
        // Given
        let runningExpectation = expectation(description: "Timer starts running")
        let pauseExpectation = expectation(description: "Timer pauses")

        var timerStates: [TimerState] = []

        self.sut.timerPublisher
            .sink { timer in
                timerStates.append(timer.state)

                if timer.state == .running, timerStates.count == 1 {
                    runningExpectation.fulfill()
                } else if timer.state == .paused {
                    pauseExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 1, preparationTimeSeconds: 0)
        wait(for: [runningExpectation], timeout: 1.0) // No preparation (preparationTimeSeconds: 0)

        self.sut.pause()

        // Then
        wait(for: [pauseExpectation], timeout: 1.0)
        XCTAssertTrue(timerStates.contains(.running))
        XCTAssertTrue(timerStates.contains(.paused))
        XCTAssertFalse(timerStates.contains(.preparation)) // No preparation phase
    }

    func testResumeTimer() {
        // Given
        let runningExpectation = expectation(description: "Timer starts running")
        let pauseExpectation = expectation(description: "Timer pauses")
        let resumeExpectation = expectation(description: "Timer resumes")

        var stateTransitions: [TimerState] = []
        var runningFulfilled = false

        self.sut.timerPublisher
            .sink { timer in
                stateTransitions.append(timer.state)

                if timer.state == .running, !runningFulfilled {
                    runningFulfilled = true
                    runningExpectation.fulfill()
                } else if timer.state == .paused {
                    pauseExpectation.fulfill()
                } else if timer.state == .running, stateTransitions.contains(.paused) {
                    resumeExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 1, preparationTimeSeconds: 0)
        wait(for: [runningExpectation], timeout: 1.0) // No preparation (preparationTimeSeconds: 0)

        self.sut.pause()
        wait(for: [pauseExpectation], timeout: 1.0)

        self.sut.resume()

        // Then
        wait(for: [resumeExpectation], timeout: 1.0)
        XCTAssertEqual(stateTransitions.first, .running) // No preparation phase
        XCTAssertTrue(stateTransitions.contains(.paused))
        XCTAssertEqual(stateTransitions.last, .running)
        XCTAssertFalse(stateTransitions.contains(.preparation)) // No preparation phase
    }

    func testResetTimer() {
        // Given
        let startExpectation = expectation(description: "Timer starts")
        let resetExpectation = expectation(description: "Timer resets")

        var lastTimer: MeditationTimer?
        var startFulfilled = false

        self.sut.timerPublisher
            .sink { timer in
                lastTimer = timer

                if timer.state == .running, !startFulfilled {
                    startFulfilled = true
                    startExpectation.fulfill()
                } else if timer.state == .idle, timer.remainingSeconds == timer.totalSeconds {
                    resetExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 5, preparationTimeSeconds: 0)
        wait(for: [startExpectation], timeout: 1.0)

        self.sut.reset()

        // Then
        wait(for: [resetExpectation], timeout: 1.0)
        XCTAssertEqual(lastTimer?.state, .idle)
        XCTAssertEqual(lastTimer?.remainingSeconds, 300)
    }

    func testTimerTicking() {
        // Given
        let expectation = expectation(description: "Timer ticks")
        expectation.expectedFulfillmentCount = 3 // Start + 2 ticks

        var receivedTimers: [MeditationTimer] = []

        self.sut.timerPublisher
            .prefix(3)
            .sink { timer in
                receivedTimers.append(timer)
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 1, preparationTimeSeconds: 0)

        // Then
        wait(for: [expectation], timeout: 3.0)

        XCTAssertGreaterThanOrEqual(receivedTimers.count, 2)
        XCTAssertEqual(receivedTimers[0].state, .running) // No preparation (preparationTimeSeconds: 0)
        XCTAssertEqual(receivedTimers[0].remainingSeconds, 60)

        // Verify timer is progressing (remainingSeconds decreases)
        if receivedTimers.count >= 2 {
            XCTAssertEqual(receivedTimers[1].state, .running)
            XCTAssertLessThan(receivedTimers[1].remainingSeconds, receivedTimers[0].remainingSeconds)
        }
    }

    func testStopTimer() {
        // Given
        let expectation = expectation(description: "Timer starts")

        self.sut.timerPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        self.sut.start(durationMinutes: 1, preparationTimeSeconds: 0)
        wait(for: [expectation], timeout: 1.0)

        // When
        self.sut.stop()

        // Then
        // Wait a bit to ensure no more updates
        let noUpdateExpectation = self.expectation(description: "No more updates")
        noUpdateExpectation.isInverted = true

        self.sut.timerPublisher
            .sink { _ in
                noUpdateExpectation.fulfill()
            }
            .store(in: &self.cancellables)

        wait(for: [noUpdateExpectation], timeout: 0.5)
    }
}
