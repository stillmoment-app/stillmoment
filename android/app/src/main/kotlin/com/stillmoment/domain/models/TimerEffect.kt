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
    data class StartForegroundService(
        val soundId: String,
        val soundVolume: Float,
        val gongSoundId: String,
        val gongVolume: Float
    ) : TimerEffect()

    /** Stop foreground service */
    data object StopForegroundService : TimerEffect()

    // MARK: - Sound Effects

    /** Play the start gong (meditation begins) */
    data class PlayStartGong(val gongSoundId: String, val gongVolume: Float) : TimerEffect()

    /** Play an interval gong with configurable sound */
    data class PlayIntervalGong(val gongSoundId: String, val gongVolume: Float) : TimerEffect()

    /** Play the completion sound (meditation ends) */
    data class PlayCompletionSound(val gongSoundId: String, val gongVolume: Float) : TimerEffect()

    // MARK: - Introduction Effects

    /** Play introduction audio (after start gong, before silent meditation) */
    data class PlayIntroduction(val introductionId: String) : TimerEffect()

    /** Stop introduction audio (on reset or timer completed during introduction) */
    data object StopIntroduction : TimerEffect()

    /** Signal the timer repository to start the introduction phase (sync timer model state) */
    data object StartIntroductionPhase : TimerEffect()

    /** Signal the timer repository to end the introduction phase */
    data object EndIntroductionPhase : TimerEffect()

    // MARK: - Background Audio Effects

    /** Start background audio (ambient sound) — only when entering Running state */
    data class StartBackgroundAudio(val soundId: String, val soundVolume: Float) : TimerEffect()

    // MARK: - Timer Repository Effects

    /** Start the timer with given duration, preparation time, and optional introduction duration */
    data class StartTimer(
        val durationMinutes: Int,
        val preparationTimeSeconds: Int = 15,
        val introductionDurationSeconds: Int = 0
    ) : TimerEffect()

    /** Reset the timer */
    data object ResetTimer : TimerEffect()

    /** Transitions timer from StartGong to Running state (no introduction path) */
    data object TransitionToRunning : TimerEffect()

    /** Transitions timer from EndGong to Completed state */
    data object TransitionToCompleted : TimerEffect()

    // MARK: - Persistence Effects

    /** Save settings to DataStore */
    data class SaveSettings(val settings: MeditationSettings) : TimerEffect()
}
