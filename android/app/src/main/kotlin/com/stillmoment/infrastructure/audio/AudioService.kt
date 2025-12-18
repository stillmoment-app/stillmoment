package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.util.Log
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
class AudioService @Inject constructor(
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

    private val audioAttributes = AudioAttributes.Builder()
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
            gongPlayer = MediaPlayer.create(context, R.raw.completion).apply {
                setAudioAttributes(audioAttributes)
                setOnCompletionListener {
                    it.release()
                    gongPlayer = null
                }
                start()
            }
            Log.d(TAG, "Playing gong sound")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play gong: ${e.message}")
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
     * Start background audio loop.
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

            val resourceId = when (soundId) {
                "forest" -> R.raw.forest_ambience
                else -> R.raw.silence // Default to silence
            }

            val volume = when (soundId) {
                "forest" -> 0.15f
                else -> 0.15f // Silent ambience at low volume
            }

            backgroundPlayer = MediaPlayer.create(context, resourceId).apply {
                setAudioAttributes(audioAttributes)
                isLooping = true
                setVolume(volume, volume)
                start()
            }
            Log.d(TAG, "Started background audio: $soundId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start background audio: ${e.message}")
        }
    }

    /**
     * Stop background audio and release the audio session.
     */
    fun stopBackgroundAudio() {
        stopBackgroundAudioInternal()
        coordinator.releaseAudioSession(AudioSource.TIMER)
    }

    /**
     * Internal method to stop background audio without releasing the session.
     * Used by the conflict handler to stop playback when another source takes over.
     */
    private fun stopBackgroundAudioInternal() {
        try {
            backgroundPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            backgroundPlayer = null
            Log.d(TAG, "Stopped background audio")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop background audio: ${e.message}")
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
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release gong player: ${e.message}")
        }
    }

    companion object {
        private const val TAG = "AudioService"
    }
}
