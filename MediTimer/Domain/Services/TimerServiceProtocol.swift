//
//  TimerServiceProtocol.swift
//  MediTimer
//
//  Domain Service Protocol - Timer Management
//

import Combine
import Foundation

/// Protocol defining timer service behavior
protocol TimerServiceProtocol {
    /// Publisher that emits timer updates every second
    var timerPublisher: AnyPublisher<MeditationTimer, Never> { get }

    /// Starts the timer with given duration
    /// - Parameter durationMinutes: Duration in minutes (1-60)
    func start(durationMinutes: Int)

    /// Pauses the currently running timer
    func pause()

    /// Resumes a paused timer
    func resume()

    /// Resets the timer to initial state
    func reset()

    /// Stops and cleans up the timer
    func stop()
}
