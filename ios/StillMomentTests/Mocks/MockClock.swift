//
//  MockClock.swift
//  Still Moment
//
//  Test mock for ClockProtocol - enables deterministic time control in tests
//

import Combine
import Foundation
@testable import StillMoment

/// Mock implementation of ClockProtocol for testing
///
/// Instead of waiting for real time, tests can call `advance()` to simulate time passing.
final class MockClock: ClockProtocol {
    /// The scheduled action (captured for manual invocation)
    private var action: (() -> Void)?

    /// Whether schedule was called
    private(set) var scheduleCalled = false

    /// The interval that was requested
    private(set) var requestedInterval: TimeInterval?

    /// Simulated current time (can be advanced for background simulation)
    private(set) var currentTime: Date = .init()

    func schedule(interval: TimeInterval, action: @escaping () -> Void) -> AnyCancellable {
        self.scheduleCalled = true
        self.requestedInterval = interval
        self.action = action
        return AnyCancellable {}
    }

    func now() -> Date {
        self.currentTime
    }

    /// Simulates one tick (one interval passing)
    func tick() {
        self.currentTime = self.currentTime.addingTimeInterval(self.requestedInterval ?? 1.0)
        self.action?()
    }

    /// Simulates multiple ticks
    ///
    /// - Parameter count: Number of ticks to simulate
    func advance(ticks count: Int) {
        for _ in 0..<count {
            self.tick()
        }
    }

    /// Simulates time passing without triggering ticks (background scenario)
    ///
    /// - Parameter seconds: Seconds to advance the clock
    func advanceTime(by seconds: TimeInterval) {
        self.currentTime = self.currentTime.addingTimeInterval(seconds)
    }

    /// Resets the mock state
    func reset() {
        self.scheduleCalled = false
        self.requestedInterval = nil
        self.action = nil
        self.currentTime = Date()
    }
}
