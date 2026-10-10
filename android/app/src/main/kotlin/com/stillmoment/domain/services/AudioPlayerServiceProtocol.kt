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
     * The meditation shown on the lock screen and in the media notification, or null.
     * Becomes null when the meditation stops — also when stopped from outside the app
     * (lock screen, notification, headset or Bluetooth button) — or fails to load.
     */
    val nowPlaying: StateFlow<GuidedMeditation?>

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
     * Shows the meditation on the lock screen and in the media notification before its
     * audio begins — while the preparation time runs or the start gong rings.
     *
     * Must be called while the app is in the foreground (the user's tap): it starts the
     * foreground service, without which Android 15+ refuses audio focus once the screen is
     * locked. A following [play] of the same meditation keeps this presence; [stop] ends it.
     *
     * @param meditation The meditation about to play
     */
    fun announce(meditation: GuidedMeditation)

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
     * Removes the meditation from the lock screen and the media notification (ending the
     * foreground service) after it has completed, keeping the completed playback state.
     *
     * Reaching the end alone keeps the meditation shown, so the end gong can ring out with
     * the screen locked; call this once it has (or right away without an end gong).
     */
    fun endLockScreenPresence()

    /**
     * Registers a callback for playback completion.
     *
     * @param callback Called when playback completes naturally
     */
    fun setOnCompletionListener(callback: () -> Unit)
}
