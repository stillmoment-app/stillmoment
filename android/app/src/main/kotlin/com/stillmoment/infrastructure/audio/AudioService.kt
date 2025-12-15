package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.util.Log
import com.stillmoment.R
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Audio Service for playing gong sounds and managing background audio.
 * Uses MediaPlayer for short sounds (gongs) and ExoPlayer for background loops.
 */
@Singleton
class AudioService @Inject constructor(
    @ApplicationContext private val context: Context
) {
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
     * @param soundId The sound identifier ("silent" or "forest")
     */
    fun startBackgroundAudio(soundId: String) {
        try {
            stopBackgroundAudio()

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
     * Stop background audio.
     */
    fun stopBackgroundAudio() {
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
