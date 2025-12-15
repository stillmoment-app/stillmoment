package com.stillmoment.infrastructure.audio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.stillmoment.MainActivity
import com.stillmoment.R
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

/**
 * Foreground Service for timer background playback.
 * Keeps the timer running and audio playing when the app is in background.
 *
 * This service:
 * - Shows a persistent notification while timer is active
 * - Manages background audio playback
 * - Plays gong sounds at appropriate times
 */
@AndroidEntryPoint
class TimerForegroundService : Service() {

    @Inject
    lateinit var audioService: AudioService

    private var currentSoundId: String = "silent"
    private var isRunning = false

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d(TAG, "Service created")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val soundId = intent.getStringExtra(EXTRA_SOUND_ID) ?: "silent"
                startTimer(soundId)
            }
            ACTION_PLAY_GONG -> {
                audioService.playGong()
            }
            ACTION_PLAY_INTERVAL_GONG -> {
                audioService.playIntervalGong()
            }
            ACTION_STOP -> {
                stopTimer()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopTimer()
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }

    private fun startTimer(soundId: String) {
        if (isRunning) {
            Log.d(TAG, "Timer already running, updating sound to: $soundId")
            if (currentSoundId != soundId) {
                currentSoundId = soundId
                audioService.startBackgroundAudio(soundId)
            }
            return
        }

        isRunning = true
        currentSoundId = soundId

        // Start foreground with notification
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // Start background audio
        audioService.startBackgroundAudio(soundId)

        Log.d(TAG, "Timer started with sound: $soundId")
    }

    private fun stopTimer() {
        if (!isRunning) return

        isRunning = false
        audioService.stopBackgroundAudio()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()

        Log.d(TAG, "Timer stopped")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.notification_channel_description)
                setShowBadge(false)
                setSound(null, null)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(getString(R.string.notification_text))
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    companion object {
        private const val TAG = "TimerForegroundService"
        private const val CHANNEL_ID = "stillmoment_timer"
        private const val NOTIFICATION_ID = 1

        const val ACTION_START = "com.stillmoment.action.START"
        const val ACTION_STOP = "com.stillmoment.action.STOP"
        const val ACTION_PLAY_GONG = "com.stillmoment.action.PLAY_GONG"
        const val ACTION_PLAY_INTERVAL_GONG = "com.stillmoment.action.PLAY_INTERVAL_GONG"
        const val EXTRA_SOUND_ID = "sound_id"

        fun startService(context: Context, soundId: String) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_SOUND_ID, soundId)
            }
            context.startForegroundService(intent)
        }

        fun stopService(context: Context) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun playGong(context: Context) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_PLAY_GONG
            }
            context.startService(intent)
        }

        fun playIntervalGong(context: Context) {
            val intent = Intent(context, TimerForegroundService::class.java).apply {
                action = ACTION_PLAY_INTERVAL_GONG
            }
            context.startService(intent)
        }
    }
}
