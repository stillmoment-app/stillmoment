package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.PlaybackState
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.FileNotFoundException
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Audio player service for guided meditation playback.
 *
 * Uses Android MediaPlayer for audio playback with support for:
 * - Play, pause, resume, seek controls
 * - Progress tracking via StateFlow
 * - Audio focus handling
 * - Completion callbacks
 * - MediaSession integration for lock screen controls
 * - Foreground service with media notification
 *
 * Integrates with MediaSessionManager for:
 * - Lock screen Now Playing info
 * - Play/Pause controls from lock screen and notifications
 * - Bluetooth/headphone button support (including wired headphones with inline remote)
 */
@Singleton
class AudioPlayerService
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val mediaSessionManager: MediaSessionManager,
    private val notificationManager: MeditationNotificationManager,
) : AudioPlayerServiceProtocol {
    private var mediaPlayer: MediaPlayer? = null
    private var onCompletionCallback: (() -> Unit)? = null

    private val _playbackState = MutableStateFlow(PlaybackState())
    override val playbackState: StateFlow<PlaybackState> = _playbackState.asStateFlow()

    /**
     * The currently playing meditation, or null if nothing is playing.
     */
    var currentMeditation: GuidedMeditation? = null
        private set

    private val handler = Handler(Looper.getMainLooper())
    private val progressUpdateRunnable =
        object : Runnable {
            override fun run() {
                updateProgress()
                updateMediaSessionState()
                if (_playbackState.value.isPlaying) {
                    handler.postDelayed(this, PROGRESS_UPDATE_INTERVAL)
                }
            }
        }

    /**
     * Plays a guided meditation with full MediaSession integration.
     *
     * @param meditation The meditation to play
     */
    fun playMeditation(meditation: GuidedMeditation) {
        currentMeditation = meditation

        // Create MediaSession with callbacks
        mediaSessionManager.createSession(
            object : MediaSessionManager.MediaSessionCallback {
                override fun onPlay() = resume()

                override fun onPause() = pause()

                override fun onStop() = stop()

                override fun onSeekTo(position: Long) = seekTo(position)
            },
        )

        // Update metadata
        mediaSessionManager.updateMetadata(meditation)

        // Play the audio
        play(Uri.parse(meditation.fileUri), meditation.duration)
    }

    override fun play(uri: Uri, duration: Long,) {
        stopMediaPlayer()

        try {
            mediaPlayer =
                MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .build(),
                    )

                    // Handle different URI schemes
                    when (uri.scheme) {
                        "file" -> {
                            // Local file - use path directly
                            val path = uri.path
                            if (path == null) {
                                Log.e(TAG, "File path is null: $uri")
                                _playbackState.update {
                                    it.copy(isPlaying = false, error = "Invalid file path")
                                }
                                return
                            }
                            Log.d(TAG, "Playing local file: $path")
                            setDataSource(path)
                        }
                        "content" -> {
                            // Content URI - use FileDescriptor for reliable access
                            val pfd =
                                try {
                                    context.contentResolver.openFileDescriptor(uri, "r")
                                } catch (e: SecurityException) {
                                    Log.e(TAG, "URI permission lost: $uri", e)
                                    _playbackState.update {
                                        it.copy(isPlaying = false, error = "Permission lost - please re-import file")
                                    }
                                    return
                                } catch (e: FileNotFoundException) {
                                    Log.e(TAG, "File not found: $uri", e)
                                    _playbackState.update {
                                        it.copy(isPlaying = false, error = "File was deleted or moved")
                                    }
                                    return
                                }

                            if (pfd == null) {
                                Log.e(TAG, "File descriptor is null: $uri")
                                _playbackState.update {
                                    it.copy(isPlaying = false, error = "File not accessible")
                                }
                                return
                            }

                            Log.d(TAG, "Playing content URI via FileDescriptor: $uri")
                            setDataSource(pfd.fileDescriptor)
                            // Note: pfd will be closed when MediaPlayer is released
                        }
                        else -> {
                            Log.e(TAG, "Unsupported URI scheme: ${uri.scheme}")
                            _playbackState.update {
                                it.copy(isPlaying = false, error = "Unsupported file type")
                            }
                            return
                        }
                    }

                    setOnPreparedListener { mp ->
                        mp.start()
                        _playbackState.update {
                            it.copy(
                                isPlaying = true,
                                currentPosition = 0L,
                                duration = duration,
                                error = null,
                            )
                        }
                        startProgressUpdates()
                        updateMediaSessionState()
                        startForegroundService()
                    }
                    setOnCompletionListener {
                        _playbackState.update {
                            it.copy(
                                isPlaying = false,
                                currentPosition = duration,
                            )
                        }
                        stopProgressUpdates()
                        updateMediaSessionState()
                        stopForegroundService()
                        onCompletionCallback?.invoke()
                    }
                    setOnErrorListener { _, what, extra ->
                        _playbackState.update {
                            it.copy(
                                isPlaying = false,
                                error = "Playback error: $what, $extra",
                            )
                        }
                        stopProgressUpdates()
                        stopForegroundService()
                        true
                    }
                    prepareAsync()
                }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play: $uri", e)
            _playbackState.update {
                it.copy(
                    isPlaying = false,
                    error = "Failed to play: ${e.message}",
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
                updateMediaSessionState()
                updateNotification()
            }
        }
    }

    override fun resume() {
        mediaPlayer?.let { player ->
            if (!player.isPlaying) {
                player.start()
                _playbackState.update { it.copy(isPlaying = true) }
                startProgressUpdates()
                updateMediaSessionState()
                updateNotification()
            }
        }
    }

    override fun seekTo(position: Long) {
        mediaPlayer?.seekTo(position.toInt())
        _playbackState.update { it.copy(currentPosition = position) }
        updateMediaSessionState()
    }

    override fun stop() {
        stopMediaPlayer()
        stopProgressUpdates()
        mediaSessionManager.release()
        stopForegroundService()
        currentMeditation = null
        _playbackState.update {
            PlaybackState()
        }
    }

    /**
     * Stops only the media player without affecting MediaSession or service.
     */
    private fun stopMediaPlayer() {
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

    private fun updateMediaSessionState() {
        val state = _playbackState.value
        mediaSessionManager.updatePlaybackState(
            isPlaying = state.isPlaying,
            position = state.currentPosition,
            duration = state.duration,
        )
    }

    private fun startForegroundService() {
        val meditation = currentMeditation ?: return
        val meditationJson = Json.encodeToString(meditation)
        MeditationPlayerForegroundService.start(context, meditationJson)
    }

    private fun updateNotification() {
        MeditationPlayerForegroundService.update(context)
    }

    private fun stopForegroundService() {
        MeditationPlayerForegroundService.stop(context)
    }

    companion object {
        private const val TAG = "AudioPlayerService"
        private const val PROGRESS_UPDATE_INTERVAL = 100L // 100ms for smooth progress
    }
}
