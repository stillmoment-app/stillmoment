package com.stillmoment.infrastructure.audio

import android.content.Context
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import com.stillmoment.domain.models.GuidedMeditation
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages MediaSession for lock screen controls and media notifications.
 *
 * Uses MediaSessionCompat for:
 * - Lock screen Now Playing info
 * - Play/Pause controls from lock screen
 * - Notification with media controls
 * - Bluetooth/headphone button support (including wired headphones)
 *
 * IMPORTANT: ACTION_PLAY_PAUSE is enabled for wired headphone inline remotes
 * which send toggle events rather than separate play/pause events.
 */
@Singleton
class MediaSessionManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var _mediaSession: MediaSessionCompat? = null

    /**
     * The active MediaSession, or null if not created.
     */
    val mediaSession: MediaSessionCompat?
        get() = _mediaSession

    /**
     * Callbacks for media button events from lock screen/notifications/headphones.
     */
    interface MediaSessionCallback {
        fun onPlay()
        fun onPause()
        fun onStop()
        fun onSeekTo(position: Long)
    }

    /**
     * Creates and activates a MediaSession with the given callbacks.
     *
     * @param callback Handler for media button events
     * @return The created MediaSession
     */
    fun createSession(callback: MediaSessionCallback): MediaSessionCompat {
        release()

        _mediaSession = MediaSessionCompat(context, "StillMomentPlayer").apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() {
                    callback.onPlay()
                }

                override fun onPause() {
                    callback.onPause()
                }

                override fun onStop() {
                    callback.onStop()
                }

                override fun onSeekTo(pos: Long) {
                    callback.onSeekTo(pos)
                }
            })
            isActive = true
        }

        return _mediaSession!!
    }

    /**
     * Updates the Now Playing metadata for the current meditation.
     *
     * @param meditation The meditation being played
     */
    fun updateMetadata(meditation: GuidedMeditation) {
        _mediaSession?.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, meditation.effectiveName)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, meditation.effectiveTeacher)
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, meditation.duration)
                .build()
        )
    }

    /**
     * Updates the playback state for lock screen and notification display.
     *
     * @param isPlaying Whether audio is currently playing
     * @param position Current playback position in milliseconds
     * @param duration Total duration in milliseconds (unused but kept for API consistency)
     */
    fun updatePlaybackState(isPlaying: Boolean, position: Long, duration: Long) {
        val state = if (isPlaying) {
            PlaybackStateCompat.STATE_PLAYING
        } else {
            PlaybackStateCompat.STATE_PAUSED
        }

        _mediaSession?.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(state, position, 1f)
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or  // CRITICAL: For wired headphones!
                    PlaybackStateCompat.ACTION_SEEK_TO or
                    PlaybackStateCompat.ACTION_STOP
                )
                .build()
        )
    }

    /**
     * Releases the MediaSession and cleans up resources.
     */
    fun release() {
        _mediaSession?.isActive = false
        _mediaSession?.release()
        _mediaSession = null
    }
}
