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
    private var currentSoundVolume: Float = DEFAULT_SOUND_VOLUME
    private var currentGongSoundId: String = "classic-bowl"
    private var currentGongVolume: Float = 1.0f
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
                val soundVolume = intent.getFloatExtra(EXTRA_SOUND_VOLUME, DEFAULT_SOUND_VOLUME)
                val gongSoundId = intent.getStringExtra(EXTRA_GONG_SOUND_ID) ?: "classic-bowl"
                val gongVolume = intent.getFloatExtra(EXTRA_GONG_VOLUME, 1.0f)
                startTimer(soundId, soundVolume, gongSoundId, gongVolume)
            }
            ACTION_PLAY_GONG -> {
                val gongSoundId = intent?.getStringExtra(EXTRA_GONG_SOUND_ID) ?: currentGongSoundId
                val gongVolume = intent?.getFloatExtra(EXTRA_GONG_VOLUME, currentGongVolume) ?: currentGongVolume
                audioService.playGong(gongSoundId, gongVolume)
            }
            ACTION_PLAY_INTERVAL_GONG -> {
                val gongVolume = intent?.getFloatExtra(EXTRA_GONG_VOLUME, currentGongVolume) ?: currentGongVolume
                audioService.playIntervalGong(gongVolume)
            }
            ACTION_PAUSE_AUDIO -> {
                audioService.pauseBackgroundAudio()
            }
            ACTION_RESUME_AUDIO -> {
                audioService.resumeBackgroundAudio()
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

    private fun startTimer(soundId: String, soundVolume: Float, gongSoundId: String, gongVolume: Float) {
        if (isRunning) {
            Log.d(
                TAG,
                "Timer already running, updating sound to: $soundId, volume: $soundVolume, " +
                    "gong: $gongSoundId, gongVolume: $gongVolume"
            )
            currentGongSoundId = gongSoundId
            currentGongVolume = gongVolume
            if (currentSoundId != soundId || currentSoundVolume != soundVolume) {
                currentSoundId = soundId
                currentSoundVolume = soundVolume
                audioService.startBackgroundAudio(soundId, soundVolume)
            }
            return
        }

        isRunning = true
        currentSoundId = soundId
        currentSoundVolume = soundVolume
        currentGongSoundId = gongSoundId
        currentGongVolume = gongVolume

        // Start foreground with notification
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // Start background audio
        audioService.startBackgroundAudio(soundId, soundVolume)

        Log.d(
            TAG,
            "Timer started with sound: $soundId, volume: $soundVolume, " +
                "gong: $gongSoundId, gongVolume: $gongVolume"
        )
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
            val channel =
                NotificationChannel(
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
        val pendingIntent =
            PendingIntent.getActivity(
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
        private const val DEFAULT_SOUND_VOLUME = 0.15f

        const val ACTION_START = "com.stillmoment.action.START"
        const val ACTION_STOP = "com.stillmoment.action.STOP"
        const val ACTION_PLAY_GONG = "com.stillmoment.action.PLAY_GONG"
        const val ACTION_PLAY_INTERVAL_GONG = "com.stillmoment.action.PLAY_INTERVAL_GONG"
        const val ACTION_PAUSE_AUDIO = "com.stillmoment.action.PAUSE_AUDIO"
        const val ACTION_RESUME_AUDIO = "com.stillmoment.action.RESUME_AUDIO"
        const val EXTRA_SOUND_ID = "sound_id"
        const val EXTRA_SOUND_VOLUME = "sound_volume"
        const val EXTRA_GONG_SOUND_ID = "gong_sound_id"
        const val EXTRA_GONG_VOLUME = "gong_volume"

        fun startService(
            context: Context,
            soundId: String,
            soundVolume: Float = DEFAULT_SOUND_VOLUME,
            gongSoundId: String = "classic-bowl",
            gongVolume: Float = 1.0f
        ) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_START
                    putExtra(EXTRA_SOUND_ID, soundId)
                    putExtra(EXTRA_SOUND_VOLUME, soundVolume)
                    putExtra(EXTRA_GONG_SOUND_ID, gongSoundId)
                    putExtra(EXTRA_GONG_VOLUME, gongVolume)
                }
            context.startForegroundService(intent)
        }

        fun stopService(context: Context) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_STOP
                }
            context.startService(intent)
        }

        fun playGong(context: Context, gongSoundId: String = "classic-bowl", gongVolume: Float = 1.0f) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_PLAY_GONG
                    putExtra(EXTRA_GONG_SOUND_ID, gongSoundId)
                    putExtra(EXTRA_GONG_VOLUME, gongVolume)
                }
            context.startService(intent)
        }

        fun playIntervalGong(context: Context, gongVolume: Float = 1.0f) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_PLAY_INTERVAL_GONG
                    putExtra(EXTRA_GONG_VOLUME, gongVolume)
                }
            context.startService(intent)
        }

        fun pauseAudio(context: Context) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_PAUSE_AUDIO
                }
            context.startService(intent)
        }

        fun resumeAudio(context: Context) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_RESUME_AUDIO
                }
            context.startService(intent)
        }
    }
}
