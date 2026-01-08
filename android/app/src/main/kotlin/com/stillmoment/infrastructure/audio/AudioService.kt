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
    private var targetVolume: Float = DEFAULT_AMBIENT_VOLUME

    companion object {
        private const val TAG = "AudioService"

        /** Duration for fade in effect (3 seconds for smooth meditation experience) */
        private const val FADE_IN_DURATION_MS = 3000L

        /** Default volume for ambient/background sounds (0.0 to 1.0) */
        private const val DEFAULT_AMBIENT_VOLUME = 0.15f
    }

    // MARK: - Gong Playback

    /**
     * Play the start/completion gong sound with configurable sound.
     *
     * @param soundId ID of the gong sound to play (default: classic-bowl)
     */
    fun playGong(soundId: String = GongSound.DEFAULT_SOUND_ID) {
        try {
            releaseGongPlayer()
            val gongSound = GongSound.findOrDefault(soundId)
            gongPlayer = mediaPlayerFactory.createFromResource(gongSound.rawResId)?.apply {
                setOnCompletionListener {
                    release()
                    gongPlayer = null
                }
                start()
            }
            logger.d(TAG, "Playing gong sound: ${gongSound.id}")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play gong - invalid state: ${e.message}")
        }
    }

    /**
     * Play interval gong sound.
     */
    fun playIntervalGong() {
        try {
            releaseGongPlayer()
            gongPlayer = mediaPlayerFactory.createFromResource(R.raw.interval)?.apply {
                setOnCompletionListener {
                    release()
                    gongPlayer = null
                }
                start()
            }
            logger.d(TAG, "Playing interval gong sound")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play interval gong - invalid state: ${e.message}")
        }
    }

    /**
     * Play a gong sound preview. Automatically stops any previous preview.
     * Uses a separate player to avoid interfering with timer playback.
     *
     * @param soundId ID of the gong sound to preview
     */
    fun playGongPreview(soundId: String) {
        try {
            stopGongPreview()
            val gongSound = GongSound.findOrDefault(soundId)
            previewPlayer = mediaPlayerFactory.createFromResource(gongSound.rawResId)?.apply {
                setOnCompletionListener {
                    release()
                    previewPlayer = null
                }
                start()
            }
            logger.d(TAG, "Playing gong preview: ${gongSound.id}")
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

    // MARK: - Background Audio

    /**
     * Start background audio loop with fade in.
     * Requests exclusive audio session before starting playback.
     *
     * @param soundId The sound identifier ("silent" or "forest")
     */
    fun startBackgroundAudio(soundId: String) {
        try {
            // Request exclusive audio session
            if (!coordinator.requestAudioSession(AudioSource.TIMER)) {
                logger.w(TAG, "Failed to acquire audio session for background audio")
                return
            }

            stopBackgroundAudioInternal()

            val resourceId =
                when (soundId) {
                    "forest" -> R.raw.forest_ambience
                    else -> R.raw.silence // Default to silence
                }

            targetVolume = DEFAULT_AMBIENT_VOLUME

            backgroundPlayer = mediaPlayerFactory.createFromResource(resourceId)?.apply {
                isLooping = true
                setVolume(0f, 0f) // Start at 0 for fade in
                start()
            }

            // Fade in to target volume
            fadeToVolume(targetVolume)
            logger.d(TAG, "Started background audio with fade in: $soundId")
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
        stopBackgroundAudio()
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
