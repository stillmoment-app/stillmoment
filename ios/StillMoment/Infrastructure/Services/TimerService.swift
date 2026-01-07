//
//  TimerService.swift
//  Still Moment
//
//  Infrastructure - Timer Service Implementation
//

import Combine
import Foundation
import OSLog

/// Concrete implementation of timer service using Combine
final class TimerService: TimerServiceProtocol {
    // MARK: Lifecycle

    init() {}

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

    func start(durationMinutes: Int, preparationTimeSeconds: Int) {
        Logger.timer.info("Starting timer", metadata: [
            "duration": durationMinutes,
            "preparationTime": preparationTimeSeconds
        ])
        self.stop() // Clean up any existing timer

        do {
            let newTimer = try MeditationTimer(
                durationMinutes: durationMinutes,
                preparationTimeSeconds: preparationTimeSeconds
            )

            if preparationTimeSeconds > 0 {
                // Start with preparation phase
                self.currentTimer = newTimer.startPreparation()
                Logger.timer.info("Timer preparation started")
            } else {
                // Skip preparation (typically for tests or disabled preparation)
                self.currentTimer = newTimer.withState(.running)
                Logger.timer.info("Timer started directly (no preparation)")
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

    func markIntervalGongPlayed() {
        guard let timer = currentTimer else {
            Logger.timer.warning("Attempted to mark interval gong when no timer exists")
            return
        }

        Logger.timer.debug("Marking interval gong played", metadata: ["remaining": timer.remainingSeconds])
        let updatedTimer = timer.markIntervalGongPlayed()
        self.currentTimer = updatedTimer
        self.timerSubject.send(updatedTimer)
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

        // Only tick if in preparation or running state
        guard timer.state == .preparation || timer.state == .running else {
            return
        }

        let updatedTimer = timer.tick()
        self.currentTimer = updatedTimer
        self.timerSubject.send(updatedTimer)

        // Log preparation → running transition
        if timer.state == .preparation, updatedTimer.state == .running {
            Logger.timer.info("Preparation complete, starting meditation timer")
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
