package com.stillmoment.infrastructure.audio

import android.content.Context
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Starts [MeditationPlayerForegroundService], which shows the playback notification.
 *
 * Only starting is needed: the service follows [AudioPlayerService.nowPlaying] and stops
 * itself when the meditation stops or ends. No intents are sent to stop or update it, so
 * nothing can start a stray service from the background.
 *
 * Android refuses foreground-service starts from the background (Android 12+). The
 * meditation keeps playing then; only the notification is missing, which is logged.
 */
@Singleton
open class MeditationPlayerServiceLauncher
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) {
    open fun start() {
        try {
            MeditationPlayerForegroundService.start(context)
        } catch (e: IllegalStateException) {
            // ForegroundServiceStartNotAllowedException (API 31+) extends IllegalStateException
            logger.w(TAG, "Playback notification could not be started: ${e.message}")
        }
    }

    private companion object {
        const val TAG = "MeditationPlayerLauncher"
    }
}
