package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.PreparationCountdown
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import dagger.hilt.android.lifecycle.HiltViewModel
import java.util.Locale
import javax.inject.Inject
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * UI State for the Guided Meditation Player screen.
 */
data class PlayerUiState(
    /** Currently loaded meditation */
    val meditation: GuidedMeditation? = null,
    /** Whether audio is currently loading */
    val isLoading: Boolean = false,
    /** Whether audio is playing */
    val isPlaying: Boolean = false,
    /** Current playback position in milliseconds */
    val currentPosition: Long = 0L,
    /** Total duration in milliseconds */
    val duration: Long = 0L,
    /** Playback progress (0.0 to 1.0) */
    val progress: Float = 0f,
    /** Error message if any */
    val error: String? = null,
    /** Whether playback has completed */
    val isCompleted: Boolean = false,
    /** Active preparation countdown, null when not counting down */
    val preparationCountdown: PreparationCountdown? = null
) {
    /** Whether preparation countdown is currently active (not finished) */
    val isPreparing: Boolean
        get() = preparationCountdown != null && !preparationCountdown.isFinished

    /** Remaining countdown seconds (0 if no countdown) */
    val countdownRemainingSeconds: Int
        get() = preparationCountdown?.remainingSeconds ?: 0

    /** Countdown progress (0.0 to 1.0, 0 if no countdown) */
    val countdownProgress: Double
        get() = preparationCountdown?.progress ?: 0.0

    /** Formatted current position (MM:SS or HH:MM:SS) */
    val formattedPosition: String
        get() = formatTime(currentPosition)

    /** Formatted total duration (MM:SS or HH:MM:SS) */
    val formattedDuration: String
        get() = formatTime(duration)

    /** Formatted remaining time (MM:SS or HH:MM:SS) */
    val formattedRemaining: String
        get() = formatTime(duration - currentPosition)

    private fun formatTime(ms: Long): String {
        val totalSeconds = (ms / 1000).coerceAtLeast(0)
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60

        return if (hours > 0) {
            String.format(Locale.ROOT, "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.ROOT, "%d:%02d", minutes, seconds)
        }
    }
}

/**
 * ViewModel for the Guided Meditation Player screen.
 *
 * Manages audio playback state and controls for guided meditations.
 * Coordinates with AudioSessionCoordinator to handle audio conflicts
 * with the timer feature.
 */
@HiltViewModel
class GuidedMeditationPlayerViewModel
@Inject
constructor(
    private val audioPlayerService: AudioPlayerServiceProtocol,
    private val audioSessionCoordinator: AudioSessionCoordinatorProtocol,
    private val settingsRepository: GuidedMeditationSettingsRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(PlayerUiState())
    val uiState: StateFlow<PlayerUiState> = _uiState.asStateFlow()

    /** Preparation time in seconds (null = disabled) */
    private var preparationTimeSeconds: Int? = null

    /** Tracks whether the session has started (countdown or playback began) */
    private var hasSessionStarted = false

    /** Job for the countdown timer */
    private var countdownJob: Job? = null

    init {
        observePlaybackState()
        registerConflictHandler()
    }

    /**
     * Observes playback state changes from the audio service.
     */
    private fun observePlaybackState() {
        viewModelScope.launch {
            audioPlayerService.playbackState.collect { state ->
                _uiState.update {
                    it.copy(
                        isPlaying = state.isPlaying,
                        currentPosition = state.currentPosition,
                        progress = state.progress,
                        error = state.error,
                        // Clear loading state when playback starts or error occurs
                        isLoading = if (state.isPlaying || state.error != null) false else it.isLoading
                    )
                }
            }
        }
    }

    /**
     * Registers conflict handler for audio session coordination.
     */
    private fun registerConflictHandler() {
        audioSessionCoordinator.registerConflictHandler(AudioSource.GUIDED_MEDITATION) {
            // Another audio source requested the session - stop our playback
            audioPlayerService.stop()
            _uiState.update {
                it.copy(
                    isPlaying = false,
                    currentPosition = 0L,
                    progress = 0f
                )
            }
        }
    }

    // MARK: - Public Methods

    /**
     * Loads a meditation for playback.
     * Loads the preparation time setting from the repository.
     *
     * @param meditation Meditation to load
     */
    fun loadMeditation(meditation: GuidedMeditation) {
        // Cancel any running countdown
        countdownJob?.cancel()
        countdownJob = null

        // Reset session state
        hasSessionStarted = false

        _uiState.update {
            it.copy(
                meditation = meditation,
                duration = meditation.duration,
                currentPosition = 0L,
                progress = 0f,
                isPlaying = false,
                isCompleted = false,
                error = null,
                preparationCountdown = null
            )
        }

        // Load settings from repository
        viewModelScope.launch {
            val settings = settingsRepository.getSettings()
            preparationTimeSeconds = settings.effectivePreparationTimeSeconds
        }
    }

    /**
     * Starts playback with optional preparation countdown.
     *
     * - First call with preparation time: starts countdown, then plays
     * - First call without preparation time: plays immediately
     * - Subsequent calls: toggles play/pause (no countdown)
     */
    fun startPlayback() {
        // Don't start if already counting down
        if (_uiState.value.isPreparing) {
            return
        }

        // If session already started, just toggle play/pause (no countdown on resume)
        if (hasSessionStarted) {
            togglePlayPause()
            return
        }

        // Mark session as started
        hasSessionStarted = true

        // First start - use countdown if configured
        val prepTime = preparationTimeSeconds
        if (prepTime != null && prepTime > 0) {
            startCountdown(prepTime)
        } else {
            togglePlayPause()
        }
    }

    /**
     * Starts the preparation countdown.
     */
    private fun startCountdown(seconds: Int) {
        val countdown = PreparationCountdown(totalSeconds = seconds)
        _uiState.update { it.copy(preparationCountdown = countdown) }

        countdownJob = viewModelScope.launch {
            while (_uiState.value.isPreparing) {
                delay(1000L)
                tickCountdown()
            }
        }
    }

    /**
     * Advances the countdown by one second.
     */
    private fun tickCountdown() {
        val currentCountdown = _uiState.value.preparationCountdown ?: return

        val ticked = currentCountdown.tick()
        _uiState.update { it.copy(preparationCountdown = ticked) }

        if (ticked.isFinished) {
            countdownJob?.cancel()
            countdownJob = null
            // Start MP3 after countdown
            play()
        }
    }

    /**
     * Starts or resumes playback.
     */
    fun play() {
        val meditation = _uiState.value.meditation ?: return

        // Request audio session (may stop timer audio)
        if (!audioSessionCoordinator.requestAudioSession(AudioSource.GUIDED_MEDITATION)) {
            _uiState.update {
                it.copy(error = "Could not acquire audio session")
            }
            return
        }

        // Set completion listener
        audioPlayerService.setOnCompletionListener {
            onPlaybackCompleted()
        }

        // Set loading state before starting playback
        _uiState.update { it.copy(isLoading = true) }

        // Start playback
        val uri = Uri.parse(meditation.fileUri)
        audioPlayerService.play(uri, meditation.duration)

        _uiState.update { it.copy(isCompleted = false) }
    }

    /**
     * Pauses playback.
     */
    fun pause() {
        audioPlayerService.pause()
    }

    /**
     * Resumes paused playback.
     */
    fun resume() {
        audioPlayerService.resume()
    }

    /**
     * Toggles between play and pause.
     */
    fun togglePlayPause() {
        if (_uiState.value.isPlaying) {
            pause()
        } else if (_uiState.value.isCompleted) {
            // Restart from beginning if completed
            seekTo(0L)
            resume()
            _uiState.update { it.copy(isCompleted = false) }
        } else if (_uiState.value.currentPosition > 0) {
            resume()
        } else {
            play()
        }
    }

    /**
     * Seeks to a specific position.
     *
     * @param position Position in milliseconds
     */
    fun seekTo(position: Long) {
        val duration = _uiState.value.duration
        val clampedPosition = position.coerceIn(0L, duration)
        audioPlayerService.seekTo(clampedPosition)
        _uiState.update {
            it.copy(
                currentPosition = clampedPosition,
                progress = if (duration > 0) clampedPosition.toFloat() / duration else 0f,
                isCompleted = false
            )
        }
    }

    /**
     * Seeks to a position based on progress (0.0 to 1.0).
     *
     * @param progress Progress value between 0.0 and 1.0
     */
    fun seekToProgress(progress: Float) {
        val position = (progress.coerceIn(0f, 1f) * _uiState.value.duration).toLong()
        seekTo(position)
    }

    /**
     * Skips forward by the specified amount.
     *
     * @param seconds Seconds to skip (default 10)
     */
    fun skipForward(seconds: Int = 10) {
        val newPosition = _uiState.value.currentPosition + (seconds * 1000L)
        seekTo(newPosition)
    }

    /**
     * Skips backward by the specified amount.
     *
     * @param seconds Seconds to skip (default 10)
     */
    fun skipBackward(seconds: Int = 10) {
        val newPosition = _uiState.value.currentPosition - (seconds * 1000L)
        seekTo(newPosition)
    }

    /**
     * Clears the current error.
     */
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    /**
     * Stops playback and releases resources.
     */
    fun stop() {
        // Cancel any running countdown
        countdownJob?.cancel()
        countdownJob = null

        audioPlayerService.stop()
        audioSessionCoordinator.releaseAudioSession(AudioSource.GUIDED_MEDITATION)
        _uiState.update {
            it.copy(
                isPlaying = false,
                currentPosition = 0L,
                progress = 0f,
                preparationCountdown = null
            )
        }
    }

    // MARK: - Private Methods

    private fun onPlaybackCompleted() {
        _uiState.update {
            it.copy(
                isPlaying = false,
                isCompleted = true,
                progress = 1f,
                currentPosition = it.duration
            )
        }
    }

    override fun onCleared() {
        super.onCleared()
        stop()
    }
}
