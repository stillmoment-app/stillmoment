//
//  SystemClock.swift
//  Still Moment
//
//  Production implementation of ClockProtocol using DispatchSourceTimer
//

import Combine
import Foundation

/// Production implementation of ClockProtocol
///
/// Uses `DispatchSourceTimer` instead of `Timer.publish` to ensure timers
/// continue firing when the screen is locked. `Timer.publish` with `.common`
/// RunLoop mode gets paused by iOS during screen lock, but `DispatchSourceTimer`
/// runs on a `DispatchQueue` and is unaffected by RunLoop mode changes.
final class SystemClock: ClockProtocol {
    func schedule(interval: TimeInterval, action: @escaping () -> Void) -> AnyCancellable {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { action() }
        timer.resume()

        return AnyCancellable {
            timer.cancel()
        }
    }

    func now() -> Date {
        Date()
    }
}
