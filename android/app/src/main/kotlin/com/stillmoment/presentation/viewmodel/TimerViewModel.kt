package com.stillmoment.presentation.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.R
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerState
import com.stillmoment.domain.repositories.SettingsRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.TimerReducer
import com.stillmoment.infrastructure.audio.AudioService
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
import kotlinx.coroutines.runBlocking

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
    val remainingPreparationSeconds: Int get() = displayState.remainingPreparationSeconds
    val currentAffirmationIndex: Int get() = displayState.currentAffirmationIndex

    // Computed properties from displayState
    val isPreparation: Boolean get() = displayState.isPreparation
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
@Suppress("TooManyFunctions") // ViewModel naturally has many user-facing action methods
@HiltViewModel
class TimerViewModel
@Inject
constructor(
    application: Application,
    private val settingsRepository: SettingsRepository,
    private val timerRepository: TimerRepository,
    private val audioService: AudioService
) : AndroidViewModel(application) {
    private val _uiState = MutableStateFlow(TimerUiState())
    val uiState: StateFlow<TimerUiState> = _uiState.asStateFlow()

    private var timerJob: Job? = null
    private var previousState: TimerState = TimerState.Idle

    init {
        // Load initial settings synchronously (DataStore is fast)
        // This ensures the UI shows the saved duration immediately, like iOS with UserDefaults
        val initialSettings = runBlocking { settingsRepository.getSettings() }
        _uiState.value = TimerUiState(
            displayState = TimerDisplayState.withDuration(initialSettings.durationMinutes),
            settings = initialSettings
        )
        // Continue collecting for future changes (background sound changes, etc.)
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
                TimerForegroundService.startService(getApplication(), effect.soundId, effect.gongSoundId)
            }
            is TimerEffect.StopForegroundService -> {
                TimerForegroundService.stopService(getApplication())
            }
            is TimerEffect.PlayStartGong -> {
                TimerForegroundService.playGong(getApplication(), effect.gongSoundId)
            }
            is TimerEffect.PlayIntervalGong -> {
                TimerForegroundService.playIntervalGong(getApplication())
            }
            is TimerEffect.PlayCompletionSound -> {
                TimerForegroundService.playGong(getApplication(), effect.gongSoundId)
            }
            is TimerEffect.StartTimer -> {
                viewModelScope.launch {
                    timerRepository.start(effect.durationMinutes, effect.preparationTimeSeconds)
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
        stopGongPreview()
        stopBackgroundPreview()
        _uiState.update { it.copy(showSettings = false) }
    }

    /**
     * Play a gong sound preview. Automatically stops any previous preview.
     */
    fun playGongPreview(soundId: String) {
        audioService.playGongPreview(soundId)
    }

    /**
     * Stop the current gong preview.
     */
    fun stopGongPreview() {
        audioService.stopGongPreview()
    }

    /**
     * Play a background sound preview. Automatically stops any previous preview (gong or background).
     * Plays for 3 seconds with fade-out.
     */
    fun playBackgroundPreview(soundId: String) {
        audioService.playBackgroundPreview(soundId, DEFAULT_PREVIEW_VOLUME)
    }

    /**
     * Stop the current background preview.
     */
    fun stopBackgroundPreview() {
        audioService.stopBackgroundPreview()
    }

    fun updateSettings(settings: MeditationSettings) {
        _uiState.update { it.copy(settings = settings) }
        saveSettings()
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    // MARK: - Affirmation Getters

    fun getCurrentPreparationAffirmation(): String {
        val index = _uiState.value.currentAffirmationIndex % PREPARATION_AFFIRMATION_COUNT
        return getApplication<Application>().getString(PREPARATION_AFFIRMATIONS[index])
    }

    fun getCurrentRunningAffirmation(): String {
        val index = _uiState.value.currentAffirmationIndex % RUNNING_AFFIRMATION_COUNT
        return getApplication<Application>().getString(RUNNING_AFFIRMATIONS[index])
    }

    // MARK: - Private Methods

    private fun startTimerLoop() {
        timerJob?.cancel()
        timerJob =
            viewModelScope.launch {
                var shouldContinue = true
                while (shouldContinue) {
                    delay(1000L)
                    shouldContinue = processTimerTick()
                }
            }
    }

    /**
     * Processes a single timer tick. Returns true if loop should continue.
     */
    private fun processTimerTick(): Boolean {
        val updatedTimer = timerRepository.tick() ?: return false

        // Dispatch tick action to update display state
        dispatch(
            TimerAction.Tick(
                remainingSeconds = updatedTimer.remainingSeconds,
                totalSeconds = updatedTimer.totalSeconds,
                remainingPreparationSeconds = updatedTimer.remainingPreparationSeconds,
                progress = updatedTimer.progress,
                state = updatedTimer.state
            )
        )

        // Handle state transitions
        handleStateTransition(previousState, updatedTimer.state)
        previousState = updatedTimer.state

        // Check for completion
        if (updatedTimer.isCompleted) {
            onTimerCompleted()
            return false
        }

        // Only continue loop if running or preparation
        if (updatedTimer.state != TimerState.Running && updatedTimer.state != TimerState.Preparation) {
            return false
        }

        // Check for interval gong
        checkIntervalGong(updatedTimer)
        return true
    }

    private fun handleStateTransition(oldState: TimerState, newState: TimerState) {
        // Preparation → Running: Dispatch preparation finished action
        if (oldState == TimerState.Preparation && newState == TimerState.Running) {
            dispatch(TimerAction.PreparationFinished)
        }
    }

    private fun onTimerCompleted() {
        timerJob?.cancel()
        dispatch(TimerAction.TimerCompleted)

        // Stop foreground service after a short delay to let gong play
        viewModelScope.launch {
            delay(COMPLETION_SOUND_DELAY_MS)
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
        private const val PREPARATION_AFFIRMATION_COUNT = 4
        private const val RUNNING_AFFIRMATION_COUNT = 5

        /** Delay before stopping foreground service to allow completion sound to play */
        private const val COMPLETION_SOUND_DELAY_MS = 3000L

        /** Default volume for background sound preview (0.0 to 1.0) */
        private const val DEFAULT_PREVIEW_VOLUME = 0.15f

        /** Affirmation resource IDs for preparation phase */
        private val PREPARATION_AFFIRMATIONS = intArrayOf(
            R.string.affirmation_countdown_1,
            R.string.affirmation_countdown_2,
            R.string.affirmation_countdown_3,
            R.string.affirmation_countdown_4
        )

        /** Affirmation resource IDs for running phase */
        private val RUNNING_AFFIRMATIONS = intArrayOf(
            R.string.affirmation_running_1,
            R.string.affirmation_running_2,
            R.string.affirmation_running_3,
            R.string.affirmation_running_4,
            R.string.affirmation_running_5
        )
    }
}
