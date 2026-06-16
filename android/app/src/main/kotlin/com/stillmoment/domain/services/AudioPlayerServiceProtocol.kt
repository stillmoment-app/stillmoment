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
    val error: String? = null
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
     * Trim points (shared-105) make playback non-destructive: playback starts at
     * [trimStartMs] (after prepare) and ends at [trimEndMs] via the progress loop,
     * triggering the same completion path as the natural file end. Positions reported
     * in [playbackState] stay in absolute file time; range-relative display is the
     * caller's concern.
     *
     * @param uri Content URI of the audio file
     * @param duration Full file duration in milliseconds (for progress calculation)
     * @param trimStartMs Playback start offset in ms, or null to start at the file start
     * @param trimEndMs Playback end offset in ms, or null to play to the file end
     */
    fun play(uri: Uri, duration: Long, trimStartMs: Long? = null, trimEndMs: Long? = null)

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
