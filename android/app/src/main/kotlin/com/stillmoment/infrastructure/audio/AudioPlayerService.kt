package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.PlaybackState
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Audio player service for guided meditation playback.
 *
 * Uses Android MediaPlayer for audio playback with support for:
 * - Play, pause, resume, seek controls
 * - Progress tracking via StateFlow
 * - Audio focus handling
 * - Completion callbacks
 *
 * Note: MediaSession and lock screen controls are added in android-010.
 */
@Singleton
class AudioPlayerService @Inject constructor(
    @ApplicationContext private val context: Context
) : AudioPlayerServiceProtocol {

    private var mediaPlayer: MediaPlayer? = null
    private var onCompletionCallback: (() -> Unit)? = null

    private val _playbackState = MutableStateFlow(PlaybackState())
    override val playbackState: StateFlow<PlaybackState> = _playbackState.asStateFlow()

    private val handler = Handler(Looper.getMainLooper())
    private val progressUpdateRunnable = object : Runnable {
        override fun run() {
            updateProgress()
            if (_playbackState.value.isPlaying) {
                handler.postDelayed(this, PROGRESS_UPDATE_INTERVAL)
            }
        }
    }

    override fun play(uri: Uri, duration: Long) {
        stop()

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build()
                )
                setDataSource(context, uri)
                setOnPreparedListener { mp ->
                    mp.start()
                    _playbackState.update {
                        it.copy(
                            isPlaying = true,
                            currentPosition = 0L,
                            duration = duration,
                            error = null
                        )
                    }
                    startProgressUpdates()
                }
                setOnCompletionListener {
                    _playbackState.update {
                        it.copy(
                            isPlaying = false,
                            currentPosition = duration
                        )
                    }
                    stopProgressUpdates()
                    onCompletionCallback?.invoke()
                }
                setOnErrorListener { _, what, extra ->
                    _playbackState.update {
                        it.copy(
                            isPlaying = false,
                            error = "Playback error: $what, $extra"
                        )
                    }
                    stopProgressUpdates()
                    true
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            _playbackState.update {
                it.copy(
                    isPlaying = false,
                    error = "Failed to play: ${e.message}"
                )
            }
        }
    }

    override fun pause() {
        mediaPlayer?.let { player ->
            if (player.isPlaying) {
                player.pause()
                _playbackState.update { it.copy(isPlaying = false) }
                stopProgressUpdates()
            }
        }
    }

    override fun resume() {
        mediaPlayer?.let { player ->
            if (!player.isPlaying) {
                player.start()
                _playbackState.update { it.copy(isPlaying = true) }
                startProgressUpdates()
            }
        }
    }

    override fun seekTo(position: Long) {
        mediaPlayer?.seekTo(position.toInt())
        _playbackState.update { it.copy(currentPosition = position) }
    }

    override fun stop() {
        stopProgressUpdates()
        mediaPlayer?.apply {
            try {
                if (isPlaying) {
                    stop()
                }
                release()
            } catch (e: Exception) {
                // Ignore errors during cleanup
            }
        }
        mediaPlayer = null
        _playbackState.update {
            PlaybackState()
        }
    }

    override fun setOnCompletionListener(callback: () -> Unit) {
        onCompletionCallback = callback
    }

    private fun startProgressUpdates() {
        handler.removeCallbacks(progressUpdateRunnable)
        handler.post(progressUpdateRunnable)
    }

    private fun stopProgressUpdates() {
        handler.removeCallbacks(progressUpdateRunnable)
    }

    private fun updateProgress() {
        mediaPlayer?.let { player ->
            try {
                if (player.isPlaying) {
                    _playbackState.update {
                        it.copy(currentPosition = player.currentPosition.toLong())
                    }
                }
            } catch (e: Exception) {
                // Player may be in invalid state
            }
        }
    }

    companion object {
        private const val PROGRESS_UPDATE_INTERVAL = 100L // 100ms for smooth progress
    }
}
