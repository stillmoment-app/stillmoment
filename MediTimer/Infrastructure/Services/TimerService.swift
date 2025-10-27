//
//  TimerService.swift
//  MediTimer
//
//  Infrastructure - Timer Service Implementation
//

import Foundation
import Combine
import OSLog

/// Concrete implementation of timer service using Combine
final class TimerService: TimerServiceProtocol {
    // MARK: - Properties

    private let timerSubject = CurrentValueSubject<MeditationTimer?, Never>(nil)
    private var systemTimer: AnyCancellable?
    private var currentTimer: MeditationTimer?

    var timerPublisher: AnyPublisher<MeditationTimer, Never> {
        timerSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    func start(durationMinutes: Int) {
        Logger.timer.info("Starting timer", metadata: ["duration": durationMinutes])
        stop() // Clean up any existing timer

        do {
            let newTimer = try MeditationTimer(durationMinutes: durationMinutes)
            currentTimer = newTimer.withState(.running)
            timerSubject.send(currentTimer)
            startSystemTimer()
            Logger.timer.info("Timer started successfully")
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
        currentTimer = timer.withState(.paused)
        timerSubject.send(currentTimer)
        stopSystemTimer()
    }

    func resume() {
        guard let timer = currentTimer, timer.state == .paused else {
            Logger.timer.warning("Attempted to resume timer in invalid state")
            return
        }

        Logger.timer.debug("Resuming timer")
        currentTimer = timer.withState(.running)
        timerSubject.send(currentTimer)
        startSystemTimer()
    }

    func reset() {
        guard let timer = currentTimer else {
            Logger.timer.warning("Attempted to reset when no timer exists")
            return
        }

        Logger.timer.debug("Resetting timer")
        stopSystemTimer()
        let resetTimer = timer.reset()
        currentTimer = resetTimer
        timerSubject.send(currentTimer)
    }

    func stop() {
        Logger.timer.debug("Stopping timer")
        stopSystemTimer()
        currentTimer = nil
        timerSubject.send(nil)
    }

    // MARK: - Private Methods

    private func startSystemTimer() {
        stopSystemTimer() // Ensure no duplicate timers

        systemTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopSystemTimer() {
        systemTimer?.cancel()
        systemTimer = nil
    }

    private func tick() {
        guard let timer = currentTimer, timer.state == .running else { return }

        let updatedTimer = timer.tick()
        currentTimer = updatedTimer
        timerSubject.send(updatedTimer)

        // Log every 10 seconds to avoid log spam
        if updatedTimer.remainingSeconds % 10 == 0 {
            Logger.timer.debug("Timer tick", metadata: ["remaining": updatedTimer.remainingSeconds])
        }

        // Stop system timer when completed
        if updatedTimer.state == .completed {
            Logger.timer.info("Timer completed")
            stopSystemTimer()
        }
    }

    // MARK: - Deinit

    deinit {
        stop()
    }
}
