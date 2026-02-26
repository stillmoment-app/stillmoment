package com.stillmoment.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * UI State for the Praxis Editor screen.
 *
 * Holds all editable fields of a Praxis configuration.
 * Each field maps directly to a Praxis property.
 */
data class PraxisEditorUiState(
    val isLoading: Boolean = true,
    val durationMinutes: Int = Praxis.DEFAULT_DURATION_MINUTES,
    val preparationTimeEnabled: Boolean = Praxis.DEFAULT_PREPARATION_TIME_ENABLED,
    val preparationTimeSeconds: Int = Praxis.DEFAULT_PREPARATION_TIME_SECONDS,
    val gongSoundId: String = Praxis.DEFAULT_GONG_SOUND_ID,
    val gongVolume: Float = Praxis.DEFAULT_GONG_VOLUME,
    val introductionId: String? = null,
    val intervalGongsEnabled: Boolean = false,
    val intervalMinutes: Int = Praxis.DEFAULT_INTERVAL_MINUTES,
    val intervalMode: IntervalMode = Praxis.DEFAULT_INTERVAL_MODE,
    val intervalSoundId: String = Praxis.DEFAULT_INTERVAL_SOUND_ID,
    val intervalGongVolume: Float = Praxis.DEFAULT_INTERVAL_GONG_VOLUME,
    val backgroundSoundId: String = Praxis.DEFAULT_BACKGROUND_SOUND_ID,
    val backgroundSoundVolume: Float = Praxis.DEFAULT_BACKGROUND_SOUND_VOLUME
)

/**
 * ViewModel for editing the current Praxis configuration.
 *
 * Manages editing fields, audio preview playback, and save operations.
 * Loads the current Praxis on init and exposes individual setter methods
 * that validate input using Praxis companion validation methods.
 */
@Suppress("TooManyFunctions") // Editor ViewModel naturally has one setter per field
@HiltViewModel
class PraxisEditorViewModel
@Inject
constructor(
    private val praxisRepository: PraxisRepository,
    private val audioService: AudioServiceProtocol
) : ViewModel() {
    private val _uiState = MutableStateFlow(PraxisEditorUiState())
    val uiState: StateFlow<PraxisEditorUiState> = _uiState.asStateFlow()

    /** Stored Praxis ID, used when saving back. */
    private var praxisId: String = ""

    init {
        viewModelScope.launch {
            val praxis = praxisRepository.load()
            praxisId = praxis.id
            _uiState.value = PraxisEditorUiState(
                isLoading = false,
                durationMinutes = praxis.durationMinutes,
                preparationTimeEnabled = praxis.preparationTimeEnabled,
                preparationTimeSeconds = praxis.preparationTimeSeconds,
                gongSoundId = praxis.gongSoundId,
                gongVolume = praxis.gongVolume,
                introductionId = praxis.introductionId,
                intervalGongsEnabled = praxis.intervalGongsEnabled,
                intervalMinutes = praxis.intervalMinutes,
                intervalMode = praxis.intervalMode,
                intervalSoundId = praxis.intervalSoundId,
                intervalGongVolume = praxis.intervalGongVolume,
                backgroundSoundId = praxis.backgroundSoundId,
                backgroundSoundVolume = praxis.backgroundSoundVolume
            )
        }
    }

    // MARK: - Setter Methods

    fun setDurationMinutes(minutes: Int) {
        _uiState.update { it.copy(durationMinutes = Praxis.validateDuration(minutes)) }
    }

    fun setPreparationEnabled(enabled: Boolean) {
        _uiState.update { it.copy(preparationTimeEnabled = enabled) }
    }

    fun setPreparationSeconds(seconds: Int) {
        _uiState.update { it.copy(preparationTimeSeconds = Praxis.validatePreparationTime(seconds)) }
    }

    fun setGongSoundId(soundId: String) {
        _uiState.update { it.copy(gongSoundId = soundId) }
    }

    fun setGongVolume(volume: Float) {
        _uiState.update { it.copy(gongVolume = Praxis.validateVolume(volume)) }
    }

    fun setIntroductionId(introductionId: String?) {
        _uiState.update { it.copy(introductionId = introductionId) }
    }

    fun setIntervalGongsEnabled(enabled: Boolean) {
        _uiState.update { it.copy(intervalGongsEnabled = enabled) }
    }

    fun setIntervalMinutes(minutes: Int) {
        _uiState.update { it.copy(intervalMinutes = Praxis.validateInterval(minutes)) }
    }

    fun setIntervalMode(mode: IntervalMode) {
        _uiState.update { it.copy(intervalMode = mode) }
    }

    fun setIntervalSoundId(soundId: String) {
        _uiState.update { it.copy(intervalSoundId = soundId) }
    }

    fun setIntervalGongVolume(volume: Float) {
        _uiState.update { it.copy(intervalGongVolume = Praxis.validateVolume(volume)) }
    }

    fun setBackgroundSoundId(soundId: String) {
        _uiState.update { it.copy(backgroundSoundId = soundId) }
    }

    fun setBackgroundSoundVolume(volume: Float) {
        _uiState.update { it.copy(backgroundSoundVolume = Praxis.validateVolume(volume)) }
    }

    // MARK: - Save

    /**
     * Creates a new Praxis from the current editor state, saves it via repository,
     * and returns the saved Praxis.
     */
    fun save(): Praxis {
        val state = _uiState.value
        val praxis = Praxis.create(
            id = praxisId,
            durationMinutes = state.durationMinutes,
            preparationTimeEnabled = state.preparationTimeEnabled,
            preparationTimeSeconds = state.preparationTimeSeconds,
            gongSoundId = state.gongSoundId,
            gongVolume = state.gongVolume,
            introductionId = state.introductionId,
            intervalGongsEnabled = state.intervalGongsEnabled,
            intervalMinutes = state.intervalMinutes,
            intervalMode = state.intervalMode,
            intervalSoundId = state.intervalSoundId,
            intervalGongVolume = state.intervalGongVolume,
            backgroundSoundId = state.backgroundSoundId,
            backgroundSoundVolume = state.backgroundSoundVolume
        )
        viewModelScope.launch {
            praxisRepository.save(praxis)
        }
        return praxis
    }

    // MARK: - Audio Preview

    /**
     * Plays a gong sound preview using the current gong volume.
     */
    fun playGongPreview(soundId: String) {
        audioService.playGongPreview(soundId, _uiState.value.gongVolume)
    }

    /**
     * Plays an interval gong preview using the current interval gong volume.
     */
    fun playIntervalGongPreview(soundId: String) {
        audioService.playIntervalGong(soundId, _uiState.value.intervalGongVolume)
    }

    /**
     * Plays a background sound preview using the current background volume.
     */
    fun playBackgroundPreview(soundId: String) {
        audioService.playBackgroundPreview(soundId, _uiState.value.backgroundSoundVolume)
    }

    /**
     * Stops all active audio previews (gong and background).
     */
    fun stopPreviews() {
        audioService.stopGongPreview()
        audioService.stopBackgroundPreview()
    }
}
