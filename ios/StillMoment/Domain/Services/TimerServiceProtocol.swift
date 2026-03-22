//
//  TimerServiceProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Timer Management
//

import Combine
import Foundation

/// Protocol defining timer service behavior
protocol TimerServiceProtocol {
    /// Publisher that emits timer updates and domain events every second.
    /// Events express what happened during the tick (e.g., preparation completed, interval gong due).
    var timerPublisher: AnyPublisher<(MeditationTimer, [TimerEvent]), Never> { get }

    /// Starts the timer with given duration
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes (1-60)
    ///   - preparationTimeSeconds: Duration of preparation phase in seconds (0 to skip)
    ///   - intervalSettings: Optional interval gong configuration. Pass `nil` when interval gongs are disabled.
    func start(durationMinutes: Int, preparationTimeSeconds: Int, intervalSettings: IntervalSettings?)

    /// Resets the timer to initial state
    func reset()

    /// Stops and cleans up the timer
    func stop()

    /// Begins the attunement phase, transitioning the timer from .startGong to .attunement.
    /// Called when the start gong finishes and an attunement is configured.
    /// Keeps the domain timer in sync with the display state so that periodic ticks
    /// deliver .attunement state (not stale .startGong state).
    func beginAttunementPhase()

    /// Ends the attunement phase, transitioning the timer from .attunement to .running.
    /// Called when the attunement audio finishes playing (event-driven).
    func endAttunementPhase()

    /// Transitions the timer from .startGong to .running (no attunement path).
    /// Called when the start gong finishes and no attunement is configured.
    func beginRunningPhase()
}
