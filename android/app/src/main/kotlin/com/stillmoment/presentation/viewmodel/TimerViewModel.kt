package com.stillmoment.presentation.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerState
import com.stillmoment.domain.repositories.SettingsRepository
import com.stillmoment.infrastructure.audio.AudioService
import com.stillmoment.infrastructure.audio.TimerForegroundService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for the Timer Screen.
 * Bundles all relevant state into a single data class.
 */
data class TimerUiState(
    val timerState: TimerState = TimerState.Idle,
    val selectedMinutes: Int = 10,
    val remainingSeconds: Int = 0,
    val totalSeconds: Int = 0,
    val progress: Float = 0f,
    val countdownSeconds: Int = 0,
    val currentAffirmationIndex: Int = 0,
    val settings: MeditationSettings = MeditationSettings.Default,
    val errorMessage: String? = null,
    val showSettings: Boolean = false
) {
    val isCountdown: Boolean get() = timerState == TimerState.Countdown
    val canStart: Boolean get() = timerState == TimerState.Idle && selectedMinutes > 0
    val canPause: Boolean get() = timerState == TimerState.Running
    val canResume: Boolean get() = timerState == TimerState.Paused
    val canReset: Boolean get() = timerState != TimerState.Idle

    val formattedTime: String
        get() = if (isCountdown) {
            "$countdownSeconds"
        } else {
            val minutes = remainingSeconds / 60
            val seconds = remainingSeconds % 60
            String.format("%02d:%02d", minutes, seconds)
        }
}

/**
 * ViewModel managing timer state and user interactions.
 * Mirrors iOS TimerViewModel functionality with audio integration.
 */
@HiltViewModel
class TimerViewModel @Inject constructor(
    application: Application,
    private val audioService: AudioService,
    private val settingsRepository: SettingsRepository
) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(TimerUiState())
    val uiState: StateFlow<TimerUiState> = _uiState.asStateFlow()

    private var timerJob: Job? = null
    private var currentTimer: MeditationTimer? = null
    private var previousState: TimerState = TimerState.Idle

    // Affirmations (localized strings would be injected in production)
    private val countdownAffirmations = listOf(
        "Find a comfortable position",
        "Take a deep breath",
        "Close your eyes gently",
        "Let go of all tension"
    )

    private val runningAffirmations = listOf(
        "Be present in this moment",
        "Breathe naturally and deeply",
        "Notice your thoughts, let them pass",
        "Feel the calm within you",
        "You are doing wonderfully"
    )

    init {
        loadSettings()
    }

    // MARK: - Public Methods

    fun setSelectedMinutes(minutes: Int) {
        val validMinutes = minutes.coerceIn(1, 60)
        _uiState.update {
            it.copy(
                selectedMinutes = validMinutes,
                settings = it.settings.copy(durationMinutes = validMinutes)
            )
        }
        saveSettings()
    }

    fun startTimer() {
        val minutes = _uiState.value.selectedMinutes
        if (minutes <= 0) return

        // Create timer with countdown
        val timer = MeditationTimer.create(
            durationMinutes = minutes,
            countdownDuration = DEFAULT_COUNTDOWN_DURATION
        ).startCountdown()

        currentTimer = timer
        previousState = TimerState.Idle

        // Rotate affirmation
        val newIndex = (_uiState.value.currentAffirmationIndex + 1) %
            maxOf(runningAffirmations.size, countdownAffirmations.size)

        _uiState.update {
            it.copy(
                timerState = timer.state,
                remainingSeconds = timer.remainingSeconds,
                totalSeconds = timer.totalSeconds,
                countdownSeconds = timer.countdownSeconds,
                currentAffirmationIndex = newIndex,
                progress = timer.progress
            )
        }

        // Start foreground service with background audio
        val soundId = _uiState.value.settings.backgroundSoundId
        TimerForegroundService.startService(getApplication(), soundId)

        startTimerLoop()
    }

    fun pauseTimer() {
        currentTimer = currentTimer?.withState(TimerState.Paused)
        _uiState.update { it.copy(timerState = TimerState.Paused) }
        timerJob?.cancel()
        // Note: Keep foreground service running to maintain background audio
    }

    fun resumeTimer() {
        currentTimer = currentTimer?.withState(TimerState.Running)
        _uiState.update { it.copy(timerState = TimerState.Running) }
        startTimerLoop()
    }

    fun resetTimer() {
        timerJob?.cancel()
        currentTimer = null
        previousState = TimerState.Idle

        // Stop foreground service and audio
        TimerForegroundService.stopService(getApplication())

        _uiState.update {
            it.copy(
                timerState = TimerState.Idle,
                remainingSeconds = 0,
                totalSeconds = 0,
                progress = 0f,
                countdownSeconds = 0
            )
        }
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
        val index = _uiState.value.currentAffirmationIndex % countdownAffirmations.size
        return countdownAffirmations[index]
    }

    fun getCurrentRunningAffirmation(): String {
        val index = _uiState.value.currentAffirmationIndex % runningAffirmations.size
        return runningAffirmations[index]
    }

    // MARK: - Private Methods

    private fun startTimerLoop() {
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (true) {
                delay(1000L)

                val timer = currentTimer ?: break
                if (timer.state != TimerState.Running && timer.state != TimerState.Countdown) break

                val updatedTimer = timer.tick()
                currentTimer = updatedTimer

                _uiState.update {
                    it.copy(
                        timerState = updatedTimer.state,
                        remainingSeconds = updatedTimer.remainingSeconds,
                        progress = updatedTimer.progress,
                        countdownSeconds = updatedTimer.countdownSeconds
                    )
                }

                // Handle state transitions for audio
                handleStateTransition(previousState, updatedTimer.state, updatedTimer)
                previousState = updatedTimer.state

                // Check for completion
                if (updatedTimer.isCompleted) {
                    onTimerCompleted()
                    break
                }

                // Check for interval gong
                checkIntervalGong(updatedTimer)
            }
        }
    }

    private fun handleStateTransition(
        oldState: TimerState,
        newState: TimerState,
        timer: MeditationTimer
    ) {
        // Countdown → Running: Play start gong
        if (oldState == TimerState.Countdown && newState == TimerState.Running) {
            TimerForegroundService.playGong(getApplication())
        }
    }

    private fun onTimerCompleted() {
        timerJob?.cancel()

        // Play completion gong
        TimerForegroundService.playGong(getApplication())

        // Stop foreground service after a short delay to let gong play
        viewModelScope.launch {
            delay(3000L) // Wait for gong to finish
            TimerForegroundService.stopService(getApplication())
        }
    }

    private fun checkIntervalGong(timer: MeditationTimer) {
        val settings = _uiState.value.settings
        if (!settings.intervalGongsEnabled) return

        if (timer.shouldPlayIntervalGong(settings.intervalMinutes)) {
            currentTimer = timer.markIntervalGongPlayed()
            TimerForegroundService.playIntervalGong(getApplication())
        }
    }

    private fun loadSettings() {
        viewModelScope.launch {
            settingsRepository.settingsFlow.collect { settings ->
                _uiState.update {
                    it.copy(
                        settings = settings,
                        selectedMinutes = if (it.timerState == TimerState.Idle) {
                            settings.durationMinutes
                        } else {
                            it.selectedMinutes
                        }
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
        private const val DEFAULT_COUNTDOWN_DURATION = 15
    }
}
