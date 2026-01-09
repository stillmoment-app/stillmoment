package com.stillmoment.infrastructure.audio

import com.stillmoment.R
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GongSound
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
    private val logger: LoggerProtocol
) {
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
    }

    private var gongPlayer: MediaPlayerProtocol? = null
    private var backgroundPlayer: MediaPlayerProtocol? = null
    private var previewPlayer: MediaPlayerProtocol? = null
    private var backgroundPreviewPlayer: MediaPlayerProtocol? = null
    private var backgroundPreviewJob: Job? = null
    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var targetVolume: Float = DEFAULT_AMBIENT_VOLUME

    companion object {
        private const val TAG = "AudioService"

        /** Duration for fade in effect (3 seconds for smooth meditation experience) */
        private const val FADE_IN_DURATION_MS = 3000L

        /** Duration for background preview before fade-out starts */
        private const val BACKGROUND_PREVIEW_DURATION_MS = 3000L

        /** Duration for fade-out effect */
        private const val FADE_OUT_DURATION_MS = 500L

        /** Number of steps for fade-out animation */
        private const val FADE_OUT_STEPS = 10

        /** Default volume for ambient/background sounds (0.0 to 1.0) */
        private const val DEFAULT_AMBIENT_VOLUME = 0.15f

        /**
         * Maps a background sound ID to its resource ID.
         * @param soundId The sound identifier ("silent" or "forest")
         * @return Resource ID or null for silent/unknown sounds
         */
        fun getBackgroundSoundResourceId(soundId: String): Int? = when (soundId) {
            "forest" -> R.raw.forest_ambience
            "silent" -> null
            else -> null
        }
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
            val clampedVolume = volume.coerceIn(0f, 1f)
            gongPlayer = mediaPlayerFactory.createFromResource(gongSound.rawResId)?.apply {
                setVolume(clampedVolume, clampedVolume)
                setOnCompletionListener {
                    release()
                    gongPlayer = null
                }
                start()
            }
            logger.d(TAG, "Playing gong sound: ${gongSound.id}, volume: $clampedVolume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play gong - invalid state: ${e.message}")
        }
    }

    /**
     * Play interval gong sound.
     *
     * @param volume Playback volume (0.0 to 1.0), defaults to 1.0
     */
    fun playIntervalGong(volume: Float = 1.0f) {
        try {
            releaseGongPlayer()
            val clampedVolume = volume.coerceIn(0f, 1f)
            gongPlayer = mediaPlayerFactory.createFromResource(R.raw.interval)?.apply {
                setVolume(clampedVolume, clampedVolume)
                setOnCompletionListener {
                    release()
                    gongPlayer = null
                }
                start()
            }
            logger.d(TAG, "Playing interval gong sound, volume: $clampedVolume")
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
    fun playGongPreview(soundId: String, volume: Float = 1.0f) {
        try {
            // Stop any previous previews (mutual exclusion: gong and background)
            stopGongPreview()
            stopBackgroundPreview()

            val gongSound = GongSound.findOrDefault(soundId)
            val clampedVolume = volume.coerceIn(0f, 1f)
            previewPlayer = mediaPlayerFactory.createFromResource(gongSound.rawResId)?.apply {
                setVolume(clampedVolume, clampedVolume)
                setOnCompletionListener {
                    release()
                    previewPlayer = null
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
    fun stopGongPreview() {
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
    }

    // MARK: - Background Preview

    /**
     * Play a background sound preview. Plays for 3 seconds with fade-out.
     * Automatically stops any previous preview (gong or background).
     *
     * @param soundId ID of the background sound to preview ("silent" or "forest")
     * @param volume Playback volume (0.0 to 1.0)
     */
    fun playBackgroundPreview(soundId: String, volume: Float) {
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
            backgroundPreviewPlayer = mediaPlayerFactory.createFromResource(resourceId)?.apply {
                setVolume(volume, volume)
                setOnCompletionListener {
                    release()
                    backgroundPreviewPlayer = null
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
    fun stopBackgroundPreview() {
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
            logger.d(TAG, "Background preview fade-out complete")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to stop background preview after fade - invalid state: ${e.message}")
        }
    }

    // MARK: - Background Audio

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

    // MARK: - Lifecycle

    /**
     * Release all audio resources.
     */
    fun release() {
        releaseGongPlayer()
        stopGongPreview()
        stopBackgroundPreview()
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
