//
//  LongPressAccelerator.swift
//  Still Moment
//
//  Presentation Layer - Long-Press-Beschleunigung fuer +/- Buttons am
//  Atemkreis-Picker (shared-086).
//
//  Spec: Beim Halten sofort ein Tick (Initial-Bump), nach 320 ms Delay
//  startet ein Auto-Repeat alle 80 ms. Beim Loslassen sauber aufraeumen,
//  damit kein Tick-Leak entsteht.
//

import Combine
import Foundation

/// Plant verzoegerte und wiederholte Arbeit. Trennt die Zeit-Mechanik von der
/// Logik, damit der Accelerator ohne echte Wartezeit testbar ist.
protocol LongPressSchedulerProtocol {
    func schedule(after delay: TimeInterval, _ work: @escaping () -> Void) -> AnyCancellable
    func scheduleRepeating(every interval: TimeInterval, _ work: @escaping () -> Void) -> AnyCancellable
}

/// Produktions-Scheduler: `DispatchQueue.main.asyncAfter` plus `Timer.publish`.
struct DispatchLongPressScheduler: LongPressSchedulerProtocol {
    static let shared = DispatchLongPressScheduler()

    func schedule(after delay: TimeInterval, _ work: @escaping () -> Void) -> AnyCancellable {
        let workItem = DispatchWorkItem(block: work)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return AnyCancellable { workItem.cancel() }
    }

    func scheduleRepeating(every interval: TimeInterval, _ work: @escaping () -> Void) -> AnyCancellable {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in work() }
    }
}

/// Beim ersten `start()` feuert die Action sofort, danach beginnt nach
/// `initialDelay` ein Auto-Repeat im Abstand `repeatInterval`. `stop()`
/// raeumt beide Subscriptions ab — auch im deinit, falls der View
/// vor einem Release-Event verschwindet.
final class LongPressAccelerator {
    typealias Action = () -> Void

    init(
        initialDelay: TimeInterval = 0.32,
        repeatInterval: TimeInterval = 0.08,
        scheduler: LongPressSchedulerProtocol = DispatchLongPressScheduler.shared,
        action: @escaping Action
    ) {
        self.initialDelay = initialDelay
        self.repeatInterval = repeatInterval
        self.scheduler = scheduler
        self.action = action
    }

    deinit {
        self.initialDelayCancellable?.cancel()
        self.repeatingCancellable?.cancel()
    }

    func start() {
        self.stop()
        self.action()
        self.initialDelayCancellable = self.scheduler.schedule(after: self.initialDelay) { [weak self] in
            guard let self
            else { return }
            self.repeatingCancellable = self.scheduler.scheduleRepeating(every: self.repeatInterval) { [weak self] in
                self?.action()
            }
        }
    }

    func stop() {
        self.initialDelayCancellable?.cancel()
        self.initialDelayCancellable = nil
        self.repeatingCancellable?.cancel()
        self.repeatingCancellable = nil
    }

    private let initialDelay: TimeInterval
    private let repeatInterval: TimeInterval
    private let scheduler: LongPressSchedulerProtocol
    private let action: Action

    private var initialDelayCancellable: AnyCancellable?
    private var repeatingCancellable: AnyCancellable?
}
