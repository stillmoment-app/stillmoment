package com.stillmoment.domain.services

import android.net.Uri
import kotlinx.coroutines.flow.StateFlow

/**
 * Playback state for the audio player.
 */
data class PlaybackState(
    val isPlaying: Boolean = false,
    val currentPosition: Long = 0L,
    val duration: Long = 0L,
    val error: String? = null,
) {
    val progress: Float
        get() = if (duration > 0) currentPosition.toFloat() / duration else 0f
}

/**
 * Protocol for audio playback service.
 *
 * Defines the contract for playing guided meditation audio files.
 * Implementation should handle audio focus, background playback,
 * and MediaSession integration.
 */
interface AudioPlayerServiceProtocol {
    /**
     * Current playback state as a reactive flow.
     */
    val playbackState: StateFlow<PlaybackState>

    /**
     * Plays audio from the given URI.
     *
     * @param uri Content URI of the audio file
     * @param duration Expected duration in milliseconds (for progress calculation)
     */
    fun play(uri: Uri, duration: Long,)

    /**
     * Pauses the current playback.
     */
    fun pause()

    /**
     * Resumes paused playback.
     */
    fun resume()

    /**
     * Seeks to the specified position.
     *
     * @param position Position in milliseconds
     */
    fun seekTo(position: Long)

    /**
     * Stops playback and releases resources.
     */
    fun stop()

    /**
     * Registers a callback for playback completion.
     *
     * @param callback Called when playback completes naturally
     */
    fun setOnCompletionListener(callback: () -> Unit)
}
