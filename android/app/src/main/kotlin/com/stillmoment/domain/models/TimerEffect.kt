package com.stillmoment.domain.models

/**
 * Side effects that the timer reducer can produce.
 *
 * These effects are returned by the reducer alongside the new state.
 * The ViewModel's effect handler executes them, keeping the reducer pure.
 *
 * Uses Android conventions for foreground service operations.
 */
sealed class TimerEffect {
    // MARK: - Foreground Service Effects

    /** Start foreground service with background audio */
    data class StartForegroundService(val soundId: String) : TimerEffect()

    /** Stop foreground service */
    data object StopForegroundService : TimerEffect()

    // MARK: - Sound Effects

    /** Play the start gong (meditation begins) */
    data object PlayStartGong : TimerEffect()

    /** Play an interval gong */
    data object PlayIntervalGong : TimerEffect()

    /** Play the completion sound (meditation ends) */
    data object PlayCompletionSound : TimerEffect()

    // MARK: - Timer Repository Effects

    /** Start the timer with given duration */
    data class StartTimer(val durationMinutes: Int) : TimerEffect()

    /** Pause the timer */
    data object PauseTimer : TimerEffect()

    /** Resume the timer */
    data object ResumeTimer : TimerEffect()

    /** Reset the timer */
    data object ResetTimer : TimerEffect()

    // MARK: - Persistence Effects

    /** Save settings to DataStore */
    data class SaveSettings(val settings: MeditationSettings) : TimerEffect()
}
