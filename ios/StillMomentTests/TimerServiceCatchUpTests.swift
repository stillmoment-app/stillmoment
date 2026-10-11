//
//  TimerServiceCatchUpTests.swift
//  Still Moment
//
//  The timer keeps counting by the clock when ticks were missed, e.g. while iOS suspended
//  the app during a phone call (shared-147).
//

import Combine
import XCTest
@testable import StillMoment

final class TimerServiceCatchUpTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockClock: MockClock!
    var updates: [(timer: MeditationTimer, events: [TimerEvent])] = []
    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        self.mockClock = MockClock()
        self.sut = TimerService(clock: self.mockClock)
        self.updates = []
        self.sut.timerPublisher
            .sink { [weak self] timer, events in
                self?.updates.append((timer, events))
            }
            .store(in: &self.cancellables)
    }

    override func tearDown() {
        self.sut.stop()
        self.cancellables.removeAll()
        self.sut = nil
        self.mockClock = nil
        super.tearDown()
    }

    func testMissedSeconds_areCountedOnTheNextTick() {
        // Given: meditation runs at 10:00
        self.startRunning(durationMinutes: 10)

        // When: 60 seconds pass without a tick, then a tick comes
        self.mockClock.advanceTime(by: 60)
        self.mockClock.tick()

        // Then: 61 seconds are gone
        XCTAssertEqual(self.lastTimer?.remainingSeconds, 539)
        XCTAssertEqual(self.lastTimer?.state, .running)
    }

    func testMeditationEndsDuringTheGap_endsExactlyOnce() {
        // Given: 0:30 left
        self.startRunning(durationMinutes: 1)
        self.mockClock.advance(ticks: 30)

        // When: 120 seconds pass without a tick
        self.mockClock.advanceTime(by: 120)
        self.mockClock.tick()

        // Then: end gong phase, reported once, no further ticks
        XCTAssertEqual(self.lastTimer?.state, .endGong)
        XCTAssertEqual(self.lastTimer?.remainingSeconds, 0)
        XCTAssertEqual(self.allEvents.filter { $0 == .meditationCompleted }.count, 1)
        let updatesAtEnd = self.updates.count
        self.mockClock.tick()
        XCTAssertEqual(self.updates.count, updatesAtEnd)
    }

    func testIntervalGongsDueDuringTheGap_areDropped() {
        // Given: interval gong every minute, meditation just began
        self.startRunning(durationMinutes: 10, intervalSettings: IntervalSettings(intervalMinutes: 1, mode: .repeating))

        // When: three minutes pass without a tick
        self.mockClock.advanceTime(by: 180)
        self.mockClock.tick()

        // Then: no burst of gongs afterwards
        XCTAssertFalse(self.lastEvents.contains(.intervalGongDue))

        // When: the next regular mark (4:00 elapsed) comes
        self.mockClock.advance(ticks: 59)

        // Then: the rhythm goes on with one gong
        XCTAssertEqual(self.allEvents.filter { $0 == .intervalGongDue }.count, 1)
        XCTAssertEqual(self.lastEvents, [.intervalGongDue])
    }

    func testPreparationEndsDuringTheGap_meditationTimeCountsTheRest() {
        // Given: 0:05 preparation left
        self.sut.start(durationMinutes: 10, preparationTimeSeconds: 15, intervalSettings: nil)
        self.mockClock.advance(ticks: 10)

        // When: 20 seconds pass without a tick
        self.mockClock.advanceTime(by: 20)
        self.mockClock.tick()

        // Then: preparation ended once, the 16 seconds after it count as meditation time
        XCTAssertEqual(self.allEvents.filter { $0 == .preparationCompleted }.count, 1)
        XCTAssertEqual(self.lastTimer?.state, .startGong)
        XCTAssertEqual(self.lastTimer?.remainingSeconds, 584)
    }

    func testIrregularTicksBelowHalfASecond_countOneSecondEach() {
        // Given
        self.startRunning(durationMinutes: 10)

        // When: one tick comes 0.4 s late, the next 0.1 s early
        self.mockClock.advanceTime(by: 0.4)
        self.mockClock.tick()
        let afterLateTick = self.lastTimer?.remainingSeconds
        self.mockClock.advanceTime(by: -0.1)
        self.mockClock.tick()

        // Then: one second per tick, as before
        XCTAssertEqual(afterLateTick, 599)
        XCTAssertEqual(self.lastTimer?.remainingSeconds, 598)
    }

    // MARK: Private

    private var lastTimer: MeditationTimer? {
        self.updates.last?.timer
    }

    private var lastEvents: [TimerEvent] {
        self.updates.last?.events ?? []
    }

    private var allEvents: [TimerEvent] {
        self.updates.flatMap(\.events)
    }

    /// Starts without preparation and lets the start gong finish right away
    private func startRunning(durationMinutes: Int, intervalSettings: IntervalSettings? = nil) {
        self.sut.start(
            durationMinutes: durationMinutes,
            preparationTimeSeconds: 0,
            intervalSettings: intervalSettings
        )
        self.sut.beginRunningPhase()
    }
}
