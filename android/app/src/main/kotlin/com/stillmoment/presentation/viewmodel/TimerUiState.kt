package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.BackgroundSound
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
    /** Current affirmation index (rotates between sessions) */
    val currentAffirmationIndex: Int = 0,
    /** Meditation settings */
    val settings: MeditationSettings = MeditationSettings.Default,
    /** Error message to show */
    val errorMessage: String? = null,
    /** Whether settings sheet is visible */
    val showSettings: Boolean = false,
    /** Whether to show the settings hint tooltip (first-time onboarding) */
    val showSettingsHint: Boolean = false,
    /** Current Praxis for configuration pills display */
    val currentPraxis: Praxis = Praxis.Default,
    /** Built-in background sounds from catalog */
    val builtInSounds: List<BackgroundSound> = emptyList()
) {
    // Convenience accessors delegating to timer
    val timerState: TimerState get() = timer?.state ?: TimerState.Idle
    val remainingSeconds: Int get() = timer?.remainingSeconds ?: 0
    val totalSeconds: Int get() = timer?.totalSeconds ?: 0
    val progress: Float get() = timer?.progress ?: 0f
    val remainingPreparationSeconds: Int get() = timer?.remainingPreparationSeconds ?: 0

    // Computed properties
    val minimumDurationMinutes: Int get() = MeditationSettings.minimumDuration(settings.introductionId)
    val isPreparation: Boolean get() = timer?.isPreparation ?: false
    val canStart: Boolean get() = timerState == TimerState.Idle && selectedMinutes > 0
    val canReset: Boolean get() = timer?.canReset ?: false
    val formattedTime: String get() = timer?.formattedTime ?: formatDefaultTime()

    private fun formatDefaultTime(): String {
        return String.format(Locale.ROOT, "%02d:00", selectedMinutes)
    }
}
