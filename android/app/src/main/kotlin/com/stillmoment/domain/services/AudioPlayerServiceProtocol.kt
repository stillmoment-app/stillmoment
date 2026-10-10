package com.stillmoment.domain.services

import com.stillmoment.domain.models.GuidedMeditation
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
     * Plays a guided meditation and shows it on the lock screen and in the media
     * notification until it stops or ends.
     *
     * Trim points (shared-105) make playback non-destructive: playback starts at the
     * meditation's trim start and ends at its trim end, triggering the same completion
     * path as the natural file end. Positions reported in [playbackState] stay in absolute
     * file time; range-relative display is the caller's concern. The lock screen shows the
     * trimmed range.
     *
     * @param meditation The meditation to play
     */
    fun play(meditation: GuidedMeditation)

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
