package com.stillmoment.infrastructure.audio

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

/**
 * Foreground service for guided meditation audio playback.
 *
 * This service:
 * - Keeps the app alive during background audio playback
 * - Displays a persistent notification with media controls
 * - Handles media button events from notifications and lock screen
 * - Integrates with MediaSession for system-wide media control
 *
 * The service delegates actual playback to AudioPlayerService and uses
 * MediaSessionManager for system integration.
 */
@AndroidEntryPoint
class MeditationPlayerForegroundService : Service() {
    @Inject
    lateinit var audioPlayerService: AudioPlayerService

    @Inject
    lateinit var notificationManager: MeditationNotificationManager

    @Inject
    lateinit var mediaSessionManager: MediaSessionManager

    private val mediaButtonReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    MeditationNotificationManager.ACTION_PLAY -> {
                        audioPlayerService.resume()
                    }
                    MeditationNotificationManager.ACTION_PAUSE -> {
                        audioPlayerService.pause()
                    }
                    MeditationNotificationManager.ACTION_STOP -> {
                        audioPlayerService.stop()
                        stopSelf()
                    }
                }
            }
        }

    override fun onCreate() {
        super.onCreate()

        // Register broadcast receiver for notification button events
        val filter =
            IntentFilter().apply {
                addAction(MeditationNotificationManager.ACTION_PLAY)
                addAction(MeditationNotificationManager.ACTION_PAUSE)
                addAction(MeditationNotificationManager.ACTION_STOP)
            }
        ContextCompat.registerReceiver(
            this,
            mediaButtonReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val meditationJson = intent.getStringExtra(EXTRA_MEDITATION)
                if (meditationJson != null) {
                    startForegroundWithNotification()
                }
            }
            ACTION_UPDATE -> {
                updateNotification()
            }
            ACTION_STOP -> {
                stopForegroundAndService()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        try {
            unregisterReceiver(mediaButtonReceiver)
        } catch (e: IllegalArgumentException) {
            Log.d(TAG, "Media button receiver was not registered", e)
        }
        super.onDestroy()
    }

    private fun startForegroundWithNotification() {
        val meditation = audioPlayerService.currentMeditation ?: return
        val mediaSession = mediaSessionManager.mediaSession ?: return
        val isPlaying = audioPlayerService.playbackState.value.isPlaying

        val notification =
            notificationManager.buildNotification(
                meditation = meditation,
                isPlaying = isPlaying,
                mediaSession = mediaSession
            )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceCompat.startForeground(
                this,
                MeditationNotificationManager.NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(MeditationNotificationManager.NOTIFICATION_ID, notification)
        }
    }

    private fun updateNotification() {
        val meditation = audioPlayerService.currentMeditation ?: return
        val mediaSession = mediaSessionManager.mediaSession ?: return
        val isPlaying = audioPlayerService.playbackState.value.isPlaying

        val notification =
            notificationManager.buildNotification(
                meditation = meditation,
                isPlaying = isPlaying,
                mediaSession = mediaSession
            )

        notificationManager.showNotification(notification)
    }

    private fun stopForegroundAndService() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    companion object {
        private const val TAG = "MeditationPlayerService"
        const val ACTION_START = "com.stillmoment.MEDITATION_START"
        const val ACTION_UPDATE = "com.stillmoment.MEDITATION_UPDATE"
        const val ACTION_STOP = "com.stillmoment.MEDITATION_STOP"
        const val EXTRA_MEDITATION = "meditation"

        /**
         * Starts the foreground service for meditation playback.
         */
        fun start(context: Context, meditationJson: String) {
            val intent =
                Intent(context, MeditationPlayerForegroundService::class.java).apply {
                    action = ACTION_START
                    putExtra(EXTRA_MEDITATION, meditationJson)
                }
            ContextCompat.startForegroundService(context, intent)
        }

        /**
         * Updates the notification (e.g., when play/pause state changes).
         */
        fun update(context: Context) {
            val intent =
                Intent(context, MeditationPlayerForegroundService::class.java).apply {
                    action = ACTION_UPDATE
                }
            context.startService(intent)
        }

        /**
         * Stops the foreground service.
         */
        fun stop(context: Context) {
            val intent =
                Intent(context, MeditationPlayerForegroundService::class.java).apply {
                    action = ACTION_STOP
                }
            context.startService(intent)
        }
    }
}
