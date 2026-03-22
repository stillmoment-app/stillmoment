package com.stillmoment.domain.models

/**
 * Domain events emitted by [MeditationTimer.tick] to express what happened during a tick.
 *
 * These events replace the previous approach where the ViewModel had to compare
 * `previousState` to detect transitions. Now `tick()` directly communicates
 * what occurred, and the ViewModel processes events without indirection.
 *
 * Note: Attunement completion is NOT a TimerEvent. It is audio-callback-driven
 * (file finished), not tick-driven (countdown at 0).
 */
sealed class TimerEvent {
    /** Preparation countdown reached zero, transitioning to startGong phase. */
    data object PreparationCompleted : TimerEvent()

    /** Meditation timer reached zero, transitioning to endGong phase. */
    data object MeditationCompleted : TimerEvent()

    /** An interval gong is due at this tick. The timer has already marked lastIntervalGongAt internally. */
    data object IntervalGongDue : TimerEvent()
}
