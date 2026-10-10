package com.stillmoment.infrastructure.audio

import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.SimpleBasePlayer
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * Media3 player facade for the lock screen, the media notification and headset buttons.
 *
 * Plays no audio itself — guided meditations play through [AudioPlayerService]. This
 * adapter only reports what is playing (title, teacher, trimmed length, position,
 * play/pause) to the [androidx.media3.session.MediaSession] and forwards the commands
 * it receives (play, pause, seek, stop) to [MediaSessionManager.MediaSessionCallback].
 *
 * Positions and the length are relative to the trimmed range (shared-105); the
 * conversion to file time happens in [AudioPlayerService].
 *
 * Must be used on the main thread (the application looper of the session).
 */
@OptIn(UnstableApi::class)
internal class GuidedMeditationSessionPlayer(
    looper: Looper,
    private val callback: MediaSessionManager.MediaSessionCallback
) : SimpleBasePlayer(looper) {
    private var metadata: MediaMetadata? = null
    private var playing = false
    private var positionMs = 0L
    private var durationMs = 0L

    /** Sets the title and teacher shown on the lock screen and in the notification. */
    fun updateMetadata(title: String, teacher: String) {
        metadata =
            MediaMetadata.Builder()
                .setTitle(title)
                .setArtist(teacher)
                .build()
        invalidateState()
    }

    /**
     * Updates play/pause state and progress.
     *
     * @param isPlaying Whether the meditation is playing
     * @param positionMs Position relative to the trim start
     * @param durationMs Effective (trimmed) length
     */
    fun updatePlayback(isPlaying: Boolean, positionMs: Long, durationMs: Long) {
        playing = isPlaying
        this.positionMs = positionMs.coerceAtLeast(0L)
        this.durationMs = durationMs.coerceAtLeast(0L)
        invalidateState()
    }

    override fun getState(): State {
        val currentMetadata = metadata ?: return idleState()
        val item =
            MediaItemData.Builder(MEDIA_ITEM_ID)
                .setMediaItem(
                    MediaItem.Builder()
                        .setMediaId(MEDIA_ITEM_ID)
                        .setMediaMetadata(currentMetadata)
                        .build()
                )
                .setDurationUs(Util.msToUs(durationMs))
                .setIsSeekable(true)
                .build()
        return State.Builder()
            .setAvailableCommands(AVAILABLE_COMMANDS)
            .setPlaylist(listOf(item))
            .setPlaybackState(Player.STATE_READY)
            .setPlayWhenReady(playing, Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST)
            .setContentPositionMs(positionMs)
            .build()
    }

    private fun idleState(): State = State.Builder()
        .setAvailableCommands(IDLE_COMMANDS)
        .setPlaybackState(Player.STATE_IDLE)
        .build()

    override fun handleSetPlayWhenReady(playWhenReady: Boolean): ListenableFuture<*> {
        if (playWhenReady) {
            callback.onPlay()
        } else {
            callback.onPause()
        }
        return Futures.immediateVoidFuture()
    }

    override fun handleSeek(mediaItemIndex: Int, positionMs: Long, seekCommand: Int): ListenableFuture<*> {
        val target = if (positionMs == C.TIME_UNSET) 0L else positionMs.coerceAtLeast(0L)
        callback.onSeekTo(target)
        return Futures.immediateVoidFuture()
    }

    override fun handleStop(): ListenableFuture<*> {
        callback.onStop()
        return Futures.immediateVoidFuture()
    }

    override fun handleRelease(): ListenableFuture<*> = Futures.immediateVoidFuture()

    private companion object {
        const val MEDIA_ITEM_ID = "guided-meditation"

        val AVAILABLE_COMMANDS: Player.Commands =
            Player.Commands.Builder()
                .addAll(
                    Player.COMMAND_PLAY_PAUSE,
                    Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM,
                    Player.COMMAND_STOP,
                    Player.COMMAND_GET_CURRENT_MEDIA_ITEM,
                    Player.COMMAND_GET_METADATA,
                    Player.COMMAND_GET_TIMELINE,
                    Player.COMMAND_RELEASE
                )
                .build()

        val IDLE_COMMANDS: Player.Commands =
            Player.Commands.Builder()
                .add(Player.COMMAND_RELEASE)
                .build()
    }
}
