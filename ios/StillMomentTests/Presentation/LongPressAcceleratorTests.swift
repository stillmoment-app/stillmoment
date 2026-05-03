//
//  LongPressAcceleratorTests.swift
//  Still Moment
//
//  Tests fuer Long-Press-Beschleunigung am Atemkreis-Picker (shared-086).
//  Spec: 320 ms Initial-Delay, danach 80 ms Tick.
//

import Combine
import XCTest
@testable import StillMoment

@MainActor
final class LongPressAcceleratorTests: XCTestCase {
    // MARK: - AK-4: Long-Press beschleunigt

    func testStartFiresActionImmediately() {
        // Given
        let scheduler = FakeLongPressScheduler()
        var calls = 0
        let sut = LongPressAccelerator(scheduler: scheduler) { calls += 1 }

        // When
        sut.start()

        // Then: erster Tick beim Druecken sofort (Initial-Bump)
        XCTAssertEqual(calls, 1, "start() muss sofort einmal feuern")
    }

    func testNoFurtherTicksBeforeInitialDelay() {
        // Vor Ablauf der 320 ms passiert nichts ausser dem Initial-Bump.
        let scheduler = FakeLongPressScheduler()
        var calls = 0
        let sut = LongPressAccelerator(scheduler: scheduler) { calls += 1 }

        sut.start()
        // Initial-Delay-Closure noch nicht gefeuert
        XCTAssertEqual(calls, 1)
        XCTAssertNil(scheduler.pendingRepeating, "Repeating darf erst nach Initial-Delay starten")
    }

    func testRepeatingStartsAfterInitialDelay() {
        let scheduler = FakeLongPressScheduler()
        var calls = 0
        let sut = LongPressAccelerator(scheduler: scheduler) { calls += 1 }

        sut.start()
        scheduler.fireInitialDelay()

        XCTAssertNotNil(scheduler.pendingRepeating, "Nach Initial-Delay muss eine Repeating-Subscription bestehen")
    }

    func testEachRepeatingTickFiresAction() {
        let scheduler = FakeLongPressScheduler()
        var calls = 0
        let sut = LongPressAccelerator(scheduler: scheduler) { calls += 1 }

        sut.start()
        scheduler.fireInitialDelay()
        XCTAssertEqual(calls, 1, "Erst nach erstem Repeating-Tick steigt der Counter")

        scheduler.fireRepeatingTick()
        XCTAssertEqual(calls, 2)

        scheduler.fireRepeatingTick()
        XCTAssertEqual(calls, 3)
    }

    func testStopBeforeInitialDelayPreventsRepeating() {
        let scheduler = FakeLongPressScheduler()
        var calls = 0
        let sut = LongPressAccelerator(scheduler: scheduler) { calls += 1 }

        sut.start()
        sut.stop()
        // Auch wenn die "Initial-Delay-Closure" noch im Test-Scheduler liegt,
        // darf sie nichts mehr ausloesen — die Subscription ist abgeraeumt.
        scheduler.fireInitialDelay()

        XCTAssertNil(scheduler.pendingRepeating, "stop() raeumt vor Initial-Delay sauber auf")
        XCTAssertEqual(calls, 1, "Nach stop() darf nur der Initial-Bump gezaehlt sein")
    }

    func testStopDuringRepeatingHaltsAllTicks() {
        let scheduler = FakeLongPressScheduler()
        var calls = 0
        let sut = LongPressAccelerator(scheduler: scheduler) { calls += 1 }

        sut.start()
        scheduler.fireInitialDelay()
        scheduler.fireRepeatingTick()
        XCTAssertEqual(calls, 2)

        sut.stop()

        // Nach stop() darf KEIN weiterer Tick mehr ankommen, auch wenn der
        // Test versucht ihn manuell auszuloesen.
        scheduler.fireRepeatingTick()
        XCTAssertEqual(calls, 2, "Kein Tick nach Release (kein Tick-Leak)")
    }

    func testRestartAfterStopFiresInitialBumpAgain() {
        let scheduler = FakeLongPressScheduler()
        var calls = 0
        let sut = LongPressAccelerator(scheduler: scheduler) { calls += 1 }

        sut.start()
        sut.stop()
        sut.start()

        XCTAssertEqual(calls, 2, "Jeder start() fuehrt zu einem Initial-Bump")
    }

    // MARK: - Spec-Werte

    func testInitialDelayMatchesSpec() {
        let scheduler = FakeLongPressScheduler()
        let sut = LongPressAccelerator(initialDelay: 0.32, repeatInterval: 0.08, scheduler: scheduler) {}

        sut.start()

        XCTAssertEqual(scheduler.lastDelay ?? -1, 0.32, accuracy: 0.001)
    }

    func testRepeatIntervalMatchesSpec() {
        let scheduler = FakeLongPressScheduler()
        let sut = LongPressAccelerator(initialDelay: 0.32, repeatInterval: 0.08, scheduler: scheduler) {}

        sut.start()
        scheduler.fireInitialDelay()

        XCTAssertEqual(scheduler.lastInterval ?? -1, 0.08, accuracy: 0.001)
    }
}

// MARK: - Test-Scheduler

/// Minimaler Fake-Scheduler. Statt echter Zeit zu warten, halten wir die
/// gestellten Closures fest und feuern sie auf Wunsch ueber `fire*()`.
@MainActor
final class FakeLongPressScheduler: LongPressSchedulerProtocol {
    private(set) var lastDelay: TimeInterval?
    private(set) var lastInterval: TimeInterval?
    private(set) var pendingDelayed: (() -> Void)?
    private(set) var pendingRepeating: (() -> Void)?

    func schedule(after delay: TimeInterval, _ work: @escaping () -> Void) -> AnyCancellable {
        self.lastDelay = delay
        self.pendingDelayed = work
        return AnyCancellable { [weak self] in
            self?.pendingDelayed = nil
        }
    }

    func scheduleRepeating(every interval: TimeInterval, _ work: @escaping () -> Void) -> AnyCancellable {
        self.lastInterval = interval
        self.pendingRepeating = work
        return AnyCancellable { [weak self] in
            self?.pendingRepeating = nil
        }
    }

    func fireInitialDelay() {
        self.pendingDelayed?()
    }

    func fireRepeatingTick() {
        self.pendingRepeating?()
    }
}
