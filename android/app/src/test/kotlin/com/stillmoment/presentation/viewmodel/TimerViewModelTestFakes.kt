package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.IntervalSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.ResolvedSoundscape
import com.stillmoment.domain.models.TimerEvent
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.SoundscapeResolverProtocol
import com.stillmoment.domain.services.TimerForegroundServiceProtocol
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.map

/**
 * Fake implementation of AudioServiceProtocol for testing.
 * Tracks method calls for verification.
 */
class FakeAudioService : AudioServiceProtocol {
    var lastGongPreviewSoundId: String? = null
    var lastGongPreviewVolume: Float? = null
    var gongPreviewStopped = false
    var lastBackgroundPreviewSoundId: String? = null
    var lastBackgroundPreviewVolume: Float? = null
    var backgroundPreviewStopped = false
    var lastIntervalGongSoundId: String? = null
    var lastIntervalGongVolume: Float? = null

    override val gongCompletionFlow: SharedFlow<Unit> = MutableSharedFlow()

    override fun playGongPreview(soundId: String, volume: Float) {
        lastGongPreviewSoundId = soundId
        lastGongPreviewVolume = volume
    }

    override fun playIntervalGong(soundId: String, volume: Float) {
        lastIntervalGongSoundId = soundId
        lastIntervalGongVolume = volume
    }

    override fun stopGongPreview() {
        gongPreviewStopped = true
    }

    override fun playBackgroundPreview(soundId: String, volume: Float) {
        lastBackgroundPreviewSoundId = soundId
        lastBackgroundPreviewVolume = volume
    }

    override fun stopBackgroundPreview() {
        backgroundPreviewStopped = true
    }

    override fun playMeditationPreview(fileUri: String) {
        // no-op for timer tests
    }

    override fun stopMeditationPreview() {
        // no-op for timer tests
    }
}

/**
 * Fake implementation of TimerForegroundServiceProtocol for testing.
 * Tracks method calls for verification.
 */
class FakeTimerForegroundService : TimerForegroundServiceProtocol {
    var serviceStarted = false
    var serviceStopped = false
    var lastStartSoundId: String? = null
    var lastStartSoundVolume: Float? = null
    var lastStartGongSoundId: String? = null
    var lastStartGongVolume: Float? = null
    var lastGongSoundId: String? = null
    var lastGongVolume: Float? = null
    var lastIntervalGongSoundId: String? = null
    var lastIntervalGongVolume: Float? = null
    var lastBackgroundAudioSoundId: String? = null
    var lastBackgroundAudioVolume: Float? = null
    var audioPaused = false
    var audioResumed = false

    override fun startService(soundId: String, soundVolume: Float, gongSoundId: String, gongVolume: Float) {
        serviceStarted = true
        lastStartSoundId = soundId
        lastStartSoundVolume = soundVolume
        lastStartGongSoundId = gongSoundId
        lastStartGongVolume = gongVolume
    }

    override fun stopService() {
        serviceStopped = true
    }

    override fun playGong(gongSoundId: String, gongVolume: Float) {
        lastGongSoundId = gongSoundId
        lastGongVolume = gongVolume
    }

    override fun playIntervalGong(gongSoundId: String, gongVolume: Float) {
        lastIntervalGongSoundId = gongSoundId
        lastIntervalGongVolume = gongVolume
    }

    override fun updateBackgroundAudio(soundId: String, soundVolume: Float) {
        lastBackgroundAudioSoundId = soundId
        lastBackgroundAudioVolume = soundVolume
    }

    override fun pauseAudio() {
        audioPaused = true
    }

    override fun resumeAudio() {
        audioResumed = true
    }
}

/**
 * Fake implementation of TimerRepository for testing.
 */
class FakeTimerRepository : TimerRepository {
    private val _timer = MutableStateFlow<MeditationTimer?>(null)

    override val timerFlow: Flow<MeditationTimer> =
        _timer.filterNotNull()

    override val currentTimer: MeditationTimer? = null

    override suspend fun start(durationMinutes: Int, preparationTimeSeconds: Int): List<TimerEvent> {
        // no-op for tests
        return emptyList()
    }

    override suspend fun reset() {
        // no-op for tests
    }

    override suspend fun setDuration(durationMinutes: Int) {
        // no-op for tests
    }

    override fun tick(intervalSettings: IntervalSettings?): Pair<MeditationTimer, List<TimerEvent>>? = null

    override fun startRunning() {
        // no-op for tests
    }

    override fun completeTimer() {
        // no-op for tests
    }
}

/**
 * Fake implementation of SoundCatalogRepository for testing.
 * Returns a minimal catalog with silent and forest sounds by default.
 */
class FakeSoundCatalogRepository : SoundCatalogRepository {
    private val defaultSounds = listOf(
        BackgroundSound(
            id = BackgroundSound.SILENT_ID,
            nameEnglish = "Silence",
            nameGerman = "Stille",
            descriptionEnglish = "Meditate in silence.",
            descriptionGerman = "Meditiere in Stille.",
            rawResourceName = ""
        ),
        BackgroundSound(
            id = "forest",
            nameEnglish = "Forest Ambience",
            nameGerman = "Waldatmosphäre",
            descriptionEnglish = "Natural forest sounds",
            descriptionGerman = "Natürliche Waldgeräusche",
            rawResourceName = "forest_ambience"
        )
    )

    override fun getAllSounds(): List<BackgroundSound> = defaultSounds

    override fun findById(id: String): BackgroundSound? = defaultSounds.find { it.id == id }

    override fun findByIdOrDefault(id: String): BackgroundSound = findById(id) ?: defaultSounds.first()
}

/**
 * Fake implementation of CustomAudioRepository for testing.
 * Provides in-memory storage and tracks import/delete calls.
 */
class FakeCustomAudioRepository : CustomAudioRepository {
    private val _files = MutableStateFlow<List<CustomAudioFile>>(emptyList())
    var lastDeletedId: String? = null

    /** Adds a file directly to the in-memory store (for test setup). */
    fun addFile(file: CustomAudioFile) {
        _files.value = _files.value + file
    }
    var importResult: Result<CustomAudioFile> = Result.success(
        CustomAudioFile(
            id = "fake-id",
            name = "fake",
            filename = "fake.mp3",
            durationMs = 60_000L,
            type = CustomAudioType.SOUNDSCAPE
        )
    )

    override fun filesFlow(type: CustomAudioType): Flow<List<CustomAudioFile>> {
        return _files.map { files -> files.filter { it.type == type } }
    }

    override suspend fun loadAll(type: CustomAudioType): List<CustomAudioFile> {
        return _files.value.filter { it.type == type }
    }

    override suspend fun importFile(uri: Uri, type: CustomAudioType): Result<CustomAudioFile> {
        importResult.onSuccess { file ->
            _files.value = _files.value + file.copy(type = type)
        }
        return importResult
    }

    override suspend fun delete(id: String) {
        lastDeletedId = id
        _files.value = _files.value.filter { it.id != id }
    }

    override suspend fun getFilePath(id: String): String? {
        return _files.value.find { it.id == id }?.let { "/fake/path/${it.filename}" }
    }

    override suspend fun findFile(id: String): CustomAudioFile? {
        return _files.value.find { it.id == id }
    }

    override suspend fun rename(id: String, newName: String) {
        _files.value = _files.value.map { file ->
            if (file.id == id) file.copy(name = newName) else file
        }
    }
}

/**
 * Fake implementation of SoundscapeResolverProtocol for testing.
 * Resolves built-in sounds via a default catalog and custom IDs via configurable map.
 */
class FakeSoundscapeResolver : SoundscapeResolverProtocol {
    var customSoundscapes: Map<String, ResolvedSoundscape> = emptyMap()

    private val builtInSounds = mapOf(
        "forest" to ResolvedSoundscape(
            id = "forest",
            displayName = "Forest Ambience"
        )
    )

    override fun resolve(id: String): ResolvedSoundscape? {
        if (id == BackgroundSound.SILENT_ID) return null
        builtInSounds[id]?.let { return it }
        return customSoundscapes[id]
    }

    override fun allAvailable(): List<ResolvedSoundscape> {
        return builtInSounds.values.toList() + customSoundscapes.values
    }
}
