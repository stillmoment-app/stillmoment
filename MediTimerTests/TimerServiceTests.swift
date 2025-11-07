//
//  TimerServiceTests.swift
//  MediTimerTests
//
//  Unit Tests - TimerService
//

import Combine
import XCTest
@testable import MediTimer

final class TimerServiceTests: XCTestCase {
    var sut: TimerService!
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
        self.sut.start(durationMinutes: 5)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedTimer)
        XCTAssertEqual(receivedTimer?.state, .running)
        XCTAssertEqual(receivedTimer?.durationMinutes, 5)
        XCTAssertEqual(receivedTimer?.remainingSeconds, 300)
    }

    func testPauseTimer() {
        // Given
        let startExpectation = expectation(description: "Timer starts")
        let pauseExpectation = expectation(description: "Timer pauses")

        var timerStates: [TimerState] = []

        self.sut.timerPublisher
            .sink { timer in
                timerStates.append(timer.state)

                if timer.state == .running {
                    startExpectation.fulfill()
                } else if timer.state == .paused {
                    pauseExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 1)
        wait(for: [startExpectation], timeout: 1.0)

        self.sut.pause()

        // Then
        wait(for: [pauseExpectation], timeout: 1.0)
        XCTAssertTrue(timerStates.contains(.running))
        XCTAssertTrue(timerStates.contains(.paused))
    }

    func testResumeTimer() {
        // Given
        let startExpectation = expectation(description: "Timer starts")
        let pauseExpectation = expectation(description: "Timer pauses")
        let resumeExpectation = expectation(description: "Timer resumes")

        var stateTransitions: [TimerState] = []

        self.sut.timerPublisher
            .sink { timer in
                stateTransitions.append(timer.state)

                if timer.state == .running, stateTransitions.count == 1 {
                    startExpectation.fulfill()
                } else if timer.state == .paused {
                    pauseExpectation.fulfill()
                } else if timer.state == .running, stateTransitions.count > 2 {
                    resumeExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 1)
        wait(for: [startExpectation], timeout: 1.0)

        self.sut.pause()
        wait(for: [pauseExpectation], timeout: 1.0)

        self.sut.resume()

        // Then
        wait(for: [resumeExpectation], timeout: 1.0)
        XCTAssertEqual(stateTransitions.first, .running)
        XCTAssertTrue(stateTransitions.contains(.paused))
        XCTAssertEqual(stateTransitions.last, .running)
    }

    func testResetTimer() {
        // Given
        let startExpectation = expectation(description: "Timer starts")
        let resetExpectation = expectation(description: "Timer resets")

        var lastTimer: MeditationTimer?

        self.sut.timerPublisher
            .sink { timer in
                lastTimer = timer

                if timer.state == .running {
                    startExpectation.fulfill()
                } else if timer.state == .idle, timer.remainingSeconds == timer.totalSeconds {
                    resetExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 5)
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
        self.sut.start(durationMinutes: 1)

        // Then
        wait(for: [expectation], timeout: 3.0)

        XCTAssertGreaterThanOrEqual(receivedTimers.count, 2)
        XCTAssertEqual(receivedTimers[0].remainingSeconds, 60)

        // Verify time is decreasing
        if receivedTimers.count >= 2 {
            XCTAssertLessThan(receivedTimers[1].remainingSeconds, receivedTimers[0].remainingSeconds)
        }
    }

    func testStopTimer() {
        // Given
        let expectation = expectation(description: "Timer starts")
        var receivedTimer: MeditationTimer?

        self.sut.timerPublisher
            .sink { timer in
                receivedTimer = timer
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        self.sut.start(durationMinutes: 1)
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
