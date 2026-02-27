package com.stillmoment.infrastructure.audio

import com.stillmoment.R
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
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
 */
@Singleton
class AudioService
@Inject
constructor(
    private val coordinator: AudioSessionCoordinatorProtocol,
    private val mediaPlayerFactory: MediaPlayerFactoryProtocol,
    private val volumeAnimator: VolumeAnimatorProtocol,
    private val logger: LoggerProtocol,
    private val customAudioRepository: CustomAudioRepository,
    private val soundCatalogRepository: SoundCatalogRepository
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
    private var introductionPlayer: MediaPlayerProtocol? = null
    private var backgroundPlayer: MediaPlayerProtocol? = null
    private var previewPlayer: MediaPlayerProtocol? = null
    private var backgroundPreviewPlayer: MediaPlayerProtocol? = null
    private var introductionPreviewPlayer: MediaPlayerProtocol? = null
    private var backgroundPreviewJob: Job? = null
    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var targetVolume: Float = DEFAULT_AMBIENT_VOLUME

    // Completion flows for ViewModel to observe
    private val _gongCompletionFlow = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    override val gongCompletionFlow: SharedFlow<Unit> = _gongCompletionFlow.asSharedFlow()

    private val _introductionCompletionFlow = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    override val introductionCompletionFlow: SharedFlow<Unit> = _introductionCompletionFlow.asSharedFlow()

    companion object {
        private const val TAG = "AudioService"

        /** Duration for fade in effect (10 seconds for smooth meditation experience) */
        private const val FADE_IN_DURATION_MS = 10000L

        /** Duration for background preview before fade-out starts */
        private const val BACKGROUND_PREVIEW_DURATION_MS = 3000L

        /** Duration for fade-out effect */
        private const val FADE_OUT_DURATION_MS = 500L

        /** Number of steps for fade-out animation */
        private const val FADE_OUT_STEPS = 10

        /** Default volume for ambient/background sounds (0.0 to 1.0) */
        private const val DEFAULT_AMBIENT_VOLUME = 0.15f

        /** Volume for introduction audio playback */
        private const val INTRODUCTION_VOLUME = 0.9f

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
            "forest_ambience" -> R.raw.forest_ambience
            "rain_ambience" -> R.raw.rain_ambience
            "ocean_waves" -> R.raw.ocean_waves
            "birds_chirping" -> R.raw.birds_chirping
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

    // MARK: - Gong Playback

    /**
     * Play the start/completion gong sound with configurable sound and volume.
     *
     * @param soundId ID of the gong sound to play (default: classic-bowl)
     * @param volume Playback volume (0.0 to 1.0), defaults to 1.0
     */
    fun playGong(soundId: String = GongSound.DEFAULT_SOUND_ID, volume: Float = 1.0f) {
        try {
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
        val hadPlayer = previewPlayer != null
        try {
            previewPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            previewPlayer = null
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to stop gong preview - invalid state: ${e.message}")
        }
        if (hadPlayer) {
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
        }
    }

    // MARK: - Introduction Playback

    /**
     * Play introduction audio from a raw resource name.
     *
     * @param resourceName Raw resource name for the introduction audio (e.g., "intro_breath_de")
     * @param volume Playback volume (0.0 to 1.0), defaults to 0.9
     */
    fun playIntroduction(resourceName: String, volume: Float = INTRODUCTION_VOLUME) {
        try {
            stopIntroduction()
            val resourceId = resolveRawResourceId(resourceName)
            if (resourceId == 0) {
                logger.e(TAG, "Unknown introduction resource: $resourceName")
                return
            }
            val clampedVolume = volume.coerceIn(0f, 1f)
            introductionPlayer = mediaPlayerFactory.createFromResource(resourceId)?.apply {
                setVolume(clampedVolume, clampedVolume)
                setOnCompletionListener {
                    release()
                    introductionPlayer = null
                    _introductionCompletionFlow.tryEmit(Unit)
                }
                start()
            }
            logger.d(TAG, "Playing introduction audio, volume: $clampedVolume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play introduction - invalid state: ${e.message}")
        }
    }

    /**
     * Play introduction audio from a local file path.
     * Used for custom imported attunements.
     *
     * @param filePath Absolute path to the audio file
     * @param volume Playback volume (0.0 to 1.0), defaults to 0.9
     */
    fun playIntroductionFromFile(filePath: String, volume: Float = INTRODUCTION_VOLUME) {
        try {
            stopIntroduction()
            val clampedVolume = volume.coerceIn(0f, 1f)
            val player = mediaPlayerFactory.create()
            player.setDataSource(filePath)
            player.setOnErrorListener { what, extra ->
                logger.e(TAG, "Introduction audio error: what=$what, extra=$extra")
                introductionPlayer = null
                false
            }
            player.setOnPreparedListener {
                player.setVolume(clampedVolume, clampedVolume)
                player.start()
                logger.d(TAG, "Playing introduction from file: $filePath, volume: $clampedVolume")
            }
            player.setOnCompletionListener {
                player.release()
                introductionPlayer = null
                _introductionCompletionFlow.tryEmit(Unit)
            }
            introductionPlayer = player
            player.prepareAsync()
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play introduction from file - invalid state: ${e.message}")
        }
    }

    /**
     * Stop introduction audio. Idempotent.
     */
    fun stopIntroduction() {
        try {
            introductionPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            introductionPlayer = null
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to stop introduction - invalid state: ${e.message}")
        }
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
            logger.d(TAG, "Skipping preview for sound: $soundId")
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
        val hadPlayer = backgroundPreviewPlayer != null
        // Cancel fade-out job
        backgroundPreviewJob?.cancel()
        backgroundPreviewJob = null

        try {
            backgroundPreviewPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            backgroundPreviewPlayer = null
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to stop background preview - invalid state: ${e.message}")
        }
        if (hadPlayer) {
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
        }
    }

    /**
     * Fades out and stops the background preview player.
     * Must be called from a coroutine context.
     */
    private suspend fun fadeOutBackgroundPreview(startVolume: Float) {
        val player = backgroundPreviewPlayer ?: return

        val stepDuration = FADE_OUT_DURATION_MS / FADE_OUT_STEPS
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

        // Stop and clean up after fade completes
        try {
            backgroundPreviewPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            backgroundPreviewPlayer = null
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
            logger.d(TAG, "Background preview fade-out complete")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to stop background preview after fade - invalid state: ${e.message}")
        }
    }

    // MARK: - Introduction Preview

    /**
     * Play an introduction audio preview (attunement or built-in introduction).
     * Automatically stops any previous preview.
     *
     * Resolves the introductionId: if it matches a built-in Introduction, plays from resources;
     * otherwise treats it as a custom audio UUID and resolves via CustomAudioRepository.
     *
     * @param introductionId ID of the introduction to preview
     */
    override fun playIntroductionPreview(introductionId: String) {
        // Stop any previous previews (mutual exclusion)
        stopIntroductionPreview()
        stopGongPreview()
        stopBackgroundPreview()

        val introduction = Introduction.find(introductionId)
        if (introduction != null) {
            playBuiltInIntroductionPreview(introduction)
        } else {
            playCustomIntroductionPreview(introductionId)
        }
    }

    /**
     * Play a built-in introduction preview from raw resources.
     */
    private fun playBuiltInIntroductionPreview(introduction: Introduction) {
        val resourceName = introduction.audioFilename(Introduction.currentLanguage)
        if (resourceName == null) {
            logger.d(TAG, "No audio available for introduction ${introduction.id} in ${Introduction.currentLanguage}")
            return
        }
        val resourceId = resolveRawResourceId(resourceName)
        if (resourceId == 0) {
            logger.e(TAG, "Unknown introduction resource: $resourceName")
            return
        }
        try {
            val player = mediaPlayerFactory.createFromResource(resourceId)
            if (player == null) {
                logger.e(TAG, "Failed to create player for introduction preview: ${introduction.id}")
                return
            }
            coordinator.requestAudioSession(AudioSource.PREVIEW)
            introductionPreviewPlayer = player.apply {
                setVolume(INTRODUCTION_VOLUME, INTRODUCTION_VOLUME)
                setOnCompletionListener {
                    release()
                    introductionPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                }
                start()
            }
            logger.d(TAG, "Playing built-in introduction preview: ${introduction.id}")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play introduction preview - invalid state: ${e.message}")
        }
    }

    /**
     * Play a custom introduction preview from a local file path.
     * Resolves the file path asynchronously via CustomAudioRepository.
     */
    private fun playCustomIntroductionPreview(introductionId: String) {
        mainScope.launch {
            try {
                val filePath = customAudioRepository.getFilePath(introductionId)
                if (filePath == null) {
                    logger.w(TAG, "Custom introduction not found: $introductionId")
                    return@launch
                }
                coordinator.requestAudioSession(AudioSource.PREVIEW)
                val player = mediaPlayerFactory.create()
                player.setDataSource(filePath)
                player.setOnErrorListener { what, extra ->
                    logger.e(TAG, "Introduction preview error: what=$what, extra=$extra")
                    introductionPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                    false
                }
                player.setOnPreparedListener {
                    player.setVolume(INTRODUCTION_VOLUME, INTRODUCTION_VOLUME)
                    player.start()
                    logger.d(TAG, "Playing custom introduction preview: $introductionId")
                }
                player.setOnCompletionListener {
                    player.release()
                    introductionPreviewPlayer = null
                    coordinator.releaseAudioSession(AudioSource.PREVIEW)
                }
                introductionPreviewPlayer = player
                player.prepareAsync()
            } catch (e: IllegalStateException) {
                logger.e(
                    TAG,
                    "Failed to play custom introduction preview - invalid state: ${e.message}"
                )
            }
        }
    }

    /**
     * Stop the current introduction preview. Idempotent - safe to call even if no preview is playing.
     */
    override fun stopIntroductionPreview() {
        val hadPlayer = introductionPreviewPlayer != null
        try {
            introductionPreviewPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            introductionPreviewPlayer = null
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to stop introduction preview - invalid state: ${e.message}")
        }
        if (hadPlayer) {
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
        }
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
        try {
            backgroundPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            backgroundPlayer = null
            logger.d(TAG, "Stopped background audio")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to stop background audio - invalid state: ${e.message}")
        }
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

    // MARK: - Preview Cleanup

    /**
     * Stops all preview players without releasing the audio session.
     * Used by the conflict handler to stop previews when another source takes over.
     */
    private fun cleanupPreviewPlayers() {
        // Cancel background preview fade-out job
        backgroundPreviewJob?.cancel()
        backgroundPreviewJob = null

        try {
            previewPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            previewPlayer = null
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to cleanup gong preview - invalid state: ${e.message}")
        }

        try {
            backgroundPreviewPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            backgroundPreviewPlayer = null
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to cleanup background preview - invalid state: ${e.message}")
        }

        try {
            introductionPreviewPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            introductionPreviewPlayer = null
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to cleanup introduction preview - invalid state: ${e.message}")
        }
    }

    // MARK: - Lifecycle

    /**
     * Release all audio resources.
     */
    fun release() {
        releaseGongPlayer()
        stopIntroduction()
        stopGongPreview()
        stopBackgroundPreview()
        stopIntroductionPreview()
        stopBackgroundAudio()
        mainScope.cancel()
    }

    private fun releaseGongPlayer() {
        try {
            gongPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            gongPlayer = null
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to release gong player - invalid state: ${e.message}")
        }
    }
}
