package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import com.stillmoment.domain.services.MeditationGongPlayerProtocol
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Plays the start/end gong for guided meditations (shared-106).
 *
 * Mirrors iOS' MeditationGongPlayer: a small, dedicated player that rings the
 * gong via [MediaPlayerFactoryProtocol] and reports completion, but never
 * requests or releases the GUIDED_MEDITATION audio session. The session
 * lifecycle stays with [com.stillmoment.infrastructure.audio.AudioPlayerService]
 * so the gong is audible while the screen is locked.
 *
 * Vibration is intentionally not handled here: meditation gongs exclude the
 * vibration option (the editor picker filters it out), unlike the timer gong.
 */
@Singleton
class MeditationGongPlayer
@Inject
constructor(
    private val mediaPlayerFactory: MediaPlayerFactoryProtocol,
    private val logger: LoggerProtocol
) : MeditationGongPlayerProtocol {
    private var gongPlayer: MediaPlayerProtocol? = null

    override fun play(soundId: String, volume: Float, onComplete: () -> Unit) {
        releasePlayer()
        try {
            val gongSound = GongSound.findOrDefault(soundId)
            val resourceId = AudioService.resolveRawResourceId(gongSound.rawResourceName)
            val clampedVolume = volume.coerceIn(0f, 1f)

            val player = mediaPlayerFactory.createFromResource(resourceId)
            if (player == null) {
                logger.e(TAG, "Failed to create meditation gong player: ${gongSound.id}")
                onComplete()
                return
            }

            // Assign before start() so a failing start() still leaves the player
            // tracked and releasePlayer() can clean it up in the catch block below.
            gongPlayer = player
            player.setVolume(clampedVolume, clampedVolume)
            player.setOnCompletionListener {
                releasePlayer()
                onComplete()
            }
            player.start()
            logger.d(TAG, "Playing meditation gong: ${gongSound.id}, volume: $clampedVolume")
        } catch (e: IllegalStateException) {
            logger.e(TAG, "Failed to play meditation gong - invalid state: ${e.message}")
            releasePlayer()
            onComplete()
        }
    }

    override fun stop() {
        // Releasing without invoking the completion listener intentionally drops
        // the pending callback (documented), mirroring iOS' AVAudioPlayer.stop().
        releasePlayer()
    }

    private fun releasePlayer() {
        gongPlayer?.let { player ->
            try {
                if (player.isPlaying) {
                    player.stop()
                }
            } catch (e: IllegalStateException) {
                logger.e(TAG, "Failed to stop meditation gong - invalid state: ${e.message}")
            }
            try {
                player.release()
            } catch (e: IllegalStateException) {
                logger.e(TAG, "Failed to release meditation gong - invalid state: ${e.message}")
            }
        }
        gongPlayer = null
    }

    companion object {
        private const val TAG = "MeditationGongPlayer"
    }
}
