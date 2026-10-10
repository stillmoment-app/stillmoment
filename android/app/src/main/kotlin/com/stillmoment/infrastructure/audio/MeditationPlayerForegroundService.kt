package com.stillmoment.infrastructure.audio

import android.app.Notification
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

/**
 * Foreground service for guided meditation audio playback.
 *
 * This service:
 * - Keeps the app alive during background audio playback
 * - Displays a persistent notification with media controls
 * - Handles the play/pause action of the notification (Android 12 and older)
 *
 * Lifecycle: started only via [MeditationPlayerServiceLauncher]. Every start calls
 * [startForeground] right away — with a minimal notification if the meditation is already
 * gone — so Android never sees a foreground-service start without a notification. The
 * service then follows [AudioPlayerService.nowPlaying] and play/pause state: it updates the
 * notification and stops itself once nothing is playing any more. Nobody sends it stop or
 * update intents.
 *
 * Lock screen controls and headset buttons reach AudioPlayerService through the Media3
 * session of MediaSessionManager, not through this service.
 */
@AndroidEntryPoint
class MeditationPlayerForegroundService : Service() {
    @Inject
    lateinit var audioPlayerService: AudioPlayerService

    @Inject
    lateinit var notificationManager: MeditationNotificationManager

    @Inject
    lateinit var mediaSessionManager: MediaSessionManager

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var observeJob: Job? = null
    private var lastStartId = 0

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
                }
            }
        }

    override fun onCreate() {
        super.onCreate()

        // Register broadcast receiver for the notification's play/pause action
        val filter =
            IntentFilter().apply {
                addAction(MeditationNotificationManager.ACTION_PLAY)
                addAction(MeditationNotificationManager.ACTION_PAUSE)
            }
        ContextCompat.registerReceiver(
            this,
            mediaButtonReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        lastStartId = startId

        // Always go foreground first: started via startForegroundService, Android requires
        // it even if the meditation already stopped in the meantime.
        val isPlaying = audioPlayerService.playbackState.value.isPlaying
        val notification =
            buildMeditationNotification(isPlaying) ?: notificationManager.buildPlaceholderNotification()
        startForegroundCompat(notification)

        if (observeJob == null) {
            observeJob = scope.launch { followPlayback() }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        scope.cancel()
        try {
            unregisterReceiver(mediaButtonReceiver)
        } catch (e: IllegalArgumentException) {
            Log.d(TAG, "Media button receiver was not registered", e)
        }
        super.onDestroy()
    }

    /**
     * Updates the notification on play/pause changes; stops the service once the meditation
     * stopped, ended or failed (nowPlaying == null).
     */
    private suspend fun followPlayback() {
        combine(
            audioPlayerService.nowPlaying,
            audioPlayerService.playbackState.map { it.isPlaying }.distinctUntilChanged()
        ) { meditation, isPlaying -> meditation to isPlaying }
            .collect { (meditation, isPlaying) ->
                if (meditation == null) {
                    stopForegroundAndService()
                } else {
                    buildMeditationNotification(isPlaying)?.let { notificationManager.showNotification(it) }
                }
            }
    }

    private fun buildMeditationNotification(isPlaying: Boolean): Notification? {
        val meditation = audioPlayerService.currentMeditation ?: return null
        val mediaSession = mediaSessionManager.mediaSession ?: return null
        return notificationManager.buildNotification(
            meditation = meditation,
            isPlaying = isPlaying,
            mediaSession = mediaSession
        )
    }

    private fun startForegroundCompat(notification: Notification) {
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

    private fun stopForegroundAndService() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        // Only stops if no newer start is pending (a new meditation started meanwhile).
        stopSelf(lastStartId)
    }

    companion object {
        private const val TAG = "MeditationPlayerService"

        /**
         * Starts the foreground service. Use [MeditationPlayerServiceLauncher], which handles
         * Android refusing the start from the background.
         */
        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, MeditationPlayerForegroundService::class.java)
            )
        }
    }
}
