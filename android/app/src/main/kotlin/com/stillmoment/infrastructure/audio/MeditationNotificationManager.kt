package com.stillmoment.infrastructure.audio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.OptIn
import androidx.core.app.NotificationCompat
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaStyleNotificationHelper
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
 * - Now Playing info (title, teacher)
 * - Play/Pause control
 * - Integration with the Media3 MediaSession for lock screen display
 *
 * Uses Media3's MediaStyle. From Android 13 the system builds the controls (play/pause,
 * progress bar) from the session itself; the play/pause action below serves older versions.
 */
@Singleton
class MeditationNotificationManager
@Inject
constructor(
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
            val channel =
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.notification_playback_channel_name),
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = context.getString(R.string.notification_playback_channel_description)
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
    @OptIn(UnstableApi::class)
    fun buildNotification(meditation: GuidedMeditation, isPlaying: Boolean, mediaSession: MediaSession): Notification {
        val contentIntent =
            PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

        // Play/Pause action (shown by Android 12 and older; newer versions use the session)
        val playPauseAction =
            NotificationCompat.Action(
                if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play,
                context.getString(
                    if (isPlaying) R.string.accessibility_pause_button_player else R.string.accessibility_play_button
                ),
                createMediaPendingIntent(if (isPlaying) ACTION_PAUSE else ACTION_PLAY)
            )

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(meditation.name)
            .setContentText(meditation.teacher)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(contentIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(isPlaying)
            .addAction(playPauseAction)
            .setStyle(
                MediaStyleNotificationHelper.MediaStyle(mediaSession)
                    // Show play/pause in compact view
                    .setShowActionsInCompactView(0)
            )
            .build()
    }

    /**
     * Minimal notification for the rare case that the foreground service starts after the
     * meditation already stopped. Android requires a notification for every foreground
     * start; the service removes it right away.
     */
    fun buildPlaceholderNotification(): Notification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setContentTitle(context.getString(R.string.notification_playback_channel_name))
        .setSmallIcon(R.drawable.ic_notification)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .setSilent(true)
        .build()

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
        val intent =
            Intent(action).apply {
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
        const val NOTIFICATION_ID = 1001

        const val ACTION_PLAY = "com.stillmoment.ACTION_PLAY"
        const val ACTION_PAUSE = "com.stillmoment.ACTION_PAUSE"
    }
}
