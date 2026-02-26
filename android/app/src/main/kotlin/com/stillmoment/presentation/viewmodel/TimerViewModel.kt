package com.stillmoment.presentation.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.IntervalSettings
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerEvent
import com.stillmoment.domain.models.TimerState
import com.stillmoment.domain.repositories.SettingsRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.TimerForegroundServiceProtocol
import com.stillmoment.domain.services.TimerReducer
import dagger.hilt.android.lifecycle.HiltViewModel
import java.util.Locale
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
    val showSettingsHint: Boolean = false
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
    val formattedTime: String get() = timer?.formattedTime ?: formatDefaultTime()

    private fun formatDefaultTime(): String {
        return String.format(Locale.ROOT, "%02d:00", selectedMinutes)
    }
}

/**
 * ViewModel managing timer state and user interactions.
 *
 * Uses Unidirectional Data Flow (UDF) with TimerReducer for pure state transitions
 * and effect handling for side effects (audio, persistence, foreground service).
 *
 * Timer events (preparation completed, meditation completed, interval gong due) are
 * emitted by `MeditationTimer.tick()` as domain events instead of being detected
 * via previousState comparison.
 */
@Suppress("TooManyFunctions") // ViewModel naturally has many user-facing action methods
@HiltViewModel
class TimerViewModel
@Inject
constructor(
    application: Application,
    private val settingsRepository: SettingsRepository,
    private val timerRepository: TimerRepository,
    private val audioService: AudioServiceProtocol,
    private val foregroundService: TimerForegroundServiceProtocol
) : AndroidViewModel(application) {
    private val _uiState = MutableStateFlow(TimerUiState())
    val uiState: StateFlow<TimerUiState> = _uiState.asStateFlow()

    private var timerJob: Job? = null

    /** Stores duration before introduction auto-clamped, restored when introduction is disabled. */
    private var minutesBeforeIntroduction: Int? = null

    init {
        // Load initial settings synchronously (DataStore is fast)
        // This ensures the UI shows the saved duration immediately, like iOS with UserDefaults
        val initialSettings = runBlocking { settingsRepository.getSettings() }
        val hasSeenHint = runBlocking { settingsRepository.getHasSeenSettingsHint() }
        val initialMinutes = MeditationSettings.validateDuration(
            initialSettings.durationMinutes,
            initialSettings.introductionId
        )
        _uiState.value = TimerUiState(
            timer = null,
            selectedMinutes = initialMinutes,
            settings = initialSettings,
            showSettingsHint = !hasSeenHint
        )
        // Continue collecting for future changes (background sound changes, etc.)
        loadSettings()

        // Subscribe to audio completion flows
        viewModelScope.launch {
            audioService.gongCompletionFlow.collect {
                onGongCompleted()
            }
        }
        viewModelScope.launch {
            audioService.introductionCompletionFlow.collect {
                dispatch(TimerAction.IntroductionFinished)
            }
        }
    }

    // MARK: - Action Dispatch (Unidirectional Data Flow)

    /**
     * Dispatches an action through the reducer and handles resulting effects.
     */
    private fun dispatch(action: TimerAction) {
        val current = _uiState.value
        val effects = TimerReducer.reduce(
            action = action,
            timerState = current.timerState,
            selectedMinutes = current.selectedMinutes,
            settings = current.settings
        )
        effects.forEach { handleEffect(it) }
    }

    /**
     * Handles side effects produced by the reducer.
     */
    @Suppress("CyclomaticComplexMethod") // Effect handler covers all sealed class variants
    private fun handleEffect(effect: TimerEffect) {
        when (effect) {
            is TimerEffect.StartForegroundService -> {
                foregroundService.startService(
                    effect.soundId,
                    effect.soundVolume,
                    effect.gongSoundId,
                    effect.gongVolume
                )
            }
            is TimerEffect.StopForegroundService -> foregroundService.stopService()
            is TimerEffect.PlayStartGong -> foregroundService.playGong(effect.gongSoundId, effect.gongVolume)
            is TimerEffect.PlayIntervalGong -> {
                foregroundService.playIntervalGong(effect.gongSoundId, effect.gongVolume)
            }
            is TimerEffect.PlayCompletionSound -> foregroundService.playGong(effect.gongSoundId, effect.gongVolume)
            is TimerEffect.StartIntroductionPhase -> timerRepository.startIntroduction()
            is TimerEffect.PlayIntroduction -> foregroundService.playIntroduction(effect.introductionId)
            is TimerEffect.StopIntroduction -> foregroundService.stopIntroduction()
            is TimerEffect.EndIntroductionPhase -> timerRepository.endIntroduction()
            is TimerEffect.StartBackgroundAudio -> {
                foregroundService.updateBackgroundAudio(effect.soundId, effect.soundVolume)
            }
            is TimerEffect.StartTimer -> handleStartTimer(effect)
            is TimerEffect.ResetTimer -> handleResetTimer()
            is TimerEffect.TransitionToRunning -> handleTransitionToRunning()
            is TimerEffect.TransitionToCompleted -> handleTransitionToCompleted()
            is TimerEffect.SaveSettings ->
                viewModelScope.launch { settingsRepository.updateSettings(effect.settings) }
        }
    }

    private fun handleStartTimer(effect: TimerEffect.StartTimer) {
        viewModelScope.launch {
            val initialEvents = timerRepository.start(
                effect.durationMinutes,
                effect.preparationTimeSeconds,
                effect.introductionDurationSeconds
            )
            // Read the initialized timer directly — no tick, no decrement
            timerRepository.currentTimer?.let { initialTimer ->
                _uiState.update { it.copy(timer = initialTimer) }
            }
            processTimerEvents(initialEvents)
        }
        startTimerLoop()
    }

    private fun handleResetTimer() {
        timerJob?.cancel()
        viewModelScope.launch {
            timerRepository.reset()
            _uiState.update { it.copy(timer = null) }
        }
    }

    private fun handleTransitionToRunning() {
        timerRepository.startRunning()
        _uiState.update { state ->
            state.copy(timer = state.timer?.withState(TimerState.Running))
        }
    }

    private fun handleTransitionToCompleted() {
        timerRepository.completeTimer()
        _uiState.update { state ->
            state.copy(timer = state.timer?.withState(TimerState.Completed))
        }
    }

    // MARK: - Public Methods (User Actions)

    fun setSelectedMinutes(minutes: Int) {
        _uiState.update { state ->
            state.copy(
                selectedMinutes = MeditationSettings.validateDuration(minutes, state.settings.introductionId),
                settings = state.settings.withDurationMinutes(minutes)
            )
        }
        saveSettings()
    }

    fun startTimer() {
        _uiState.update { state ->
            state.copy(currentAffirmationIndex = (state.currentAffirmationIndex + 1) % AFFIRMATION_COUNT)
        }
        dispatch(TimerAction.StartPressed)
    }

    fun resetTimer() {
        dispatch(TimerAction.ResetPressed)
    }

    fun showSettings() {
        dismissSettingsHint()
        _uiState.update { it.copy(showSettings = true) }
    }

    /**
     * Dismisses the settings hint tooltip and marks it as seen.
     * Called on timeout or when user taps the settings icon.
     */
    fun dismissSettingsHint() {
        if (_uiState.value.showSettingsHint) {
            _uiState.update { it.copy(showSettingsHint = false) }
            viewModelScope.launch {
                settingsRepository.setHasSeenSettingsHint(true)
            }
        }
    }

    fun hideSettings() {
        stopGongPreview()
        stopBackgroundPreview()
        _uiState.update { it.copy(showSettings = false) }
    }

    /**
     * Play a gong sound preview. Automatically stops any previous preview.
     * Uses the current gong volume setting for preview playback.
     */
    fun playGongPreview(soundId: String) {
        audioService.playGongPreview(soundId, _uiState.value.settings.gongVolume)
    }

    /**
     * Play interval gong sound preview.
     * Uses the current interval gong sound and volume settings for preview playback.
     */
    fun playIntervalGongPreview() {
        val settings = _uiState.value.settings
        audioService.playIntervalGong(settings.intervalSoundId, settings.intervalGongVolume)
    }

    /**
     * Play a specific interval gong sound preview (e.g., when changing sound selection).
     */
    fun playIntervalGongPreview(soundId: String) {
        audioService.playIntervalGong(soundId, _uiState.value.settings.intervalGongVolume)
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
     * Uses the current volume setting from settings for preview playback.
     */
    fun playBackgroundPreview(soundId: String) {
        audioService.playBackgroundPreview(soundId, _uiState.value.settings.backgroundSoundVolume)
    }

    /**
     * Stop the current background preview.
     */
    fun stopBackgroundPreview() {
        audioService.stopBackgroundPreview()
    }

    fun updateSettings(settings: MeditationSettings) {
        val oldSettings = _uiState.value.settings
        var updatedSettings = settings

        // Track introduction changes for duration restoration
        if (oldSettings.introductionId == null && settings.introductionId != null) {
            // Introduction enabled — save pre-clamp duration if clamping occurred
            val minimum = MeditationSettings.minimumDuration(settings.introductionId)
            if (oldSettings.durationMinutes < minimum) {
                minutesBeforeIntroduction = oldSettings.durationMinutes
            }
        } else if (oldSettings.introductionId != null && settings.introductionId == null) {
            // Introduction disabled — restore pre-introduction duration
            minutesBeforeIntroduction?.let { restored ->
                updatedSettings = settings.copy(durationMinutes = restored)
                minutesBeforeIntroduction = null
            }
        }

        _uiState.update { it.copy(settings = updatedSettings) }
        // Sync selectedMinutes if idle
        if (_uiState.value.timerState == TimerState.Idle) {
            _uiState.update { it.copy(selectedMinutes = updatedSettings.durationMinutes) }
        }
        saveSettings()
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
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
     * Builds interval settings from current meditation settings.
     * Returns null when interval gongs are disabled (tick() skips interval detection).
     */
    private fun buildIntervalSettings(): IntervalSettings? {
        val settings = _uiState.value.settings
        if (!settings.intervalGongsEnabled) return null
        return IntervalSettings(
            intervalMinutes = settings.intervalMinutes,
            mode = settings.intervalMode
        )
    }

    /**
     * Processes a single timer tick. Returns true if loop should continue.
     *
     * Domain events from tick() are processed directly — no previousState comparison needed.
     */
    private fun processTimerTick(): Boolean {
        val (updatedTimer, events) = timerRepository.tick(buildIntervalSettings()) ?: return false

        // Update timer directly — no dispatch needed
        _uiState.update { it.copy(timer = updatedTimer) }

        // Process domain events emitted by tick()
        processTimerEvents(events)

        if (updatedTimer.isCompleted) return false

        val activeStates = setOf(
            TimerState.Preparation,
            TimerState.StartGong,
            TimerState.Introduction,
            TimerState.Running
        )
        return updatedTimer.state in activeStates
    }

    /**
     * Processes domain events from [MeditationTimer.tick] and dispatches corresponding actions.
     */
    private fun processTimerEvents(events: List<TimerEvent>) {
        for (event in events) {
            when (event) {
                TimerEvent.PreparationCompleted -> dispatch(TimerAction.PreparationFinished)
                TimerEvent.MeditationCompleted -> {
                    timerJob?.cancel()
                    dispatch(TimerAction.TimerCompleted)
                }
                TimerEvent.IntervalGongDue -> dispatch(TimerAction.IntervalGongTriggered)
            }
        }
    }

    /**
     * Handles gong audio completion callback.
     * Dispatches the appropriate action based on current timer state:
     * - StartGong -> StartGongFinished (start gong finished, proceed to next phase)
     * - EndGong -> EndGongFinished (completion gong finished, meditation complete)
     */
    private fun onGongCompleted() {
        when (_uiState.value.timerState) {
            TimerState.EndGong -> dispatch(TimerAction.EndGongFinished)
            else -> dispatch(TimerAction.StartGongFinished)
        }
    }

    private fun loadSettings() {
        viewModelScope.launch {
            settingsRepository.settingsFlow.collect { settings ->
                _uiState.update { state ->
                    val newMinutes = if (state.timerState == TimerState.Idle) {
                        settings.durationMinutes
                    } else {
                        state.selectedMinutes
                    }
                    state.copy(settings = settings, selectedMinutes = newMinutes)
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
        private const val AFFIRMATION_COUNT = 5
    }
}
