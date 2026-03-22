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

    init(clock: ClockProtocol = SystemClock()) {
        self.clock = clock
    }

    // MARK: - Deinit

    deinit {
        stop()
    }

    // MARK: Internal

    var timerPublisher: AnyPublisher<(MeditationTimer, [TimerEvent]), Never> {
        self.timerSubject.eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    func start(durationMinutes: Int, preparationTimeSeconds: Int, intervalSettings: IntervalSettings?) {
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

            self.intervalSettings = intervalSettings

            if preparationTimeSeconds > 0 {
                // Start with preparation phase
                self.currentTimer = newTimer.startPreparation()
                Logger.timer.info("Timer preparation started")
            } else {
                // Skip preparation, go directly to start gong
                self.currentTimer = newTimer.withState(.startGong)
                Logger.timer.info("Timer started directly with start gong (no preparation)")
            }

            if let timer = self.currentTimer {
                let initialEvents: [TimerEvent] = preparationTimeSeconds > 0 ? [] : [.preparationCompleted]
                self.timerSubject.send((timer, initialEvents))
            }
            self.startSystemTimer()
        } catch {
            Logger.timer.error("Failed to start timer", error: error, metadata: ["duration": durationMinutes])
        }
    }

    func reset() {
        guard let timer = self.currentTimer else {
            Logger.timer.warning("Attempted to reset when no timer exists")
            return
        }

        Logger.timer.debug("Resetting timer")
        self.stopSystemTimer()
        let resetTimer = timer.reset()
        self.currentTimer = resetTimer
        self.timerSubject.send((resetTimer, []))
    }

    func stop() {
        Logger.timer.debug("Stopping timer")
        self.stopSystemTimer()
        self.currentTimer = nil
        self.intervalSettings = nil
    }

    func beginAttunementPhase() {
        guard let timer = self.currentTimer else {
            Logger.timer.warning("Attempted to begin attunement when no timer exists")
            return
        }

        Logger.timer.info("Beginning attunement phase", metadata: ["remaining": timer.remainingSeconds])
        let updatedTimer = timer.withState(.attunement)
        self.currentTimer = updatedTimer
        self.timerSubject.send((updatedTimer, []))
    }

    func endAttunementPhase() {
        guard let timer = self.currentTimer else {
            Logger.timer.warning("Attempted to end attunement when no timer exists")
            return
        }

        Logger.timer.info("Ending attunement phase", metadata: ["remaining": timer.remainingSeconds])
        let updatedTimer = timer.endAttunement()
        self.currentTimer = updatedTimer
        self.timerSubject.send((updatedTimer, []))
    }

    func beginRunningPhase() {
        guard let timer = self.currentTimer else {
            Logger.timer.warning("Attempted to begin running phase when no timer exists")
            return
        }

        Logger.timer.info("Beginning running phase (no attunement)", metadata: ["remaining": timer.remainingSeconds])
        let updatedTimer = timer.endAttunement()
        self.currentTimer = updatedTimer
        self.timerSubject.send((updatedTimer, []))
    }

    // MARK: Private

    private let clock: ClockProtocol
    private let timerSubject = PassthroughSubject<(MeditationTimer, [TimerEvent]), Never>()
    private var systemTimer: AnyCancellable?
    private var currentTimer: MeditationTimer?
    private var intervalSettings: IntervalSettings?

    // MARK: - Private Methods

    private func startSystemTimer() {
        self.stopSystemTimer() // Ensure no duplicate timers

        self.systemTimer = self.clock.schedule(interval: 1.0) { [weak self] in
            self?.tick()
        }
    }

    private func stopSystemTimer() {
        self.systemTimer?.cancel()
        self.systemTimer = nil
    }

    private func tick() {
        guard let timer = self.currentTimer else {
            return
        }

        // Only tick if in an active state
        guard timer.state == .preparation || timer.state == .startGong
            || timer.state == .attunement || timer.state == .running
        else {
            return
        }

        let (updatedTimer, events) = timer.tick(intervalSettings: self.intervalSettings)
        self.currentTimer = updatedTimer
        self.timerSubject.send((updatedTimer, events))

        // Log state transitions
        if timer.state == .preparation, updatedTimer.state == .startGong {
            Logger.timer.info("Preparation complete, playing start gong")
        }

        // Log every 10 seconds to avoid log spam (only for running/attunement/startGong timer)
        if updatedTimer.state == .running || updatedTimer.state == .attunement
            || updatedTimer.state == .startGong,
            updatedTimer.remainingSeconds.isMultiple(of: 10) {
            Logger.timer.debug("Timer tick", metadata: ["remaining": updatedTimer.remainingSeconds])
        }

        // Stop system timer when entering endGong (waiting for audio callback) or completed
        if updatedTimer.state == .endGong {
            Logger.timer.info("Timer reached zero, entering endGong phase")
            self.stopSystemTimer()
        } else if updatedTimer.state == .completed {
            Logger.timer.info("Timer completed")
            self.stopSystemTimer()
        }
    }
}
