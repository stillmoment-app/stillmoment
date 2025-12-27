package com.stillmoment.infrastructure.audio

import android.content.Context
import android.net.Uri
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import com.stillmoment.domain.services.PlaybackState
import com.stillmoment.domain.services.ProgressSchedulerProtocol
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
    private val coordinator: AudioSessionCoordinatorProtocol,
    private val mediaPlayerFactory: MediaPlayerFactoryProtocol,
    private val progressScheduler: ProgressSchedulerProtocol,
    private val logger: LoggerProtocol
) : AudioPlayerServiceProtocol {
    init {
        // Register conflict handler to stop playback when another source takes over (Timer)
        coordinator.registerConflictHandler(AudioSource.GUIDED_MEDITATION) {
            logger.d(TAG, "Audio conflict: stopping guided meditation for other source")
            stop()
        }

        // Register pause handler for system audio focus loss (phone call, other app)
        coordinator.registerPauseHandler(AudioSource.GUIDED_MEDITATION) {
            logger.d(TAG, "Audio focus lost: pausing guided meditation")
            pause()
        }
    }
    private var mediaPlayer: MediaPlayerProtocol? = null
    private var onCompletionCallback: (() -> Unit)? = null

    private val _playbackState = MutableStateFlow(PlaybackState())
    override val playbackState: StateFlow<PlaybackState> = _playbackState.asStateFlow()

    /**
     * The currently playing meditation, or null if nothing is playing.
     */
    var currentMeditation: GuidedMeditation? = null
        private set

    /**
     * Plays a guided meditation with full MediaSession integration.
     *
     * @param meditation The meditation to play
     */
    fun playMeditation(meditation: GuidedMeditation) {
        // Request exclusive audio session
        if (!coordinator.requestAudioSession(AudioSource.GUIDED_MEDITATION)) {
            logger.w(TAG, "Failed to acquire audio session for guided meditation")
            return
        }

        currentMeditation = meditation

        // Create MediaSession with callbacks
        mediaSessionManager.createSession(
            object : MediaSessionManager.MediaSessionCallback {
                override fun onPlay() = resume()

                override fun onPause() = pause()

                override fun onStop() = stop()

                override fun onSeekTo(position: Long) = seekTo(position)
            }
        )

        // Update metadata
        mediaSessionManager.updateMetadata(meditation)

        // Play the audio
        play(Uri.parse(meditation.fileUri), meditation.duration)
    }

    override fun play(uri: Uri, duration: Long) {
        stopMediaPlayer()

        try {
            mediaPlayer = createMediaPlayer(uri, duration)
        } catch (e: IllegalStateException) {
            logger.e(TAG, "MediaPlayer in invalid state: $uri", e)
            setPlaybackError("Player error: ${e.message}")
        } catch (e: java.io.IOException) {
            logger.e(TAG, "Failed to read audio file: $uri", e)
            setPlaybackError("Could not read file: ${e.message}")
        }
    }

    /**
     * Creates and configures a MediaPlayer for the given URI.
     * Returns null if the data source could not be set.
     */
    private fun createMediaPlayer(uri: Uri, duration: Long): MediaPlayerProtocol? {
        val player = mediaPlayerFactory.create()

        if (!setDataSourceForUri(player, uri)) {
            player.release()
            return null
        }

        configureListeners(player, duration)
        player.prepareAsync()
        return player
    }

    /**
     * Sets the data source on the MediaPlayer based on URI scheme.
     * Returns true on success, false on failure (error state already set).
     */
    private fun setDataSourceForUri(player: MediaPlayerProtocol, uri: Uri): Boolean {
        return when (uri.scheme) {
            "file" -> setFileDataSource(player, uri)
            "content" -> setContentDataSource(player, uri)
            else -> {
                logger.e(TAG, "Unsupported URI scheme: ${uri.scheme}")
                setPlaybackError("Unsupported file type")
                false
            }
        }
    }

    private fun setFileDataSource(player: MediaPlayerProtocol, uri: Uri): Boolean {
        val path = uri.path
        if (path == null) {
            logger.e(TAG, "File path is null: $uri")
            setPlaybackError("Invalid file path")
            return false
        }
        logger.d(TAG, "Playing local file: $path")
        player.setDataSource(path)
        return true
    }

    private fun setContentDataSource(player: MediaPlayerProtocol, uri: Uri): Boolean {
        val pfd = openFileDescriptor(uri) ?: return false
        logger.d(TAG, "Playing content URI via FileDescriptor: $uri")
        player.setDataSourceFromFd(pfd.fileDescriptor)
        // Note: pfd will be closed when MediaPlayer is released
        return true
    }

    private fun openFileDescriptor(uri: Uri): android.os.ParcelFileDescriptor? {
        return try {
            context.contentResolver.openFileDescriptor(uri, "r").also {
                if (it == null) {
                    logger.e(TAG, "File descriptor is null: $uri")
                    setPlaybackError("File not accessible")
                }
            }
        } catch (e: SecurityException) {
            logger.e(TAG, "URI permission lost: $uri", e)
            setPlaybackError("Permission lost - please re-import file")
            null
        } catch (e: FileNotFoundException) {
            logger.e(TAG, "File not found: $uri", e)
            setPlaybackError("File was deleted or moved")
            null
        }
    }

    private fun configureListeners(player: MediaPlayerProtocol, duration: Long) {
        player.setOnPreparedListener {
            player.start()
            _playbackState.update {
                it.copy(
                    isPlaying = true,
                    currentPosition = 0L,
                    duration = duration,
                    error = null
                )
            }
            startProgressUpdates()
            updateMediaSessionState()
            startForegroundService()
        }
        player.setOnCompletionListener {
            _playbackState.update {
                it.copy(
                    isPlaying = false,
                    currentPosition = duration
                )
            }
            stopProgressUpdates()
            updateMediaSessionState()
            stopForegroundService()
            onCompletionCallback?.invoke()
        }
        player.setOnErrorListener { what, extra ->
            setPlaybackError("Playback error: $what, $extra")
            stopProgressUpdates()
            stopForegroundService()
            true
        }
    }

    private fun setPlaybackError(message: String) {
        _playbackState.update { it.copy(isPlaying = false, error = message) }
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
        coordinator.releaseAudioSession(AudioSource.GUIDED_MEDITATION)
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
            } catch (e: IllegalStateException) {
                logger.w(TAG, "MediaPlayer cleanup in invalid state (can be ignored)")
            }
        }
        mediaPlayer = null
    }

    override fun setOnCompletionListener(callback: () -> Unit) {
        onCompletionCallback = callback
    }

    private fun startProgressUpdates() {
        progressScheduler.start(PROGRESS_UPDATE_INTERVAL) {
            updateProgress()
            updateMediaSessionState()
        }
    }

    private fun stopProgressUpdates() {
        progressScheduler.stop()
    }

    private fun updateProgress() {
        mediaPlayer?.let { player ->
            try {
                if (player.isPlaying) {
                    _playbackState.update {
                        it.copy(currentPosition = player.currentPosition.toLong())
                    }
                }
            } catch (e: IllegalStateException) {
                logger.d(TAG, "Progress update skipped - player in invalid state")
            }
        }
    }

    private fun updateMediaSessionState() {
        val state = _playbackState.value
        mediaSessionManager.updatePlaybackState(
            isPlaying = state.isPlaying,
            position = state.currentPosition,
            duration = state.duration
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
        private const val PROGRESS_UPDATE_INTERVAL = 500L // 500ms for energy efficiency
    }
}
