package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.services.AttunementResolverProtocol
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.SoundscapeResolverProtocol
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
    val introductionEnabled: Boolean = false,
    val intervalGongsEnabled: Boolean = false,
    val intervalMinutes: Int = Praxis.DEFAULT_INTERVAL_MINUTES,
    val intervalMode: IntervalMode = Praxis.DEFAULT_INTERVAL_MODE,
    val intervalSoundId: String = Praxis.DEFAULT_INTERVAL_SOUND_ID,
    val intervalGongVolume: Float = Praxis.DEFAULT_INTERVAL_GONG_VOLUME,
    val backgroundSoundId: String = Praxis.DEFAULT_BACKGROUND_SOUND_ID,
    val backgroundSoundVolume: Float = Praxis.DEFAULT_BACKGROUND_SOUND_VOLUME,
    val customSoundscapes: List<CustomAudioFile> = emptyList(),
    val customAttunements: List<CustomAudioFile> = emptyList(),
    val customAudioError: String? = null,
    val builtInSounds: List<BackgroundSound> = emptyList(),
    /** Resolved introduction name (built-in or custom), null when no introduction set */
    val resolvedIntroductionName: String? = null,
    /** Resolved background sound name (built-in or custom) */
    val resolvedBackgroundSoundName: String? = null
) {
    /**
     * Applies a loaded Praxis and its resolved names to this state,
     * preserving fields not owned by Praxis (custom audio lists, errors).
     */
    fun withPraxis(
        praxis: Praxis,
        builtInSounds: List<BackgroundSound>,
        resolvedIntroductionName: String?,
        resolvedBackgroundSoundName: String?
    ): PraxisEditorUiState = copy(
        isLoading = false,
        durationMinutes = praxis.durationMinutes,
        preparationTimeEnabled = praxis.preparationTimeEnabled,
        preparationTimeSeconds = praxis.preparationTimeSeconds,
        gongSoundId = praxis.gongSoundId,
        gongVolume = praxis.gongVolume,
        introductionId = praxis.introductionId,
        introductionEnabled = praxis.introductionEnabled,
        intervalGongsEnabled = praxis.intervalGongsEnabled,
        intervalMinutes = praxis.intervalMinutes,
        intervalMode = praxis.intervalMode,
        intervalSoundId = praxis.intervalSoundId,
        intervalGongVolume = praxis.intervalGongVolume,
        backgroundSoundId = praxis.backgroundSoundId,
        backgroundSoundVolume = praxis.backgroundSoundVolume,
        builtInSounds = builtInSounds,
        resolvedIntroductionName = resolvedIntroductionName,
        resolvedBackgroundSoundName = resolvedBackgroundSoundName
    )
}

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
    private val audioService: AudioServiceProtocol,
    private val customAudioRepository: CustomAudioRepository,
    private val soundCatalogRepository: SoundCatalogRepository,
    private val attunementResolver: AttunementResolverProtocol,
    private val soundscapeResolver: SoundscapeResolverProtocol
) : ViewModel() {
    private val _uiState = MutableStateFlow(PraxisEditorUiState())
    val uiState: StateFlow<PraxisEditorUiState> = _uiState.asStateFlow()

    /** Stored Praxis ID, used when saving back. */
    private var praxisId: String = ""

    init {
        viewModelScope.launch {
            val praxis = praxisRepository.load()
            praxisId = praxis.id

            val introName = praxis.introductionId?.let { id ->
                attunementResolver.resolve(id)?.displayName
            }
            val bgName = soundscapeResolver.resolve(praxis.backgroundSoundId)?.displayName

            _uiState.update { current ->
                current.withPraxis(
                    praxis = praxis,
                    builtInSounds = soundCatalogRepository.getAllSounds(),
                    resolvedIntroductionName = introName,
                    resolvedBackgroundSoundName = bgName
                )
            }

            loadCustomAudio()
        }
    }

    // MARK: - Setter Methods

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
        resolveIntroductionName(introductionId)
    }

    fun setIntroductionEnabled(enabled: Boolean) {
        val available = Introduction.availableForCurrentLanguage()
        _uiState.update { state ->
            if (enabled && state.introductionId == null) {
                state.copy(introductionEnabled = true, introductionId = available.firstOrNull()?.id)
            } else {
                state.copy(introductionEnabled = enabled)
            }
        }
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
        resolveBackgroundSoundName(soundId)
    }

    fun setBackgroundSoundVolume(volume: Float) {
        _uiState.update { it.copy(backgroundSoundVolume = Praxis.validateVolume(volume)) }
    }

    // MARK: - Audio Name Resolution

    private fun resolveIntroductionName(introductionId: String?) {
        viewModelScope.launch {
            val name = introductionId?.let { attunementResolver.resolve(it)?.displayName }
            _uiState.update { it.copy(resolvedIntroductionName = name) }
        }
    }

    private fun resolveBackgroundSoundName(soundId: String) {
        viewModelScope.launch {
            val name = soundscapeResolver.resolve(soundId)?.displayName
            _uiState.update { it.copy(resolvedBackgroundSoundName = name) }
        }
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
            introductionEnabled = state.introductionEnabled,
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
     * Plays an introduction audio preview using the current introduction.
     */
    fun playIntroductionPreview(introductionId: String) {
        audioService.playIntroductionPreview(introductionId)
    }

    /**
     * Stops all active audio previews (gong, background, and introduction).
     */
    fun stopPreviews() {
        audioService.stopGongPreview()
        audioService.stopBackgroundPreview()
        audioService.stopIntroductionPreview()
    }

    // MARK: - Custom Audio

    /**
     * Imports a custom audio file from the given URI.
     * Sets customAudioError on failure.
     */
    fun importCustomAudio(uri: Uri, type: CustomAudioType) {
        viewModelScope.launch {
            val result = customAudioRepository.importFile(uri, type)
            result.fold(
                onSuccess = { loadCustomAudio() },
                onFailure = { error ->
                    _uiState.update { it.copy(customAudioError = error.message) }
                }
            )
        }
    }

    /**
     * Deletes a custom audio file by ID.
     * If the current praxis uses the deleted file, resets to the appropriate default.
     */
    fun deleteCustomAudio(id: String) {
        viewModelScope.launch {
            val current = _uiState.value
            customAudioRepository.delete(id)
            loadCustomAudio()

            // Reset backgroundSoundId if it references the deleted file
            if (current.backgroundSoundId == id) {
                _uiState.update { it.copy(backgroundSoundId = Praxis.DEFAULT_BACKGROUND_SOUND_ID) }
                save()
            }

            // Reset introductionId and disable if it references the deleted file
            if (current.introductionId == id) {
                _uiState.update { it.copy(introductionId = null, introductionEnabled = false) }
                save()
            }
        }
    }

    /**
     * Renames a custom audio file.
     */
    fun renameCustomAudio(id: String, newName: String) {
        viewModelScope.launch {
            customAudioRepository.rename(id, newName)
            loadCustomAudio()
        }
    }

    /**
     * Clears any custom audio error message.
     */
    fun clearCustomAudioError() {
        _uiState.update { it.copy(customAudioError = null) }
    }

    /**
     * Loads custom soundscapes and attunements from the repository.
     * Called after init and after every CRUD mutation — mirrors iOS approach.
     */
    private suspend fun loadCustomAudio() {
        val soundscapes = customAudioRepository.loadAll(CustomAudioType.SOUNDSCAPE)
        val attunements = customAudioRepository.loadAll(CustomAudioType.ATTUNEMENT)
        _uiState.update { it.copy(customSoundscapes = soundscapes, customAttunements = attunements) }
    }
}
