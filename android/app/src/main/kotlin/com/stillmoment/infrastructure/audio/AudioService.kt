package com.stillmoment.infrastructure.audio

import com.stillmoment.R
import com.stillmoment.domain.models.Attunement
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import com.stillmoment.domain.services.VibrationServiceProtocol
import com.stillmoment.domain.services.VolumeAnimatorProtocol
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch

/**
 * Audio Service for playing gong sounds and managing background audio.
 * Uses MediaPlayer for short sounds (gongs) and background loops.
 *
 * Coordinates with AudioSessionCoordinator to ensure exclusive audio access
 * when Timer and Guided Meditations features coexist.
 *
 * LargeClass suppressed: this singleton intentionally manages multiple audio concerns
 * (gongs, background loops, previews, meditation playback). Splitting would require
 * exposing internal MediaPlayer state across class boundaries.
 */
@Suppress("LargeClass")
@Singleton
class AudioService
@Inject
constructor(
    private val coordinator: AudioSessionCoordinatorProtocol,
    private val mediaPlayerFactory: MediaPlayerFactoryProtocol,
    private val volumeAnimator: VolumeAnimatorProtocol,
    private val logger: LoggerProtocol,
    private val customAudioRepository: CustomAudioRepository,
    private val soundCatalogRepository: SoundCatalogRepository,
    private val vibrationService: VibrationServiceProtocol
) : AudioServiceProtocol {
    init {
        // Register conflict handler to stop background audio when another source takes over
        coordinator.registerConflictHandler(AudioSource.TIMER) {
            logger.d(TAG, "Audio conflict: stopping timer audio for other source")
            stopBackgroundAudioInternal()
        }

        // Register pause handler for system audio focus loss (phone call, other app)
        coordinator.registerPauseHandler(AudioSource.TIMER) {
            logger.d(TAG, "Audio focus lost: pausing timer background audio")
            pauseBackgroundAudio()
        }

        // Register conflict handler to stop preview audio when another source takes over
        coordinator.registerConflictHandler(AudioSource.PREVIEW) {
            logger.d(TAG, "Audio conflict: stopping preview audio for other source")
            cleanupPreviewPlayers()
        }
    }

    private var gongPlayer: MediaPlayerProtocol? = null
    private var attunementPlayer: MediaPlayerProtocol? = null
    private var backgroundPlayer: MediaPlayerProtocol? = null
    private var previewPlayer: MediaPlayerProtocol? = null
    private var backgroundPreviewPlayer: MediaPlayerProtocol? = null
    private var attunementPreviewPlayer: MediaPlayerProtocol? = null
    private var meditationPreviewPlayer: MediaPlayerProtocol? = null
    private var backgroundPreviewJob: Job? = null
    private var meditationPreviewFadeJob: Job? = null
    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var targetVolume: Float = DEFAULT_AMBIENT_VOLUME

    // Completion flows for ViewModel to observe
    private val _gongCompletionFlow = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    override val gongCompletionFlow: SharedFlow<Unit> = _gongCompletionFlow.asSharedFlow()

    private val _attunementCompletionFlow = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    override val attunementCompletionFlow: SharedFlow<Unit> = _attunementCompletionFlow.asSharedFlow()

    companion object {
        private const val TAG = "AudioService"

        /** Duration for fade in effect (10 seconds for smooth meditation experience) */
        private const val FADE_IN_DURATION_MS = 10000L

        /** Duration for background preview before fade-out starts */
        private const val BACKGROUND_PREVIEW_DURATION_MS = 3000L

        /** Duration for fade-out effect */
        private const val FADE_OUT_DURATION_MS = 500L

        /** Duration for meditation preview fade-out (~0.3s, consistent with iOS) */
        private const val MEDITATION_PREVIEW_FADE_OUT_DURATION_MS = 300L

        /** Number of steps for fade-out animation */
        private const val FADE_OUT_STEPS = 10

        /** Default volume for ambient/background sounds (0.0 to 1.0) */
        private const val DEFAULT_AMBIENT_VOLUME = 0.15f

        /** Volume for attunement audio playback */
        private const val ATTUNEMENT_VOLUME = 0.9f

        /**
         * Resolves a raw resource name to its Android resource ID.
         * @param name The resource name (e.g., "gong_temple_bell")
         * @return Resource ID or 0 if not found
         */
        fun resolveRawResourceId(name: String): Int = when (name) {
            "gong_temple_bell" -> R.raw.gong_temple_bell
            "gong_classic_bowl" -> R.raw.gong_classic_bowl
            "gong_deep_resonance" -> R.raw.gong_deep_resonance
            "gong_clear_strike" -> R.raw.gong_clear_strike
            "interval" -> R.raw.interval
            "intro_breath_de" -> R.raw.intro_breath_de
            "intro_breath_en" -> R.raw.intro_breath_en
            "forest_ambience" -> R.raw.forest_ambience
            "cozy_midnight_rain" -> R.raw.cozy_midnight_rain
            "silence" -> R.raw.silence
            else -> 0
        }
    }

    /**
     * Maps a background sound ID to its resource ID via the sound catalog.
     * @param soundId The sound identifier (e.g., "silent", "forest", "rain")
     * @return Resource ID or null for silent/unknown sounds
     */
    private fun getBackgroundSoundResourceId(soundId: String): Int? {
        val sound = soundCatalogRepository.findById(soundId)
        if (sound == null || sound.isSilent) return null
        val resourceId = resolveRawResourceId(sound.rawResourceName)
        return if (resourceId != 0) resourceId else null
    }

    // MARK: - Player Lifecycle Helpers

    /**
     * Safely stops and releases a MediaPlayer. Returns true if a player was released.
     */
    private fun safeRelease(player: MediaPlayerProtocol?, label: String): Boolean {
        if (player == null) return false
        try {
            if (player.isPlaying) {
                player.stop()
            }
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to stop $label - invalid state: ${e.message}")
        }
        try {
            player.release()
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to release $label - invalid state: ${e.message}")
        }
        return true
    }

    // MARK: - Gong Playback

    /**
     * Play the start/completion gong sound with configurable sound and volume.
     *
     * @param soundId ID of the gong sound to play (default: classic-bowl)
     * @param volume Playback volume (0.0 to 1.0), defaults to 1.0
     */
    fun playGong(soundId: String = GongSound.DEFAULT_SOUND_ID, volume: Float = 1.0f) {
        try {
            if (soundId == GongSound.VIBRATION_ID) {
                vibrationService.vibrate()
                return
            }
            releaseGongPlayer()
            val gongSound = GongSound.findOrDefault(soundId)
            val resourceId = resolveRawResourceId(gongSound.rawResourceName)
            val clampedVolume = volume.coerceIn(0f, 1f)
            gongPlayer = mediaPlayerFactory.createFromResource(resourceId)?.apply {
                setVolume(clampedVolume, clampedVolume)
                setOnCompletionListener {
                    release()
                    gongPlayer = null
                    _gongCompletionFlow.tryEmit(Unit)
                }
                start()
            }
            logger.d(TAG, "Playing gong sound: ${gongSound.id}, volume: $clampedVolume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play gong - invalid state: ${e.message}")
        }
    }

    /**
     * Play interval gong sound with configurable sound selection.
     *
     * @param soundId ID of the gong sound to play (from GongSound.allIntervalSounds)
     * @param volume Playback volume (0.0 to 1.0), defaults to 1.0
     */
    override fun playIntervalGong(soundId: String, volume: Float) {
        try {
            if (soundId == GongSound.VIBRATION_ID) {
                vibrationService.vibrateShort()
                return
            }
            releaseGongPlayer()
            val gongSound = GongSound.findOrDefault(soundId)
            val resourceId = resolveRawResourceId(gongSound.rawResourceName)
            val clampedVolume = volume.coerceIn(0f, 1f)
            gongPlayer = mediaPlayerFactory.createFromResource(resourceId)?.apply {
                setVolume(clampedVolume, clampedVolume)
                setOnCompletionListener {
                    release()
                    gongPlayer = null
                }
                start()
            }
            logger.d(TAG, "Playing interval gong: ${gongSound.id}, volume: $clampedVolume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play interval gong - invalid state: ${e.message}")
        }
    }

    /**
     * Play a gong sound preview. Automatically stops any previous preview.
     * Uses a separate player to avoid interfering with timer playback.
     *
     * @param soundId ID of the gong sound to preview
     * @param volume Playback volume (0.0 to 1.0), defaults to 1.0
     */
    override fun playGongPreview(soundId: String, volume: Float) {
        try {
            // Stop any previous previews (mutual exclusion: gong and background)
            stopGongPreview()
            stopBackgroundPreview()

            if (soundId == GongSound.VIBRATION_ID) {
                vibrationService.vibrate()
                return
            }

            val gongSound = GongSound.findOrDefault(soundId)
            val resourceId = resolveRawResourceId(gongSound.rawResourceName)
            val clampedVolume = volume.coerceIn(0f, 1f)
            val player = mediaPlayerFactory.createFromResource(resourceId)
            if (player == null) {
                logger.e(TAG, "Failed to create player for gong preview: ${gongSound.id}")
                return
            }

            coordinator.requestAudioSession(AudioSource.PREVIEW)
            previewPlayer = player.apply {
                setVolume(clampedVolume, clampedVolume)
                setOnCompletionListener {
                    release()
                    previewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                }
                start()
            }
            logger.d(TAG, "Playing gong preview: ${gongSound.id}, volume: $clampedVolume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play gong preview - invalid state: ${e.message}")
        }
    }

    /**
     * Stop the current gong preview. Idempotent - safe to call even if no preview is playing.
     */
    override fun stopGongPreview() {
        if (safeRelease(previewPlayer, "gong preview")) {
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
        }
        previewPlayer = null
    }

    // MARK: - Attunement Playback

    /**
     * Play attunement audio from a raw resource name.
     *
     * @param resourceName Raw resource name for the attunement audio (e.g., "intro_breath_de")
     * @param volume Playback volume (0.0 to 1.0), defaults to 0.9
     */
    fun playAttunement(resourceName: String, volume: Float = ATTUNEMENT_VOLUME) {
        try {
            stopAttunement()
            val resourceId = resolveRawResourceId(resourceName)
            if (resourceId == 0) {
                logger.e(TAG, "Unknown attunement resource: $resourceName")
                return
            }
            val clampedVolume = volume.coerceIn(0f, 1f)
            attunementPlayer = mediaPlayerFactory.createFromResource(resourceId)?.apply {
                setVolume(clampedVolume, clampedVolume)
                setOnCompletionListener {
                    release()
                    attunementPlayer = null
                    _attunementCompletionFlow.tryEmit(Unit)
                }
                start()
            }
            logger.d(TAG, "Playing attunement audio, volume: $clampedVolume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play attunement - invalid state: ${e.message}")
        }
    }

    /**
     * Play attunement audio from a local file path.
     * Used for custom imported attunements.
     *
     * @param filePath Absolute path to the audio file
     * @param volume Playback volume (0.0 to 1.0), defaults to 0.9
     */
    fun playAttunementFromFile(filePath: String, volume: Float = ATTUNEMENT_VOLUME) {
        try {
            stopAttunement()
            val clampedVolume = volume.coerceIn(0f, 1f)
            val player = mediaPlayerFactory.create()
            player.setDataSource(filePath)
            player.setOnErrorListener { what, extra ->
                logger.e(TAG, "Attunement audio error: what=$what, extra=$extra")
                attunementPlayer = null
                false
            }
            player.setOnPreparedListener {
                player.setVolume(clampedVolume, clampedVolume)
                player.start()
                logger.d(TAG, "Playing attunement from file: $filePath, volume: $clampedVolume")
            }
            player.setOnCompletionListener {
                player.release()
                attunementPlayer = null
                _attunementCompletionFlow.tryEmit(Unit)
            }
            attunementPlayer = player
            player.prepareAsync()
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play attunement from file - invalid state: ${e.message}")
        }
    }

    /**
     * Stop attunement audio. Idempotent.
     */
    fun stopAttunement() {
        safeRelease(attunementPlayer, "attunement")
        attunementPlayer = null
    }

    // MARK: - Background Preview

    /**
     * Play a background sound preview. Plays for 3 seconds with fade-out.
     * Automatically stops any previous preview (gong or background).
     *
     * @param soundId ID of the background sound to preview ("silent" or "forest")
     * @param volume Playback volume (0.0 to 1.0)
     */
    override fun playBackgroundPreview(soundId: String, volume: Float) {
        // Stop any previous previews (mutual exclusion: gong and background)
        stopBackgroundPreview()
        stopGongPreview()

        // Get resource ID - returns null for silent/unknown sounds
        val resourceId = getBackgroundSoundResourceId(soundId)
        if (resourceId == null) {
            // If sound is in the built-in catalog (e.g. silent), skip preview
            if (soundCatalogRepository.findById(soundId) != null) {
                logger.d(TAG, "Skipping preview for sound: $soundId")
                return
            }
            // Not in catalog - treat as custom audio file
            playCustomBackgroundPreview(soundId, volume)
            return
        }

        try {
            val player = mediaPlayerFactory.createFromResource(resourceId)
            if (player == null) {
                logger.e(TAG, "Failed to create player for background preview: $soundId")
                return
            }

            coordinator.requestAudioSession(AudioSource.PREVIEW)
            backgroundPreviewPlayer = player.apply {
                setVolume(volume, volume)
                setOnCompletionListener {
                    release()
                    backgroundPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                }
                start()
            }

            // Schedule fade-out after preview duration
            backgroundPreviewJob?.cancel()
            backgroundPreviewJob = mainScope.launch {
                delay(BACKGROUND_PREVIEW_DURATION_MS)
                fadeOutBackgroundPreview(volume)
            }

            logger.d(TAG, "Playing background preview: $soundId at volume $volume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play background preview - invalid state: ${e.message}")
        }
    }

    /**
     * Stop the current background preview. Idempotent - safe to call even if no preview is playing.
     */
    override fun stopBackgroundPreview() {
        backgroundPreviewJob?.cancel()
        backgroundPreviewJob = null
        if (safeRelease(backgroundPreviewPlayer, "background preview")) {
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
        }
        backgroundPreviewPlayer = null
    }

    /**
     * Play a custom background sound preview from a local file path.
     * Resolves the file path asynchronously via CustomAudioRepository.
     */
    private fun playCustomBackgroundPreview(soundId: String, volume: Float) {
        mainScope.launch {
            try {
                val filePath = customAudioRepository.getFilePath(soundId)
                if (filePath == null) {
                    logger.w(TAG, "Custom background sound not found: $soundId")
                    return@launch
                }
                coordinator.requestAudioSession(AudioSource.PREVIEW)
                val player = mediaPlayerFactory.create()
                player.setDataSource(filePath)
                player.setOnErrorListener { what, extra ->
                    logger.e(TAG, "Background preview error: what=$what, extra=$extra")
                    backgroundPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                    false
                }
                player.setOnPreparedListener {
                    player.setVolume(volume, volume)
                    player.start()
                    backgroundPreviewJob?.cancel()
                    backgroundPreviewJob = mainScope.launch {
                        delay(BACKGROUND_PREVIEW_DURATION_MS)
                        fadeOutBackgroundPreview(volume)
                    }
                    logger.d(TAG, "Playing custom background preview: $soundId at volume $volume")
                }
                player.setOnCompletionListener {
                    player.release()
                    backgroundPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                }
                backgroundPreviewPlayer = player
                player.prepareAsync()
            } catch (e: IllegalStateException) {
                logger.e(TAG, "Failed to play custom background preview - invalid state: ${e.message}")
            }
        }
    }

    /**
     * Fades out and stops the background preview player.
     * Must be called from a coroutine context.
     */
    private suspend fun fadeOutBackgroundPreview(startVolume: Float) {
        val player = backgroundPreviewPlayer ?: return
        fadeOutPlayer(player, FADE_OUT_DURATION_MS, startVolume)
        safeRelease(player, "background preview after fade")
        backgroundPreviewPlayer = null
        coordinator.releaseAudioSession(AudioSource.PREVIEW)
        logger.d(TAG, "Background preview fade-out complete")
    }

    /**
     * Animates a player's volume from startVolume down to 0 over durationMs.
     * Must be called from a coroutine context.
     */
    private suspend fun fadeOutPlayer(player: MediaPlayerProtocol, durationMs: Long, startVolume: Float = 1.0f) {
        val stepDuration = durationMs / FADE_OUT_STEPS
        for (step in FADE_OUT_STEPS downTo 0) {
            val volume = startVolume * step / FADE_OUT_STEPS
            try {
                player.setVolume(volume, volume)
            } catch (e: IllegalStateException) {
                logger.d(TAG, "Fade interrupted - player released: ${e.message}")
                break
            }
            delay(stepDuration)
        }
    }

    // MARK: - Attunement Preview

    /**
     * Play an attunement audio preview (attunement or built-in attunement).
     * Automatically stops any previous preview.
     *
     * Resolves the attunementId: if it matches a built-in Attunement, plays from resources;
     * otherwise treats it as a custom audio UUID and resolves via CustomAudioRepository.
     *
     * @param attunementId ID of the attunement to preview
     */
    override fun playAttunementPreview(attunementId: String) {
        // Stop any previous previews (mutual exclusion)
        stopAttunementPreview()
        stopGongPreview()
        stopBackgroundPreview()

        val attunement = Attunement.find(attunementId)
        if (attunement != null) {
            playBuiltInAttunementPreview(attunement)
        } else {
            playCustomAttunementPreview(attunementId)
        }
    }

    /**
     * Play a built-in attunement preview from raw resources.
     */
    private fun playBuiltInAttunementPreview(attunement: Attunement) {
        val resourceName = attunement.audioFilename(Attunement.currentLanguage)
        if (resourceName == null) {
            logger.d(TAG, "No audio available for attunement ${attunement.id} in ${Attunement.currentLanguage}")
            return
        }
        val resourceId = resolveRawResourceId(resourceName)
        if (resourceId == 0) {
            logger.e(TAG, "Unknown attunement resource: $resourceName")
            return
        }
        try {
            val player = mediaPlayerFactory.createFromResource(resourceId)
            if (player == null) {
                logger.e(TAG, "Failed to create player for attunement preview: ${attunement.id}")
                return
            }
            coordinator.requestAudioSession(AudioSource.PREVIEW)
            attunementPreviewPlayer = player.apply {
                setVolume(ATTUNEMENT_VOLUME, ATTUNEMENT_VOLUME)
                setOnCompletionListener {
                    release()
                    attunementPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                }
                start()
            }
            logger.d(TAG, "Playing built-in attunement preview: ${attunement.id}")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play attunement preview - invalid state: ${e.message}")
        }
    }

    /**
     * Play a custom attunement preview from a local file path.
     * Resolves the file path asynchronously via CustomAudioRepository.
     */
    private fun playCustomAttunementPreview(attunementId: String) {
        mainScope.launch {
            try {
                val filePath = customAudioRepository.getFilePath(attunementId)
                if (filePath == null) {
                    logger.w(TAG, "Custom attunement not found: $attunementId")
                    return@launch
                }
                coordinator.requestAudioSession(AudioSource.PREVIEW)
                val player = mediaPlayerFactory.create()
                player.setDataSource(filePath)
                player.setOnErrorListener { what, extra ->
                    logger.e(TAG, "Attunement preview error: what=$what, extra=$extra")
                    attunementPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                    false
                }
                player.setOnPreparedListener {
                    player.setVolume(ATTUNEMENT_VOLUME, ATTUNEMENT_VOLUME)
                    player.start()
                    logger.d(TAG, "Playing custom attunement preview: $attunementId")
                }
                player.setOnCompletionListener {
                    player.release()
                    attunementPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                }
                attunementPreviewPlayer = player
                player.prepareAsync()
            } catch (e: IllegalStateException) {
                logger.e(
                    TAG,
                    "Failed to play custom attunement preview - invalid state: ${e.message}"
                )
            }
        }
    }

    /**
     * Stop the current attunement preview. Idempotent - safe to call even if no preview is playing.
     */
    override fun stopAttunementPreview() {
        if (safeRelease(attunementPreviewPlayer, "attunement preview")) {
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
        }
        attunementPreviewPlayer = null
    }

    // MARK: - Background Audio

    /**
     * Start background audio loop from a local file path with fade in.
     * Used for custom imported soundscapes. Requests exclusive audio session before starting.
     *
     * @param filePath Absolute path to the audio file
     * @param volume The playback volume (0.0 to 1.0), defaults to DEFAULT_AMBIENT_VOLUME
     */
    fun startBackgroundAudioFromFile(filePath: String, volume: Float = DEFAULT_AMBIENT_VOLUME) {
        try {
            if (!coordinator.requestAudioSession(AudioSource.TIMER)) {
                logger.w(TAG, "Failed to acquire audio session for background audio from file")
                return
            }

            stopBackgroundAudioInternal()
            targetVolume = volume.coerceIn(0f, 1f)

            val player = mediaPlayerFactory.create()
            player.setDataSource(filePath)
            player.isLooping = true
            player.setVolume(0f, 0f)
            player.setOnErrorListener { what, extra ->
                logger.e(TAG, "Background audio error: what=$what, extra=$extra")
                backgroundPlayer = null
                false
            }
            player.setOnPreparedListener {
                player.start()
                fadeToVolume(targetVolume)
                logger.d(TAG, "Started background audio from file: $filePath, volume: $targetVolume")
            }
            backgroundPlayer = player
            player.prepareAsync()
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to start background audio from file - invalid state: ${e.message}")
        }
    }

    /**
     * Start background audio loop with fade in.
     * Requests exclusive audio session before starting playback.
     *
     * @param soundId The sound identifier ("silent" or "forest")
     * @param volume The playback volume (0.0 to 1.0), defaults to DEFAULT_AMBIENT_VOLUME
     */
    fun startBackgroundAudio(soundId: String, volume: Float = DEFAULT_AMBIENT_VOLUME) {
        try {
            // Request exclusive audio session
            if (!coordinator.requestAudioSession(AudioSource.TIMER)) {
                logger.w(TAG, "Failed to acquire audio session for background audio")
                return
            }

            stopBackgroundAudioInternal()

            // Get resource ID - fallback to silence for unknown sounds
            val resourceId = getBackgroundSoundResourceId(soundId) ?: R.raw.silence

            // Use the provided volume (from settings) instead of hardcoded default
            targetVolume = volume.coerceIn(0f, 1f)

            backgroundPlayer = mediaPlayerFactory.createFromResource(resourceId)?.apply {
                isLooping = true
                setVolume(0f, 0f) // Start at 0 for fade in
                start()
            }

            // Fade in to target volume
            fadeToVolume(targetVolume)
            logger.d(TAG, "Started background audio with fade in: $soundId, volume: $targetVolume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to start background audio - invalid state: ${e.message}")
        }
    }

    /**
     * Stop background audio and release the audio session.
     */
    fun stopBackgroundAudio() {
        volumeAnimator.cancel()
        stopBackgroundAudioInternal()
        coordinator.releaseAudioSession(AudioSource.TIMER)
    }

    /**
     * Pause background audio immediately (no fade).
     * Used for "Brief Pause" during meditation.
     */
    fun pauseBackgroundAudio() {
        volumeAnimator.cancel()
        try {
            backgroundPlayer?.let { player ->
                if (player.isPlaying) {
                    player.pause()
                    logger.d(TAG, "Paused background audio")
                }
            }
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to pause background audio - invalid state: ${e.message}")
        }
    }

    /**
     * Resume background audio with fade in.
     * Used after "Brief Pause" during meditation.
     */
    fun resumeBackgroundAudio() {
        try {
            backgroundPlayer?.let { player ->
                if (!player.isPlaying) {
                    player.setVolume(0f, 0f)
                    player.start()
                }
                // Fade in to target volume
                fadeToVolume(targetVolume)
                logger.d(TAG, "Resuming background audio with fade in")
            }
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to resume background audio - invalid state: ${e.message}")
        }
    }

    /**
     * Internal method to stop background audio without releasing the session.
     * Used by the conflict handler to stop playback when another source takes over.
     */
    private fun stopBackgroundAudioInternal() {
        volumeAnimator.cancel()
        safeRelease(backgroundPlayer, "background audio")
        backgroundPlayer = null
        logger.d(TAG, "Stopped background audio")
    }

    /**
     * Animate volume from current level to target over FADE_IN_DURATION_MS.
     */
    private fun fadeToVolume(target: Float) {
        volumeAnimator.animate(0f, target, FADE_IN_DURATION_MS) { volume ->
            try {
                backgroundPlayer?.setVolume(volume, volume)
            } catch (e: IllegalStateException) {
                logger.e(TAG, "Failed to set volume during fade - invalid state: ${e.message}")
            }
        }
    }

    /**
     * Check if background audio is currently playing.
     */
    fun isBackgroundAudioPlaying(): Boolean {
        return backgroundPlayer?.isPlaying == true
    }

    // MARK: - Meditation Preview

    /**
     * Play a guided meditation preview from a content URI (SAF).
     * Automatically stops any previous preview.
     * Uses AudioSource.PREVIEW (not GUIDED_MEDITATION).
     *
     * @param fileUri Content URI string of the meditation file
     */
    override fun playMeditationPreview(fileUri: String) {
        // Cancel fade-out and hard-stop the previous player (no fade for switch)
        meditationPreviewFadeJob?.cancel()
        meditationPreviewFadeJob = null
        hardStopMeditationPreview()
        stopGongPreview()
        stopBackgroundPreview()
        stopAttunementPreview()

        try {
            val player = mediaPlayerFactory.createFromContentUri(fileUri)
            if (player == null) {
                logger.e(TAG, "Failed to create player for meditation preview: $fileUri")
                return
            }

            coordinator.requestAudioSession(AudioSource.PREVIEW)
            meditationPreviewPlayer = player.apply {
                setVolume(1.0f, 1.0f)
                setOnCompletionListener {
                    release()
                    meditationPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                }
                start()
            }
            logger.d(TAG, "Playing meditation preview: $fileUri")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play meditation preview - invalid state: ${e.message}")
        }
    }

    /**
     * Stop the current meditation preview with fade-out (~0.3s, consistent with iOS).
     * Idempotent - safe to call even if no preview is playing.
     */
    override fun stopMeditationPreview() {
        val player = meditationPreviewPlayer ?: return

        // Cancel any previous fade-out job
        meditationPreviewFadeJob?.cancel()

        meditationPreviewFadeJob = mainScope.launch {
            fadeOutMeditationPreview(player)
        }
    }

    /**
     * Fades out and stops the meditation preview player.
     * Must be called from a coroutine context.
     */
    private suspend fun fadeOutMeditationPreview(player: MediaPlayerProtocol) {
        fadeOutPlayer(player, MEDITATION_PREVIEW_FADE_OUT_DURATION_MS)
        safeRelease(player, "meditation preview after fade")

        // Only clean up if this player is still the current one (not replaced by a new preview)
        if (meditationPreviewPlayer === player) {
            meditationPreviewPlayer = null
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
            logger.d(TAG, "Meditation preview fade-out complete")
        }
    }

    /**
     * Immediately stops the meditation preview player without fade-out.
     * Used when switching to a new preview or during conflict cleanup.
     */
    private fun hardStopMeditationPreview() {
        if (safeRelease(meditationPreviewPlayer, "meditation preview")) {
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
        }
        meditationPreviewPlayer = null
    }

    // MARK: - Preview Cleanup

    /**
     * Stops all preview players without releasing the audio session.
     * Used by the conflict handler to stop previews when another source takes over.
     */
    private fun cleanupPreviewPlayers() {
        backgroundPreviewJob?.cancel()
        backgroundPreviewJob = null
        meditationPreviewFadeJob?.cancel()
        meditationPreviewFadeJob = null

        safeRelease(previewPlayer, "gong preview cleanup")
        previewPlayer = null
        safeRelease(backgroundPreviewPlayer, "background preview cleanup")
        backgroundPreviewPlayer = null
        safeRelease(attunementPreviewPlayer, "attunement preview cleanup")
        attunementPreviewPlayer = null
        safeRelease(meditationPreviewPlayer, "meditation preview cleanup")
        meditationPreviewPlayer = null
    }

    // MARK: - Lifecycle

    /**
     * Release all audio resources.
     */
    fun release() {
        releaseGongPlayer()
        stopAttunement()
        stopGongPreview()
        stopBackgroundPreview()
        stopAttunementPreview()
        // Hard-stop instead of fade — mainScope.cancel() below would abort the fade coroutine
        meditationPreviewFadeJob?.cancel()
        meditationPreviewFadeJob = null
        hardStopMeditationPreview()
        stopBackgroundAudio()
        mainScope.cancel()
    }

    private fun releaseGongPlayer() {
        safeRelease(gongPlayer, "gong player")
        gongPlayer = null
    }
}
