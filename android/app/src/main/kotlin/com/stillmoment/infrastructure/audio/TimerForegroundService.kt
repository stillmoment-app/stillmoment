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
import androidx.core.app.NotificationCompat
import com.stillmoment.MainActivity
import com.stillmoment.R
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

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

    @Inject
    lateinit var customAudioRepository: CustomAudioRepository

    @Inject
    lateinit var logger: LoggerProtocol

    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private var currentSoundId: String = "silent"
    private var currentSoundVolume: Float = DEFAULT_SOUND_VOLUME
    private var currentGongSoundId: String = "classic-bowl"
    private var currentGongVolume: Float = 1.0f
    private var isRunning = false

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        logger.d(TAG, "Service created")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let { handleAction(it) }
        return START_STICKY
    }

    private fun handleAction(intent: Intent) {
        when (intent.action) {
            ACTION_START -> handleStart(intent)
            ACTION_PLAY_GONG -> handlePlayGong(intent)
            ACTION_PLAY_INTERVAL_GONG -> handlePlayIntervalGong(intent)
            ACTION_PLAY_INTRODUCTION -> handlePlayIntroduction(intent)
            ACTION_STOP_INTRODUCTION -> audioService.stopIntroduction()
            ACTION_UPDATE_BACKGROUND_AUDIO -> handleUpdateBackgroundAudio(intent)
            ACTION_PAUSE_AUDIO -> audioService.pauseBackgroundAudio()
            ACTION_RESUME_AUDIO -> audioService.resumeBackgroundAudio()
            ACTION_STOP -> stopTimer()
        }
    }

    private fun handleStart(intent: Intent) {
        val soundId = intent.getStringExtra(EXTRA_SOUND_ID) ?: "silent"
        val soundVolume = intent.getFloatExtra(EXTRA_SOUND_VOLUME, DEFAULT_SOUND_VOLUME)
        val gongSoundId = intent.getStringExtra(EXTRA_GONG_SOUND_ID) ?: "classic-bowl"
        val gongVolume = intent.getFloatExtra(EXTRA_GONG_VOLUME, 1.0f)
        startTimer(soundId, soundVolume, gongSoundId, gongVolume)
    }

    private fun handlePlayGong(intent: Intent) {
        val gongSoundId = intent.getStringExtra(EXTRA_GONG_SOUND_ID) ?: currentGongSoundId
        val gongVolume = intent.getFloatExtra(EXTRA_GONG_VOLUME, currentGongVolume)
        audioService.playGong(gongSoundId, gongVolume)
    }

    private fun handlePlayIntervalGong(intent: Intent) {
        val gongSoundId = intent.getStringExtra(EXTRA_GONG_SOUND_ID) ?: currentGongSoundId
        val gongVolume = intent.getFloatExtra(EXTRA_GONG_VOLUME, currentGongVolume)
        audioService.playIntervalGong(gongSoundId, gongVolume)
    }

    private fun handlePlayIntroduction(intent: Intent) {
        val introductionId = intent.getStringExtra(EXTRA_INTRODUCTION_ID) ?: return
        val introduction = Introduction.find(introductionId)
        if (introduction != null) {
            // Built-in introduction
            val resourceName = introduction.audioFilename(Introduction.currentLanguage) ?: return
            audioService.playIntroduction(resourceName)
        } else {
            // Custom introduction: resolve file path asynchronously
            serviceScope.launch {
                val filePath = customAudioRepository.getFilePath(introductionId)
                if (filePath != null) {
                    audioService.playIntroductionFromFile(filePath)
                } else {
                    logger.w(TAG, "Custom introduction not found: $introductionId, skipping")
                }
            }
        }
    }

    private fun handleUpdateBackgroundAudio(intent: Intent) {
        val soundId = intent.getStringExtra(EXTRA_SOUND_ID) ?: currentSoundId
        val soundVolume = intent.getFloatExtra(EXTRA_SOUND_VOLUME, currentSoundVolume)
        currentSoundId = soundId
        currentSoundVolume = soundVolume
        startBackgroundSound(soundId, soundVolume)
    }

    override fun onDestroy() {
        stopTimer()
        serviceScope.cancel()
        super.onDestroy()
        logger.d(TAG, "Service destroyed")
    }

    private fun startTimer(soundId: String, soundVolume: Float, gongSoundId: String, gongVolume: Float) {
        if (isRunning) {
            logger.d(
                TAG,
                "Timer already running, updating sound to: $soundId, volume: $soundVolume, " +
                    "gong: $gongSoundId, gongVolume: $gongVolume"
            )
            currentGongSoundId = gongSoundId
            currentGongVolume = gongVolume
            if (currentSoundId != soundId || currentSoundVolume != soundVolume) {
                currentSoundId = soundId
                currentSoundVolume = soundVolume
                startBackgroundSound(soundId, soundVolume)
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

        // Start background audio (built-in or custom)
        startBackgroundSound(soundId, soundVolume)

        logger.d(
            TAG,
            "Timer started with sound: $soundId, volume: $soundVolume, " +
                "gong: $gongSoundId, gongVolume: $gongVolume"
        )
    }

    /**
     * Starts background sound playback, resolving custom audio IDs asynchronously.
     * Built-in sounds (silent, forest) play immediately; custom sounds require file path lookup.
     */
    private fun startBackgroundSound(soundId: String, soundVolume: Float) {
        if (AudioService.getBackgroundSoundResourceId(soundId) != null || soundId == "silent") {
            audioService.startBackgroundAudio(soundId, soundVolume)
        } else {
            serviceScope.launch {
                val filePath = customAudioRepository.getFilePath(soundId)
                if (filePath != null) {
                    audioService.startBackgroundAudioFromFile(filePath, soundVolume)
                } else {
                    logger.w(TAG, "Custom background audio not found: $soundId, falling back to silence")
                    audioService.startBackgroundAudio("silent", soundVolume)
                }
            }
        }
    }

    private fun stopTimer() {
        if (!isRunning) return

        isRunning = false
        audioService.stopIntroduction()
        audioService.stopBackgroundAudio()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()

        logger.d(TAG, "Timer stopped")
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
        const val ACTION_PLAY_INTRODUCTION = "com.stillmoment.action.PLAY_INTRODUCTION"
        const val ACTION_STOP_INTRODUCTION = "com.stillmoment.action.STOP_INTRODUCTION"
        const val ACTION_UPDATE_BACKGROUND_AUDIO = "com.stillmoment.action.UPDATE_BACKGROUND_AUDIO"
        const val ACTION_PAUSE_AUDIO = "com.stillmoment.action.PAUSE_AUDIO"
        const val ACTION_RESUME_AUDIO = "com.stillmoment.action.RESUME_AUDIO"
        const val EXTRA_SOUND_ID = "sound_id"
        const val EXTRA_SOUND_VOLUME = "sound_volume"
        const val EXTRA_GONG_SOUND_ID = "gong_sound_id"
        const val EXTRA_GONG_VOLUME = "gong_volume"
        const val EXTRA_INTRODUCTION_ID = "introduction_id"

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

        fun playIntervalGong(context: Context, gongSoundId: String, gongVolume: Float = 1.0f) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_PLAY_INTERVAL_GONG
                    putExtra(EXTRA_GONG_SOUND_ID, gongSoundId)
                    putExtra(EXTRA_GONG_VOLUME, gongVolume)
                }
            context.startService(intent)
        }

        fun playIntroduction(context: Context, introductionId: String) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_PLAY_INTRODUCTION
                    putExtra(EXTRA_INTRODUCTION_ID, introductionId)
                }
            context.startService(intent)
        }

        fun stopIntroduction(context: Context) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_STOP_INTRODUCTION
                }
            context.startService(intent)
        }

        fun updateBackgroundAudio(context: Context, soundId: String, soundVolume: Float) {
            val intent =
                Intent(context, TimerForegroundService::class.java).apply {
                    action = ACTION_UPDATE_BACKGROUND_AUDIO
                    putExtra(EXTRA_SOUND_ID, soundId)
                    putExtra(EXTRA_SOUND_VOLUME, soundVolume)
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
