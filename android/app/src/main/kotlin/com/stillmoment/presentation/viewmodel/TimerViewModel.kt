package com.stillmoment.presentation.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.IntervalSettings
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerEvent
import com.stillmoment.domain.models.TimerState
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.SoundscapeResolverProtocol
import com.stillmoment.domain.services.TimerForegroundServiceProtocol
import com.stillmoment.domain.services.TimerReducer
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
    private val timerRepository: TimerRepository,
    private val audioService: AudioServiceProtocol,
    private val foregroundService: TimerForegroundServiceProtocol,
    private val praxisRepository: PraxisRepository,
    private val soundCatalogRepository: SoundCatalogRepository,
    private val soundscapeResolver: SoundscapeResolverProtocol
) : AndroidViewModel(application) {
    private val _uiState = MutableStateFlow(TimerUiState())
    val uiState: StateFlow<TimerUiState> = _uiState.asStateFlow()

    private var timerJob: Job? = null

    /** Returns the display name for the background sound (built-in or custom), or null if silent. */
    private fun resolveBackgroundSoundName(praxis: Praxis): String? {
        return soundscapeResolver.resolve(praxis.backgroundSoundId)?.displayName
    }

    init {
        // Load initial settings and praxis synchronously (DataStore is fast)
        // This ensures the UI shows the saved duration immediately, like iOS with UserDefaults
        val initialPraxis = runBlocking { praxisRepository.load() }
        val initialSettings = initialPraxis.toMeditationSettings()
        _uiState.value = TimerUiState(
            timer = null,
            selectedMinutes = initialSettings.durationMinutes,
            settings = initialSettings,
            currentPraxis = initialPraxis,
            builtInSounds = soundCatalogRepository.getAllSounds(),
            resolvedBackgroundSoundName = resolveBackgroundSoundName(initialPraxis)
        )
        // Observe praxis changes and sync settings + pill labels
        observePraxis()

        // Subscribe to audio completion flows
        viewModelScope.launch {
            audioService.gongCompletionFlow.collect {
                onGongCompleted()
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
            settings = current.settings,
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
            is TimerEffect.StartBackgroundAudio -> {
                foregroundService.updateBackgroundAudio(effect.soundId, effect.soundVolume)
            }
            is TimerEffect.StartTimer -> handleStartTimer(effect)
            is TimerEffect.ResetTimer -> handleResetTimer()
            is TimerEffect.TransitionToRunning -> handleTransitionToRunning()
            is TimerEffect.TransitionToCompleted -> handleTransitionToCompleted()
            is TimerEffect.SaveSettings -> viewModelScope.launch {
                val currentPraxis = _uiState.value.currentPraxis
                praxisRepository.save(
                    currentPraxis.withDurationMinutes(effect.settings.durationMinutes)
                )
            }
        }
    }

    private fun handleStartTimer(effect: TimerEffect.StartTimer) {
        viewModelScope.launch {
            val initialEvents = timerRepository.start(
                effect.durationMinutes,
                effect.preparationTimeSeconds
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
            val updatedSettings = state.settings.withDurationMinutes(minutes)
            state.copy(
                selectedMinutes = updatedSettings.durationMinutes,
                settings = updatedSettings
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
        _uiState.update { it.copy(showSettings = true) }
    }

    fun hideSettings() {
        stopGongPreview()
        stopBackgroundPreview()
        _uiState.update { it.copy(showSettings = false) }
    }

    // MARK: - Audio Preview

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

    // MARK: - Settings Management

    fun updateSettings(settings: MeditationSettings) {
        _uiState.update { it.copy(settings = settings) }
        // Sync selectedMinutes if idle
        if (_uiState.value.timerState == TimerState.Idle) {
            _uiState.update { it.copy(selectedMinutes = settings.durationMinutes) }
        }
        saveSettings()
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    // MARK: - Timer Loop

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
            TimerState.Running
        )
        return updatedTimer.state in activeStates
    }

    /**
     * Processes domain events from [com.stillmoment.domain.models.MeditationTimer.tick] and
     * dispatches corresponding actions.
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

    // MARK: - Persistence

    private fun observePraxis() {
        viewModelScope.launch {
            praxisRepository.praxisFlow.collect { praxis ->
                val settings = praxis.toMeditationSettings()
                val bgName = resolveBackgroundSoundName(praxis)
                _uiState.update { state ->
                    val newMinutes = if (state.timerState == TimerState.Idle) {
                        settings.durationMinutes
                    } else {
                        state.selectedMinutes
                    }
                    state.copy(
                        settings = settings,
                        selectedMinutes = newMinutes,
                        currentPraxis = praxis,
                        resolvedBackgroundSoundName = bgName
                    )
                }
            }
        }
    }

    /**
     * Applies a just-saved Praxis directly to the UI state, bypassing the DataStore roundtrip.
     *
     * Called after PraxisEditor saves so the timer sees the new settings immediately,
     * without racing against the async DataStore write.
     */
    fun applyPraxisUpdate(praxis: Praxis) {
        val settings = praxis.toMeditationSettings()
        val bgName = resolveBackgroundSoundName(praxis)
        _uiState.update { state ->
            val newMinutes = if (state.timerState == TimerState.Idle) {
                settings.durationMinutes
            } else {
                state.selectedMinutes
            }
            state.copy(
                settings = settings,
                selectedMinutes = newMinutes,
                currentPraxis = praxis,
                resolvedBackgroundSoundName = bgName
            )
        }
    }

    private fun saveSettings() {
        viewModelScope.launch {
            val state = _uiState.value
            praxisRepository.save(
                Praxis.fromMeditationSettings(state.settings, state.currentPraxis.id)
            )
        }
    }

    // MARK: - Lifecycle

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        // Don't stop service here - let it run if timer is active
    }

    companion object {
        private const val AFFIRMATION_COUNT = 5
    }
}
