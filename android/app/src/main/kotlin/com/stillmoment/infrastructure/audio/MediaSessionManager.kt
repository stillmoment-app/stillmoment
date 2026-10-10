package com.stillmoment.infrastructure.audio

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaSession
import com.stillmoment.MainActivity
import com.stillmoment.domain.models.GuidedMeditation
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Owns the Media3 [MediaSession] of a guided meditation.
 *
 * The session feeds:
 * - the lock screen (title, teacher, trimmed length, progress, play/pause, seek)
 * - the media notification (see [MeditationNotificationManager])
 * - Bluetooth and wired headset buttons (play/pause toggle)
 *
 * The session lives from the start of a meditation until it stops or ends. Audio is played
 * by [AudioPlayerService]; [GuidedMeditationSessionPlayer] only mirrors its state.
 * Media3 requires the session to be used on the main thread, so calls from other threads
 * are posted there.
 */
@Singleton
open class MediaSessionManager
@Inject
constructor(
    @ApplicationContext protected val context: Context
) {
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }
    private var session: MediaSession? = null
    private var player: GuidedMeditationSessionPlayer? = null

    /**
     * The active MediaSession, or null if not created.
     */
    val mediaSession: MediaSession?
        get() = session

    /**
     * Commands from the lock screen, the notification and headset buttons.
     * Seek positions are relative to the trimmed range (shared-105).
     */
    interface MediaSessionCallback {
        fun onPlay()

        fun onPause()

        fun onStop()

        fun onSeekTo(position: Long)
    }

    /**
     * Creates and activates a session that forwards its commands to [callback].
     * Replaces a previous session.
     */
    open fun createSession(callback: MediaSessionCallback) {
        onMainThread {
            releaseOnMainThread()
            val newPlayer = GuidedMeditationSessionPlayer(Looper.getMainLooper(), callback)
            player = newPlayer
            session =
                MediaSession.Builder(context, newPlayer)
                    .setId(SESSION_ID)
                    .setSessionActivity(openAppIntent())
                    .build()
        }
    }

    /**
     * Shows the meditation's title and teacher.
     */
    open fun updateMetadata(meditation: GuidedMeditation) {
        onMainThread {
            player?.updateMetadata(title = meditation.name, teacher = meditation.teacher)
        }
    }

    /**
     * Updates play/pause state and progress.
     *
     * @param isPlaying Whether audio is currently playing
     * @param position Position relative to the trim start in milliseconds
     * @param duration Effective (trimmed) length in milliseconds
     */
    open fun updatePlaybackState(isPlaying: Boolean, position: Long, duration: Long) {
        onMainThread {
            player?.updatePlayback(isPlaying = isPlaying, positionMs = position, durationMs = duration)
        }
    }

    /**
     * Releases the session; lock screen controls disappear.
     */
    open fun release() {
        onMainThread { releaseOnMainThread() }
    }

    // SimpleBasePlayer.release() is part of Media3's unstable API surface
    @OptIn(UnstableApi::class)
    private fun releaseOnMainThread() {
        session?.release()
        player?.release()
        session = null
        player = null
    }

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        context,
        0,
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    private fun onMainThread(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post(block)
        }
    }

    private companion object {
        const val SESSION_ID = "StillMomentPlayer"
    }
}
