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
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockClock: MockClock!

    override func setUp() {
        super.setUp()
        self.mockClock = MockClock()
        self.sut = TimerService(clock: self.mockClock)
        self.cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        self.sut.stop()
        self.cancellables = nil
        self.sut = nil
        self.mockClock = nil
        super.tearDown()
    }

    func testStartTimer() {
        // Given
        var receivedTimer: MeditationTimer?

        self.sut.timerPublisher
            .first()
            .sink { timer, _ in
                receivedTimer = timer
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 5, preparationTimeSeconds: 0, intervalSettings: nil)

        // Then
        XCTAssertNotNil(receivedTimer)
        XCTAssertEqual(receivedTimer?.state, .startGong) // No preparation → startGong directly
        XCTAssertEqual(receivedTimer?.durationMinutes, 5)
        XCTAssertEqual(receivedTimer?.remainingSeconds, 300)
    }

    func testResetTimer() {
        // Given
        var lastTimer: MeditationTimer?

        self.sut.timerPublisher
            .sink { timer, _ in
                lastTimer = timer
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 5, preparationTimeSeconds: 0, intervalSettings: nil)
        self.sut.reset()

        // Then
        XCTAssertEqual(lastTimer?.state, .idle)
        XCTAssertEqual(lastTimer?.remainingSeconds, 300)
    }

    func testTimerTicking() {
        // Given
        var receivedTimers: [MeditationTimer] = []

        self.sut.timerPublisher
            .sink { timer, _ in
                receivedTimers.append(timer)
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 1, preparationTimeSeconds: 0, intervalSettings: nil)
        self.mockClock.tick() // First tick
        self.mockClock.tick() // Second tick

        // Then
        XCTAssertEqual(receivedTimers.count, 3) // Start + 2 ticks
        XCTAssertEqual(receivedTimers[0].state, .startGong) // No preparation → startGong directly
        XCTAssertEqual(receivedTimers[0].remainingSeconds, 60)

        // Verify timer is progressing (remainingSeconds decreases)
        XCTAssertEqual(receivedTimers[1].state, .startGong)
        XCTAssertLessThan(receivedTimers[1].remainingSeconds, receivedTimers[0].remainingSeconds)
    }

    func testStartWithoutPreparation_emitsPreparationCompleted() {
        // Given — user starts timer without preparation time
        var receivedEvents: [TimerEvent] = []

        self.sut.timerPublisher
            .first()
            .sink { _, events in
                receivedEvents = events
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 5, preparationTimeSeconds: 0, intervalSettings: nil)

        // Then — preparation is immediately complete, so start gong flow can begin
        XCTAssertEqual(receivedEvents, [.preparationCompleted])
    }

    func testStartWithPreparation_doesNotEmitPreparationCompleted() {
        // Given — user starts timer with preparation time
        var receivedEvents: [TimerEvent] = []

        self.sut.timerPublisher
            .first()
            .sink { _, events in
                receivedEvents = events
            }
            .store(in: &self.cancellables)

        // When
        self.sut.start(durationMinutes: 5, preparationTimeSeconds: 15, intervalSettings: nil)

        // Then — preparation not yet complete, event comes later via tick()
        XCTAssertEqual(receivedEvents, [])
    }

    func testStopTimer() {
        // Given
        var received = false

        self.sut.timerPublisher
            .sink { _, _ in
                received = true
            }
            .store(in: &self.cancellables)

        self.sut.start(durationMinutes: 1, preparationTimeSeconds: 0, intervalSettings: nil)
        XCTAssertTrue(received)

        // When
        self.sut.stop()
        received = false

        // Then - No more updates after stop
        self.mockClock.tick()
        XCTAssertFalse(received)
    }
}
