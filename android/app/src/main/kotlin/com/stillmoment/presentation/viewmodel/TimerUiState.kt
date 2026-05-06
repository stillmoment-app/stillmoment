package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.MeditationPhase
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.models.TimerState
import java.util.Locale

/**
 * UI State for the Timer Screen.
 *
 * Holds MeditationTimer directly and forwards computed properties.
 * No intermediate display state — the ViewModel holds MeditationTimer? directly.
 */
data class TimerUiState(
    /** Active meditation timer, null when idle */
    val timer: MeditationTimer? = null,
    /** Selected duration in minutes */
    val selectedMinutes: Int = MeditationSettings.DEFAULT_DURATION_MINUTES,
    /** Meditation settings */
    val settings: MeditationSettings = MeditationSettings.Default,
    /** Error message to show */
    val errorMessage: String? = null,
    /** Whether settings sheet is visible */
    val showSettings: Boolean = false,
    /** Current Praxis for configuration pills display */
    val currentPraxis: Praxis = Praxis.Default,
    /** Built-in background sounds from catalog */
    val builtInSounds: List<BackgroundSound> = emptyList(),
    /** Resolved background sound display name (built-in or custom) */
    val resolvedBackgroundSoundName: String? = null
) {
    // Convenience accessors delegating to timer
    val timerState: TimerState get() = timer?.state ?: TimerState.Idle
    val remainingSeconds: Int get() = timer?.remainingSeconds ?: 0
    val totalSeconds: Int get() = timer?.totalSeconds ?: 0
    val progress: Float get() = timer?.progress ?: 0f
    val remainingPreparationSeconds: Int get() = timer?.remainingPreparationSeconds ?: 0

    // Computed properties
    val isPreparation: Boolean get() = timer?.isPreparation ?: false
    val canStart: Boolean get() = timerState == TimerState.Idle && selectedMinutes > 0
    val canReset: Boolean get() = timer?.canReset ?: false

    /**
     * Visuelle Phase fuer den Atemkreis-Display: PreRoll waehrend der Vorbereitung,
     * Playing in allen anderen Zustaenden (Idle, StartGong, Running, EndGong, Completed).
     */
    val phase: MeditationPhase
        get() = if (isPreparation) MeditationPhase.PreRoll else MeditationPhase.Playing

    /**
     * Restzeit als "m:ss" (ohne fuehrende Null bei Minuten) fuer das Restzeit-Label
     * unter dem Atemkreis. Identisches Format wie im Player ([PlayerUiState.formattedRemainingMinutes]).
     */
    val formattedRemainingMinutes: String
        get() {
            val seconds = if (timer != null) remainingSeconds else selectedMinutes * SECONDS_PER_MINUTE
            val minutes = seconds / SECONDS_PER_MINUTE
            val remainder = seconds % SECONDS_PER_MINUTE
            return String.format(Locale.ROOT, "%d:%02d", minutes, remainder)
        }

    private companion object {
        private const val SECONDS_PER_MINUTE = 60
    }
}
