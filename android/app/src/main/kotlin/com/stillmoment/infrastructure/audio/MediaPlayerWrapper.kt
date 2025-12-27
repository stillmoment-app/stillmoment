package com.stillmoment.infrastructure.audio

import android.media.AudioAttributes
import android.media.MediaPlayer
import com.stillmoment.domain.services.MediaPlayerProtocol

/**
 * Wrapper around Android's MediaPlayer implementing MediaPlayerProtocol.
 *
 * Provides a testable abstraction over MediaPlayer operations.
 * AudioAttributes are set by default for media playback.
 */
class MediaPlayerWrapper(
    private val mediaPlayer: MediaPlayer
) : MediaPlayerProtocol {

    init {
        mediaPlayer.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
        )
    }

    override fun start() {
        mediaPlayer.start()
    }

    override fun pause() {
        mediaPlayer.pause()
    }

    override fun stop() {
        mediaPlayer.stop()
    }

    override fun release() {
        mediaPlayer.release()
    }

    override fun seekTo(position: Int) {
        mediaPlayer.seekTo(position)
    }

    override val currentPosition: Int
        get() = mediaPlayer.currentPosition

    override val isPlaying: Boolean
        get() = mediaPlayer.isPlaying

    override fun setVolume(leftVolume: Float, rightVolume: Float) {
        mediaPlayer.setVolume(leftVolume, rightVolume)
    }

    override var isLooping: Boolean
        get() = mediaPlayer.isLooping
        set(value) {
            mediaPlayer.isLooping = value
        }

    override fun setOnPreparedListener(listener: () -> Unit) {
        mediaPlayer.setOnPreparedListener { listener() }
    }

    override fun setOnCompletionListener(listener: () -> Unit) {
        mediaPlayer.setOnCompletionListener { listener() }
    }

    override fun setOnErrorListener(listener: (what: Int, extra: Int) -> Boolean) {
        mediaPlayer.setOnErrorListener { _, what, extra -> listener(what, extra) }
    }

    override fun prepareAsync() {
        mediaPlayer.prepareAsync()
    }

    override fun setDataSource(path: String) {
        mediaPlayer.setDataSource(path)
    }

    override fun setDataSourceFromFd(fd: java.io.FileDescriptor) {
        mediaPlayer.setDataSource(fd)
    }
}
