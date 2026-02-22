//
//  TimerEvent.swift
//  Still Moment
//
//  Domain Model - Events emitted by MeditationTimer.tick()
//

import Foundation

/// Domain events emitted by `MeditationTimer.tick()` to express what happened during a tick.
///
/// These events replace the previous approach where the ViewModel had to compare
/// `previousState` to detect transitions. Now `tick()` directly communicates
/// what occurred, and the ViewModel processes events without indirection.
///
/// Note: `introductionCompleted` is NOT a TimerEvent. Introduction completion is
/// audio-callback-driven (file finished), not tick-driven (countdown at 0).
enum TimerEvent: Equatable {
    /// Preparation countdown reached zero, transitioning to startGong phase.
    /// ViewModel should dispatch `.preparationFinished` to trigger the start gong.
    case preparationCompleted

    /// Meditation timer reached zero, transitioning to endGong phase.
    /// ViewModel should dispatch `.timerCompleted` to trigger the completion gong.
    case meditationCompleted

    /// An interval gong is due at this tick.
    /// The timer has already marked `lastIntervalGongAt` internally.
    /// ViewModel should dispatch `.intervalGongTriggered` to play the gong sound.
    case intervalGongDue
}
