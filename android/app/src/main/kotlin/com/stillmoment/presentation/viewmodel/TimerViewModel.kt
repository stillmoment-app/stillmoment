package com.stillmoment.presentation.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.R
import com.stillmoment.data.repositories.TimerRepositoryImpl
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
 *
 * Uses TimerRepositoryImpl as Single Source of Truth for timer state.
 */
@HiltViewModel
class TimerViewModel @Inject constructor(
    application: Application,
    private val audioService: AudioService,
    private val settingsRepository: SettingsRepository,
    private val timerRepository: TimerRepositoryImpl
) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(TimerUiState())
    val uiState: StateFlow<TimerUiState> = _uiState.asStateFlow()

    private var timerJob: Job? = null
    private var previousState: TimerState = TimerState.Idle

    init {
        loadSettings()
        observeTimerFlow()
    }

    /**
     * Observes timer state changes from repository and updates UI state.
     */
    private fun observeTimerFlow() {
        viewModelScope.launch {
            timerRepository.timerFlow.collect { timer ->
                _uiState.update {
                    it.copy(
                        timerState = timer.state,
                        remainingSeconds = timer.remainingSeconds,
                        totalSeconds = timer.totalSeconds,
                        progress = timer.progress,
                        countdownSeconds = timer.countdownSeconds
                    )
                }
            }
        }
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

        // Start timer via repository
        viewModelScope.launch {
            timerRepository.start(minutes)
        }
        previousState = TimerState.Idle

        // Rotate affirmation (4 countdown, 5 running affirmations)
        val newIndex = (_uiState.value.currentAffirmationIndex + 1) % AFFIRMATION_COUNT
        _uiState.update { it.copy(currentAffirmationIndex = newIndex) }

        // Start foreground service with background audio
        val soundId = _uiState.value.settings.backgroundSoundId
        TimerForegroundService.startService(getApplication(), soundId)

        startTimerLoop()
    }

    fun pauseTimer() {
        viewModelScope.launch {
            timerRepository.pause()
        }
        timerJob?.cancel()
        // Note: Keep foreground service running to maintain background audio
    }

    fun resumeTimer() {
        viewModelScope.launch {
            timerRepository.resume()
        }
        startTimerLoop()
    }

    fun resetTimer() {
        timerJob?.cancel()
        previousState = TimerState.Idle

        viewModelScope.launch {
            timerRepository.reset()
        }

        // Stop foreground service and audio
        TimerForegroundService.stopService(getApplication())

        // Reset UI state immediately (timerFlow won't emit for null)
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
        val index = _uiState.value.currentAffirmationIndex % COUNTDOWN_AFFIRMATION_COUNT
        val resourceId = when (index) {
            0 -> R.string.affirmation_countdown_1
            1 -> R.string.affirmation_countdown_2
            2 -> R.string.affirmation_countdown_3
            else -> R.string.affirmation_countdown_4
        }
        return getApplication<Application>().getString(resourceId)
    }

    fun getCurrentRunningAffirmation(): String {
        val index = _uiState.value.currentAffirmationIndex % RUNNING_AFFIRMATION_COUNT
        val resourceId = when (index) {
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
        timerJob = viewModelScope.launch {
            while (true) {
                delay(1000L)

                // Tick via repository (Single Source of Truth)
                val updatedTimer = timerRepository.tick() ?: break
                if (updatedTimer.state != TimerState.Running && updatedTimer.state != TimerState.Countdown) break

                // UI state is updated via observeTimerFlow()

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
            timerRepository.markIntervalGongPlayed()
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
        private const val COUNTDOWN_AFFIRMATION_COUNT = 4
        private const val RUNNING_AFFIRMATION_COUNT = 5
        private const val AFFIRMATION_COUNT = 5 // max(COUNTDOWN, RUNNING)
    }
}
