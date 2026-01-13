//
//  SystemClock.swift
//  Still Moment
//
//  Production implementation of ClockProtocol using Foundation Timer
//

import Combine
import Foundation

/// Production implementation of ClockProtocol
///
/// Uses `Timer.publish` to schedule repeating actions on the main run loop.
final class SystemClock: ClockProtocol {
    func schedule(interval: TimeInterval, action: @escaping () -> Void) -> AnyCancellable {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in action() }
    }

    func now() -> Date {
        Date()
    }
}
