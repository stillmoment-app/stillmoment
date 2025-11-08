//
//  TimerService.swift
//  MediTimer
//
//  Infrastructure - Timer Service Implementation
//

import Combine
import Foundation
import OSLog

/// Concrete implementation of timer service using Combine
final class TimerService: TimerServiceProtocol {
    // MARK: Lifecycle

    // MARK: - Deinit

    deinit {
        stop()
    }

    // MARK: Internal

    var timerPublisher: AnyPublisher<MeditationTimer, Never> {
        self.timerSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    func start(durationMinutes: Int) {
        Logger.timer.info("Starting timer", metadata: ["duration": durationMinutes])
        self.stop() // Clean up any existing timer

        do {
            let newTimer = try MeditationTimer(durationMinutes: durationMinutes)

            // Check if running in UI test mode
            let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")

            if isUITesting {
                // Skip countdown for faster, more reliable tests
                self.currentTimer = newTimer.withState(.running)
                Logger.timer.info("Timer started directly (UI Testing mode)")
            } else {
                // Start in countdown state (15 seconds) for normal use
                self.currentTimer = newTimer.startCountdown()
                Logger.timer.info("Timer countdown started")
            }

            self.timerSubject.send(self.currentTimer)
            self.startSystemTimer()
        } catch {
            Logger.timer.error("Failed to start timer", error: error, metadata: ["duration": durationMinutes])
        }
    }

    func pause() {
        guard let timer = currentTimer, timer.state == .running else {
            Logger.timer.warning("Attempted to pause timer in invalid state")
            return
        }

        Logger.timer.debug("Pausing timer")
        self.currentTimer = timer.withState(.paused)
        self.timerSubject.send(self.currentTimer)
        self.stopSystemTimer()
    }

    func resume() {
        guard let timer = currentTimer, timer.state == .paused else {
            Logger.timer.warning("Attempted to resume timer in invalid state")
            return
        }

        Logger.timer.debug("Resuming timer")
        self.currentTimer = timer.withState(.running)
        self.timerSubject.send(self.currentTimer)
        self.startSystemTimer()
    }

    func reset() {
        guard let timer = currentTimer else {
            Logger.timer.warning("Attempted to reset when no timer exists")
            return
        }

        Logger.timer.debug("Resetting timer")
        self.stopSystemTimer()
        let resetTimer = timer.reset()
        self.currentTimer = resetTimer
        self.timerSubject.send(self.currentTimer)
    }

    func stop() {
        Logger.timer.debug("Stopping timer")
        self.stopSystemTimer()
        self.currentTimer = nil
        self.timerSubject.send(nil)
    }

    // MARK: Private

    private let timerSubject = CurrentValueSubject<MeditationTimer?, Never>(nil)
    private var systemTimer: AnyCancellable?
    private var currentTimer: MeditationTimer?

    // MARK: - Private Methods

    private func startSystemTimer() {
        self.stopSystemTimer() // Ensure no duplicate timers

        self.systemTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopSystemTimer() {
        self.systemTimer?.cancel()
        self.systemTimer = nil
    }

    private func tick() {
        guard let timer = currentTimer else {
            return
        }

        // Only tick if in countdown or running state
        guard timer.state == .countdown || timer.state == .running else {
            return
        }

        let updatedTimer = timer.tick()
        self.currentTimer = updatedTimer
        self.timerSubject.send(updatedTimer)

        // Log countdown transitions
        if timer.state == .countdown, updatedTimer.state == .running {
            Logger.timer.info("Countdown complete, starting meditation timer")
        }

        // Log every 10 seconds to avoid log spam (only for running timer)
        if updatedTimer.state == .running, updatedTimer.remainingSeconds.isMultiple(of: 10) {
            Logger.timer.debug("Timer tick", metadata: ["remaining": updatedTimer.remainingSeconds])
        }

        // Stop system timer when completed
        if updatedTimer.state == .completed {
            Logger.timer.info("Timer completed")
            self.stopSystemTimer()
        }
    }
}
