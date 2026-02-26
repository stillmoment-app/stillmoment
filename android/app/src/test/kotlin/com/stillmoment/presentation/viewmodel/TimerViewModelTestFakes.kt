package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.IntervalSettings
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerEvent
import com.stillmoment.domain.repositories.SettingsRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.TimerForegroundServiceProtocol
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first

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
    var lastIntroductionPreviewId: String? = null
    var introductionPreviewStopped = false

    override val gongCompletionFlow: SharedFlow<Unit> = MutableSharedFlow()
    override val introductionCompletionFlow: SharedFlow<Unit> = MutableSharedFlow()

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

    override fun playIntroductionPreview(introductionId: String) {
        lastIntroductionPreviewId = introductionId
    }

    override fun stopIntroductionPreview() {
        introductionPreviewStopped = true
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
    var lastIntroductionId: String? = null
    var introductionStopped = false
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

    override fun playIntroduction(introductionId: String) {
        lastIntroductionId = introductionId
    }

    override fun stopIntroduction() {
        introductionStopped = true
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
 * Fake implementation of SettingsRepository for testing.
 * Tracks hasSeenSettingsHint state for verification.
 */
class FakeSettingsRepository : SettingsRepository {
    private val _settings = MutableStateFlow(MeditationSettings.Default)
    var hasSeenHint = false

    override val settingsFlow: Flow<MeditationSettings> = _settings

    override suspend fun updateSettings(settings: MeditationSettings) {
        _settings.value = settings
    }

    override suspend fun getSettings(): MeditationSettings = _settings.first()

    override suspend fun getHasSeenSettingsHint(): Boolean = hasSeenHint

    override suspend fun setHasSeenSettingsHint(seen: Boolean) {
        hasSeenHint = seen
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

    override suspend fun start(
        durationMinutes: Int,
        preparationTimeSeconds: Int,
        introductionDurationSeconds: Int
    ): List<TimerEvent> {
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

    override fun startIntroduction() {
        // no-op for tests
    }

    override fun endIntroduction() {
        // no-op for tests
    }

    override fun startRunning() {
        // no-op for tests
    }

    override fun completeTimer() {
        // no-op for tests
    }
}
