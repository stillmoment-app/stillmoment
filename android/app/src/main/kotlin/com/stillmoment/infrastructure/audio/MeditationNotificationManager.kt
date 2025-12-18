package com.stillmoment.infrastructure.audio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.support.v4.media.session.MediaSessionCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import com.stillmoment.MainActivity
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages media notifications for guided meditation playback.
 *
 * Creates and updates notifications with:
 * - Now Playing info (title, artist)
 * - Play/Pause controls
 * - Integration with MediaSession for lock screen display
 *
 * Uses MediaStyle notification for proper media control appearance.
 */
@Singleton
class MeditationNotificationManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannel()
    }

    /**
     * Creates the notification channel for meditation playback.
     * Required for Android 8.0+ (API 26+).
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = CHANNEL_DESCRIPTION
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Builds a media notification for the given meditation.
     *
     * @param meditation The meditation being played
     * @param isPlaying Whether audio is currently playing
     * @param mediaSession The MediaSession for lock screen integration
     * @return A configured notification ready for display
     */
    fun buildNotification(
        meditation: GuidedMeditation,
        isPlaying: Boolean,
        mediaSession: MediaSessionCompat
    ): Notification {
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Play/Pause action
        val playPauseAction = NotificationCompat.Action(
            if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play,
            if (isPlaying) "Pause" else "Play",
            createMediaPendingIntent(if (isPlaying) ACTION_PAUSE else ACTION_PLAY)
        )

        // Stop action
        val stopAction = NotificationCompat.Action(
            R.drawable.ic_notification,
            "Stop",
            createMediaPendingIntent(ACTION_STOP)
        )

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(meditation.effectiveName)
            .setContentText(meditation.effectiveTeacher)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(contentIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(isPlaying)
            .addAction(playPauseAction)
            .addAction(stopAction)
            .setStyle(
                MediaStyle()
                    .setMediaSession(mediaSession.sessionToken)
                    .setShowActionsInCompactView(0) // Show play/pause in compact view
            )
            .build()
    }

    /**
     * Shows or updates the notification.
     *
     * @param notification The notification to display
     */
    fun showNotification(notification: Notification) {
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    /**
     * Hides the notification.
     */
    fun hideNotification() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun createMediaPendingIntent(action: String): PendingIntent {
        val intent = Intent(action).apply {
            setPackage(context.packageName)
        }
        return PendingIntent.getBroadcast(
            context,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    companion object {
        const val CHANNEL_ID = "meditation_playback"
        const val CHANNEL_NAME = "Meditation Playback"
        const val CHANNEL_DESCRIPTION = "Controls for guided meditation playback"
        const val NOTIFICATION_ID = 1001

        const val ACTION_PLAY = "com.stillmoment.ACTION_PLAY"
        const val ACTION_PAUSE = "com.stillmoment.ACTION_PAUSE"
        const val ACTION_STOP = "com.stillmoment.ACTION_STOP"
    }
}
