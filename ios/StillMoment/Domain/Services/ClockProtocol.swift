//
//  ClockProtocol.swift
//  Still Moment
//
//  Abstraction for time-based scheduling (enables testing without real timers)
//

import Combine
import Foundation

/// Protocol for scheduling time-based actions
///
/// Abstracts timer functionality to enable:
/// - Deterministic testing without real time delays
/// - Clean Architecture: Application layer depends on abstraction, not Timer
protocol ClockProtocol {
    /// Schedules a repeating action at the specified interval
    ///
    /// - Parameters:
    ///   - interval: Time between invocations in seconds
    ///   - action: Closure to execute on each tick
    /// - Returns: Cancellable to stop the scheduled action
    func schedule(interval: TimeInterval, action: @escaping () -> Void) -> AnyCancellable

    /// Returns the current time
    ///
    /// Used for time-based calculations (e.g., background handling)
    func now() -> Date
}
