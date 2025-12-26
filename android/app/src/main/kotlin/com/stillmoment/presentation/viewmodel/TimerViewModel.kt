package com.stillmoment.presentation.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.R
import com.stillmoment.data.repositories.TimerRepositoryImpl
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerState
import com.stillmoment.domain.repositories.SettingsRepository
import com.stillmoment.domain.services.TimerReducer
import com.stillmoment.infrastructure.audio.TimerForegroundService
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * UI State for the Timer Screen.
 *
 * Combines TimerDisplayState (pure timer logic) with UI-specific fields.
 */
data class TimerUiState(
    /** Timer display state (managed by reducer) */
    val displayState: TimerDisplayState = TimerDisplayState.Initial,
    /** Meditation settings */
    val settings: MeditationSettings = MeditationSettings.Default,
    /** Error message to show */
    val errorMessage: String? = null,
    /** Whether settings sheet is visible */
    val showSettings: Boolean = false
) {
    // Convenience accessors delegating to displayState
    val timerState: TimerState get() = displayState.timerState
    val selectedMinutes: Int get() = displayState.selectedMinutes
    val remainingSeconds: Int get() = displayState.remainingSeconds
    val totalSeconds: Int get() = displayState.totalSeconds
    val progress: Float get() = displayState.progress
    val countdownSeconds: Int get() = displayState.countdownSeconds
    val currentAffirmationIndex: Int get() = displayState.currentAffirmationIndex

    // Computed properties from displayState
    val isCountdown: Boolean get() = displayState.isCountdown
    val canStart: Boolean get() = displayState.canStart
    val canPause: Boolean get() = displayState.canPause
    val canResume: Boolean get() = displayState.canResume
    val canReset: Boolean get() = displayState.canReset
    val formattedTime: String get() = displayState.formattedTime
}

/**
 * ViewModel managing timer state and user interactions.
 *
 * Uses Unidirectional Data Flow (UDF) with TimerReducer for pure state transitions
 * and effect handling for side effects (audio, persistence, foreground service).
 */
@HiltViewModel
class TimerViewModel
@Inject
constructor(
    application: Application,
    private val settingsRepository: SettingsRepository,
    private val timerRepository: TimerRepositoryImpl
) : AndroidViewModel(application) {
    private val _uiState = MutableStateFlow(TimerUiState())
    val uiState: StateFlow<TimerUiState> = _uiState.asStateFlow()

    private var timerJob: Job? = null
    private var previousState: TimerState = TimerState.Idle

    init {
        loadSettings()
    }

    // MARK: - Action Dispatch (Unidirectional Data Flow)

    /**
     * Dispatches an action through the reducer and handles resulting effects.
     */
    private fun dispatch(action: TimerAction) {
        val currentState = _uiState.value
        val (newDisplayState, effects) =
            TimerReducer.reduce(
                currentState.displayState,
                action,
                currentState.settings
            )

        // Update state
        _uiState.update { it.copy(displayState = newDisplayState) }

        // Handle effects
        effects.forEach { handleEffect(it) }
    }

    /**
     * Handles side effects produced by the reducer.
     */
    private fun handleEffect(effect: TimerEffect) {
        when (effect) {
            is TimerEffect.StartForegroundService -> {
                TimerForegroundService.startService(getApplication(), effect.soundId)
            }
            is TimerEffect.StopForegroundService -> {
                TimerForegroundService.stopService(getApplication())
            }
            is TimerEffect.PlayStartGong -> {
                TimerForegroundService.playGong(getApplication())
            }
            is TimerEffect.PlayIntervalGong -> {
                TimerForegroundService.playIntervalGong(getApplication())
            }
            is TimerEffect.PlayCompletionSound -> {
                TimerForegroundService.playGong(getApplication())
            }
            is TimerEffect.StartTimer -> {
                viewModelScope.launch {
                    timerRepository.start(effect.durationMinutes)
                }
                previousState = TimerState.Idle
                startTimerLoop()
            }
            is TimerEffect.PauseTimer -> {
                viewModelScope.launch {
                    timerRepository.pause()
                }
                timerJob?.cancel()
            }
            is TimerEffect.ResumeTimer -> {
                viewModelScope.launch {
                    timerRepository.resume()
                }
                startTimerLoop()
            }
            is TimerEffect.PauseBackgroundAudio -> {
                TimerForegroundService.pauseAudio(getApplication())
            }
            is TimerEffect.ResumeBackgroundAudio -> {
                TimerForegroundService.resumeAudio(getApplication())
            }
            is TimerEffect.ResetTimer -> {
                timerJob?.cancel()
                previousState = TimerState.Idle
                viewModelScope.launch {
                    timerRepository.reset()
                }
            }
            is TimerEffect.SaveSettings -> {
                viewModelScope.launch {
                    settingsRepository.updateSettings(effect.settings)
                }
            }
        }
    }

    // MARK: - Public Methods (User Actions)

    fun setSelectedMinutes(minutes: Int) {
        dispatch(TimerAction.SelectDuration(minutes))
        // Also update settings for persistence
        _uiState.update {
            it.copy(settings = it.settings.withDurationMinutes(minutes))
        }
        saveSettings()
    }

    fun startTimer() {
        dispatch(TimerAction.StartPressed)
    }

    fun pauseTimer() {
        dispatch(TimerAction.PausePressed)
    }

    fun resumeTimer() {
        dispatch(TimerAction.ResumePressed)
    }

    fun resetTimer() {
        dispatch(TimerAction.ResetPressed)
    }

    fun showSettings() {
        _uiState.update { it.copy(showSettings = true) }
    }

    fun hideSettings() {
        _uiState.update { it.copy(showSettings = false) }
    }

    fun updateSettings(settings: MeditationSettings) {
        _uiState.update { it.copy(settings = settings) }
        saveSettings()
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    // MARK: - Affirmation Getters

    fun getCurrentCountdownAffirmation(): String {
        val index = _uiState.value.currentAffirmationIndex % COUNTDOWN_AFFIRMATION_COUNT
        val resourceId =
            when (index) {
                0 -> R.string.affirmation_countdown_1
                1 -> R.string.affirmation_countdown_2
                2 -> R.string.affirmation_countdown_3
                else -> R.string.affirmation_countdown_4
            }
        return getApplication<Application>().getString(resourceId)
    }

    fun getCurrentRunningAffirmation(): String {
        val index = _uiState.value.currentAffirmationIndex % RUNNING_AFFIRMATION_COUNT
        val resourceId =
            when (index) {
                0 -> R.string.affirmation_running_1
                1 -> R.string.affirmation_running_2
                2 -> R.string.affirmation_running_3
                3 -> R.string.affirmation_running_4
                else -> R.string.affirmation_running_5
            }
        return getApplication<Application>().getString(resourceId)
    }

    // MARK: - Private Methods

    private fun startTimerLoop() {
        timerJob?.cancel()
        timerJob =
            viewModelScope.launch {
                while (true) {
                    delay(1000L)

                    // Tick via repository (Single Source of Truth)
                    val updatedTimer = timerRepository.tick() ?: break

                    // Dispatch tick action to update display state
                    dispatch(
                        TimerAction.Tick(
                            remainingSeconds = updatedTimer.remainingSeconds,
                            totalSeconds = updatedTimer.totalSeconds,
                            countdownSeconds = updatedTimer.countdownSeconds,
                            progress = updatedTimer.progress,
                            state = updatedTimer.state
                        )
                    )

                    // Handle state transitions
                    handleStateTransition(previousState, updatedTimer.state)
                    previousState = updatedTimer.state

                    // Check for completion FIRST (before loop exit check)
                    if (updatedTimer.isCompleted) {
                        onTimerCompleted()
                        break
                    }

                    // Only continue loop if running or countdown
                    if (updatedTimer.state != TimerState.Running && updatedTimer.state != TimerState.Countdown) break

                    // Check for interval gong
                    checkIntervalGong(updatedTimer)
                }
            }
    }

    private fun handleStateTransition(oldState: TimerState, newState: TimerState) {
        // Countdown → Running: Dispatch countdown finished action
        if (oldState == TimerState.Countdown && newState == TimerState.Running) {
            dispatch(TimerAction.CountdownFinished)
        }
    }

    private fun onTimerCompleted() {
        timerJob?.cancel()
        dispatch(TimerAction.TimerCompleted)

        // Stop foreground service after a short delay to let gong play
        viewModelScope.launch {
            delay(3000L)
            TimerForegroundService.stopService(getApplication())
        }
    }

    private fun checkIntervalGong(timer: MeditationTimer) {
        val settings = _uiState.value.settings
        if (!settings.intervalGongsEnabled) return

        if (timer.shouldPlayIntervalGong(settings.intervalMinutes)) {
            timerRepository.markIntervalGongPlayed()
            dispatch(TimerAction.IntervalGongTriggered)
            // Mark as played for next interval
            dispatch(TimerAction.IntervalGongPlayed)
        }
    }

    private fun loadSettings() {
        viewModelScope.launch {
            settingsRepository.settingsFlow.collect { settings ->
                _uiState.update { state ->
                    val newDisplayState =
                        if (state.timerState == TimerState.Idle) {
                            state.displayState.copy(selectedMinutes = settings.durationMinutes)
                        } else {
                            state.displayState
                        }
                    state.copy(
                        displayState = newDisplayState,
                        settings = settings
                    )
                }
            }
        }
    }

    private fun saveSettings() {
        viewModelScope.launch {
            settingsRepository.updateSettings(_uiState.value.settings)
        }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        // Don't stop service here - let it run if timer is active
    }

    companion object {
        private const val COUNTDOWN_AFFIRMATION_COUNT = 4
        private const val RUNNING_AFFIRMATION_COUNT = 5
    }
}
