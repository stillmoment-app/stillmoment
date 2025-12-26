package com.stillmoment.infrastructure.audio

import android.animation.ValueAnimator
import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.util.Log
import android.view.animation.LinearInterpolator
import com.stillmoment.R
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Audio Service for playing gong sounds and managing background audio.
 * Uses MediaPlayer for short sounds (gongs) and ExoPlayer for background loops.
 *
 * Coordinates with AudioSessionCoordinator to ensure exclusive audio access
 * when Timer and Guided Meditations features coexist.
 */
@Singleton
class AudioService
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val coordinator: AudioSessionCoordinatorProtocol
) {
    init {
        // Register conflict handler to stop background audio when another source takes over
        coordinator.registerConflictHandler(AudioSource.TIMER) {
            Log.d(TAG, "Audio conflict: stopping timer audio for other source")
            stopBackgroundAudioInternal()
        }
    }

    private var gongPlayer: MediaPlayer? = null
    private var backgroundPlayer: MediaPlayer? = null
    private var fadeAnimator: ValueAnimator? = null
    private var targetVolume: Float = DEFAULT_AMBIENT_VOLUME

    companion object {
        private const val TAG = "AudioService"

        /** Duration for fade in effect (3 seconds for smooth meditation experience) */
        private const val FADE_IN_DURATION_MS = 3000L

        /** Default volume for ambient/background sounds (0.0 to 1.0) */
        private const val DEFAULT_AMBIENT_VOLUME = 0.15f
    }

    private val audioAttributes =
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()

    // MARK: - Gong Playback

    /**
     * Play the start/completion gong sound.
     */
    fun playGong() {
        try {
            releaseGongPlayer()
            gongPlayer =
                MediaPlayer.create(context, R.raw.completion).apply {
                    setAudioAttributes(audioAttributes)
                    setOnCompletionListener {
                        it.release()
                        gongPlayer = null
                    }
                    start()
                }
            Log.d(TAG, "Playing gong sound")
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Failed to play gong - invalid state: ${e.message}")
        }
    }

    /**
     * Play interval gong (same sound, could be different in future).
     */
    fun playIntervalGong() {
        playGong()
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
                Log.w(TAG, "Failed to acquire audio session for background audio")
                return
            }

            stopBackgroundAudioInternal()

            val resourceId =
                when (soundId) {
                    "forest" -> R.raw.forest_ambience
                    else -> R.raw.silence // Default to silence
                }

            targetVolume = DEFAULT_AMBIENT_VOLUME

            backgroundPlayer =
                MediaPlayer.create(context, resourceId).apply {
                    setAudioAttributes(audioAttributes)
                    isLooping = true
                    setVolume(0f, 0f) // Start at 0 for fade in
                    start()
                }

            // Fade in to target volume
            fadeToVolume(targetVolume)
            Log.d(TAG, "Started background audio with fade in: $soundId")
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Failed to start background audio - invalid state: ${e.message}")
        }
    }

    /**
     * Stop background audio and release the audio session.
     */
    fun stopBackgroundAudio() {
        cancelFade()
        stopBackgroundAudioInternal()
        coordinator.releaseAudioSession(AudioSource.TIMER)
    }

    /**
     * Pause background audio immediately (no fade).
     * Used for "Brief Pause" during meditation.
     */
    fun pauseBackgroundAudio() {
        cancelFade()
        try {
            backgroundPlayer?.let { player ->
                if (player.isPlaying) {
                    player.pause()
                    Log.d(TAG, "Paused background audio")
                }
            }
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Failed to pause background audio - invalid state: ${e.message}")
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
                Log.d(TAG, "Resuming background audio with fade in")
            }
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Failed to resume background audio - invalid state: ${e.message}")
        }
    }

    /**
     * Internal method to stop background audio without releasing the session.
     * Used by the conflict handler to stop playback when another source takes over.
     */
    private fun stopBackgroundAudioInternal() {
        cancelFade()
        try {
            backgroundPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            backgroundPlayer = null
            Log.d(TAG, "Stopped background audio")
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Failed to stop background audio - invalid state: ${e.message}")
        }
    }

    /**
     * Animate volume from current level to target over FADE_IN_DURATION_MS.
     */
    private fun fadeToVolume(target: Float) {
        cancelFade()
        fadeAnimator =
            ValueAnimator.ofFloat(0f, target).apply {
                duration = FADE_IN_DURATION_MS
                interpolator = LinearInterpolator()
                addUpdateListener { animator ->
                    val volume = animator.animatedValue as Float
                    try {
                        backgroundPlayer?.setVolume(volume, volume)
                    } catch (e: IllegalStateException) {
                        Log.e(TAG, "Failed to set volume during fade - invalid state: ${e.message}")
                    }
                }
                start()
            }
    }

    /**
     * Cancel any running fade animation.
     */
    private fun cancelFade() {
        fadeAnimator?.cancel()
        fadeAnimator = null
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
            Log.e(TAG, "Failed to release gong player - invalid state: ${e.message}")
        }
    }
}
