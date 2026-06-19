package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.MeditationPhase
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.models.PreparationCountdown
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MeditationGongPlayerProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformProviderProtocol
import com.stillmoment.presentation.ui.meditations.components.PlayheadWindowGeometry
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
 * State of the central resting line below the wave (shared-109).
 *
 * [Remaining] carries the already-formatted `mm:ss` remaining time; [Paused] and [Finished]
 * are special states the view renders as plain words. Mirrors iOS `RemainingLineState`.
 */
sealed class RemainingLineState {
    data class Remaining(val time: String) : RemainingLineState()
    data object Paused : RemainingLineState()
    data object Finished : RemainingLineState()
}

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
    val preparationCountdown: PreparationCountdown? = null,
    /**
     * Precomputed waveform of the whole file (null while loading or after a failure).
     * The samples span the full `meditation.duration`, not the trimmed range (shared-109).
     */
    val waveform: MeditationWaveform? = null,
    /**
     * True when waveform generation failed (e.g. exotic format). The player stays fully
     * functional — the window renders a plain baseline instead of amplitudes (shared-109).
     */
    val waveformLoadFailed: Boolean = false,
    /**
     * True while the user is dragging the wave to scrub. Pauses the pulse and replaces the
     * remaining-time line with the large live position (shared-109).
     */
    val isDragging: Boolean = false,
    /**
     * Live position during a drag (range-relative ms, 0 = trim start, clamped to the
     * effective duration). Drives the window center and the live-position readout (shared-109).
     */
    val dragPositionMs: Long = 0L
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

    /**
     * Visuelle Phase des Players.
     *
     * - [MeditationPhase.PreRoll] solange die Vorbereitung laeuft.
     * - [MeditationPhase.Playing] ansonsten (auch bei Pause, Loading, Idle, Finished —
     *   der Atemkreis sieht in all diesen Zustaenden gleich aus).
     */
    val phase: MeditationPhase
        get() = if (isPreparing) MeditationPhase.PreRoll else MeditationPhase.Playing

    /** Formatted current position (MM:SS or HH:MM:SS) */
    val formattedPosition: String
        get() = formatTime(currentPosition)

    /** Formatted total duration (MM:SS or HH:MM:SS) */
    val formattedDuration: String
        get() = formatTime(duration)

    /** Formatted remaining time (MM:SS or HH:MM:SS) */
    val formattedRemaining: String
        get() = formatTime(duration - currentPosition)

    /**
     * Restzeit fuer das "NOCH … MIN"-Label im neuen Player-Layout.
     *
     * Identisch mit [formattedRemaining] — eigene Property, weil der
     * View-Aufruf so semantisch klar bleibt ("Minuten-Label im Atemkreis-Player").
     */
    val formattedRemainingMinutes: String
        get() = formattedRemaining

    // MARK: - Waveform window & scrub (shared-109)

    /**
     * Playable range (range-relative ms) the scrub is clamped to: `[0, effectiveDuration]`.
     * Position 0 is the trim start; the upper bound is the trimmed length.
     */
    val scrubBoundsMs: LongRange
        get() = 0L..duration.coerceAtLeast(0L)

    /**
     * The range-relative position the window is centered on: the live drag position while
     * scrubbing, otherwise the real audio position (source of truth for clean recovery).
     */
    val displayPositionMs: Long
        get() = if (isDragging) dragPositionMs else currentPosition

    /** Current position relative to the trim start (`mm:ss`), following the live drag. */
    val formattedDisplayPosition: String
        get() = formatTime(displayPositionMs)

    /**
     * State of the central resting line below the wave (shared-109). While dragging the view
     * shows the live position instead.
     */
    val remainingLineState: RemainingLineState
        get() = when {
            isCompleted -> RemainingLineState.Finished
            !isPlaying && !isLoading && !isPreparing && currentPosition > 0L -> RemainingLineState.Paused
            else -> RemainingLineState.Remaining(formattedRemaining)
        }

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
@Suppress("TooManyFunctions") // ViewModel orchestrates playback, countdown, gong + scrub flows
@HiltViewModel
class GuidedMeditationPlayerViewModel
@Inject
constructor(
    private val audioPlayerService: AudioPlayerServiceProtocol,
    private val audioSessionCoordinator: AudioSessionCoordinatorProtocol,
    private val settingsRepository: GuidedMeditationSettingsRepository,
    private val gongPlayer: MeditationGongPlayerProtocol,
    private val praxisRepository: PraxisRepository,
    private val waveformProvider: WaveformProviderProtocol,
    private val logger: LoggerProtocol
) : ViewModel() {
    private val _uiState = MutableStateFlow(PlayerUiState())
    val uiState: StateFlow<PlayerUiState> = _uiState.asStateFlow()

    /** Preparation time in seconds (null = disabled) */
    private var preparationTimeSeconds: Int? = null

    /**
     * Gong volume from the timer settings (Praxis), loaded with the meditation.
     * The per-meditation gong follows the timer's gong volume, not a stored value (shared-106).
     */
    private var gongVolume: Float = Praxis.DEFAULT_GONG_VOLUME

    /** Tracks whether the session has started (countdown or playback began) */
    private var hasSessionStarted = false

    /** Job for the countdown timer */
    private var countdownJob: Job? = null

    /** Job for the start-gong sequence (gong + breath pause). */
    private var startGongJob: Job? = null

    /** Job loading the waveform; cancelled on reload (shared-109). */
    private var waveformJob: Job? = null

    /**
     * Whether playback was running when the current drag began — decides whether to resume
     * on release (shared-109).
     */
    private var dragWasPlaying = false

    /**
     * Range-relative position the band was centered on when the current drag began. The drag
     * translation is always applied to this fixed anchor (never to the already-moved position),
     * so the scrub follows the finger 1:1. Mirrors iOS `dragStartTime`.
     */
    private var dragStartMs = 0L

    /**
     * True while the start gong rings and during the following breath pause —
     * blocks further startPlayback taps until the meditation audio runs (shared-106).
     */
    private var isStartGongSequenceActive = false

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
                    val meditation = it.meditation
                    // The service reports absolute file time; the UI shows the trimmed
                    // range relative to its start (shared-105). Without a meditation
                    // (e.g. before load) fall back to the raw values.
                    val relativePosition = relativePosition(meditation, state.currentPosition)
                    val effectiveDuration = meditation?.effectiveDurationMs ?: state.duration
                    it.copy(
                        isPlaying = state.isPlaying,
                        currentPosition = relativePosition,
                        duration = effectiveDuration,
                        progress = progressFor(relativePosition, effectiveDuration),
                        error = state.error,
                        // Clear loading state when playback starts or error occurs
                        isLoading = if (state.isPlaying || state.error != null) false else it.isLoading
                    )
                }
            }
        }
    }

    /** Converts an absolute file position into a range-relative display position. */
    private fun relativePosition(meditation: GuidedMeditation?, absolutePosition: Long): Long {
        val start = meditation?.effectiveStartMs ?: 0L
        return (absolutePosition - start).coerceAtLeast(0L)
    }

    private fun progressFor(relativePosition: Long, effectiveDuration: Long): Float {
        if (effectiveDuration <= 0) {
            return 0f
        }
        return (relativePosition.toFloat() / effectiveDuration).coerceIn(0f, 1f)
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
     * Suspend, damit der direkte Folge-Aufruf [startPlayback] das
     * geladene `preparationTimeSeconds` sicher sieht. Andernfalls wuerde
     * Auto-Start ggf. mit `preparationTimeSeconds == null` losspielen,
     * obwohl Pre-Roll konfiguriert ist.
     *
     * @param meditation Meditation to load
     */
    suspend fun loadMeditation(meditation: GuidedMeditation) {
        // Cancel any running countdown
        countdownJob?.cancel()
        countdownJob = null

        // Cancel any pending start-gong sequence
        startGongJob?.cancel()
        startGongJob = null
        gongPlayer.stop()
        isStartGongSequenceActive = false

        // Reset session state
        hasSessionStarted = false

        _uiState.update {
            it.copy(
                meditation = meditation,
                duration = meditation.effectiveDurationMs,
                currentPosition = 0L,
                progress = 0f,
                isPlaying = false,
                isCompleted = false,
                error = null,
                preparationCountdown = null,
                waveform = null,
                waveformLoadFailed = false,
                isDragging = false,
                dragPositionMs = 0L
            )
        }

        // Load settings sequentially so startPlayback() sees the value.
        val settings = settingsRepository.getSettings()
        preparationTimeSeconds = settings.effectivePreparationTimeSeconds

        // The per-meditation gong follows the timer's gong volume (shared-106).
        gongVolume = praxisRepository.load().gongVolume
    }

    /**
     * Starts playback with optional preparation countdown.
     *
     * - First call with preparation time: starts countdown, then plays
     * - First call without preparation time: plays immediately
     * - Subsequent calls: toggles play/pause (no countdown)
     */
    fun startPlayback() {
        // Don't start while counting down or while the start-gong sequence runs
        if (_uiState.value.isPreparing || isStartGongSequenceActive) {
            return
        }

        // If session already started, just toggle play/pause (no countdown/gong on resume)
        if (hasSessionStarted) {
            togglePlayPause()
            return
        }

        // Mark session as started
        hasSessionStarted = true

        // First start - use countdown if configured, otherwise start gong (if any), otherwise play
        val prepTime = preparationTimeSeconds
        when {
            prepTime != null && prepTime > 0 -> startCountdown(prepTime)
            _uiState.value.meditation?.startGongEnabled == true -> startGongSequence()
            else -> togglePlayPause()
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
            // After the countdown: ring the start gong (if any), then play (shared-106)
            if (_uiState.value.meditation?.startGongEnabled == true) {
                startGongSequence()
            } else {
                play()
            }
        }
    }

    // MARK: - Start Gong Sequence (shared-106)

    /**
     * Rings the start gong, waits a breath pause, then begins audio playback.
     *
     * Mirrors iOS: the gong marks the start of the session; resume and restart do
     * not ring it again (only the first [startPlayback] reaches here).
     */
    private fun startGongSequence() {
        isStartGongSequenceActive = true
        val meditation = _uiState.value.meditation ?: run {
            isStartGongSequenceActive = false
            return
        }
        gongPlayer.play(meditation.gongSoundId, gongVolume) {
            startBreathPause()
        }
    }

    private fun startBreathPause() {
        startGongJob?.cancel()
        startGongJob = viewModelScope.launch {
            delay(BREATH_PAUSE_MS)
            isStartGongSequenceActive = false
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

        // Start playback, honouring the trim range (shared-105)
        val uri = Uri.parse(meditation.fileUri)
        audioPlayerService.play(uri, meditation.duration, meditation.trimStartMs, meditation.trimEndMs)

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
            play()
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
     * @param position Range-relative position in milliseconds (0 = trim start)
     */
    fun seekTo(position: Long) {
        val effectiveDuration = _uiState.value.duration
        val relativePosition = position.coerceIn(0L, effectiveDuration)

        // Translate the relative position to absolute file time for the service,
        // which clamps it to the trim range itself (shared-105).
        val start = _uiState.value.meditation?.effectiveStartMs ?: 0L
        audioPlayerService.seekTo(start + relativePosition)

        _uiState.update {
            it.copy(
                currentPosition = relativePosition,
                progress = progressFor(relativePosition, effectiveDuration),
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

    // MARK: - Waveform & Scrub (shared-109)

    /**
     * Loads the precomputed waveform for the scrolling window.
     *
     * Runs independently of [play] so a cold cache (first open, on-demand generation) never
     * blocks playback. On failure the window falls back to a plain baseline — scrub, times and
     * the mini overview stay fully functional.
     */
    fun loadWaveform() {
        val current = _uiState.value
        if (current.waveform != null || current.waveformLoadFailed) {
            return
        }
        val meditation = current.meditation ?: return
        waveformJob?.cancel()
        waveformJob = viewModelScope.launch {
            try {
                val loaded = waveformProvider.waveform(meditation)
                _uiState.update { it.copy(waveform = loaded, waveformLoadFailed = false) }
            } catch (e: WaveformGenerationException) {
                logger.e(TAG, "Failed to load waveform for player", e)
                _uiState.update { it.copy(waveform = null, waveformLoadFailed = true) }
            }
        }
    }

    /**
     * Begins a scrub: grabbing the wave pauses playback and anchors the drag at the current
     * range-relative position (clamped into `[0, effectiveDuration]`).
     */
    fun beginScrub() {
        val current = _uiState.value
        val anchored = current.currentPosition.coerceIn(current.scrubBoundsMs)
        dragWasPlaying = current.isPlaying
        dragStartMs = anchored
        _uiState.update { it.copy(isDragging = true, dragPositionMs = anchored) }
        if (current.isPlaying) {
            pause()
        }
    }

    /**
     * Updates the live drag position to a range-relative time, clamped to the effective range.
     *
     * @param positionMs Range-relative position in milliseconds (0 = trim start)
     */
    fun scrubToMs(positionMs: Long) {
        _uiState.update { it.copy(dragPositionMs = positionMs.coerceIn(it.scrubBoundsMs)) }
    }

    /**
     * Updates the live drag position from the cumulative drag translation in pixels, anchored at
     * the position when the grab began ([dragStartMs]). Dragging the wave left moves the position
     * forward, right moves it backward — the band scrolls under the fixed now-line. Mirrors iOS
     * `WaveformWindowView`'s scrub gesture via [PlayheadWindowGeometry.draggedNow] (shared-109).
     *
     * @param translationPx Cumulative horizontal drag distance since the grab began.
     * @param widthPx Current width of the waveform canvas.
     * @param windowSec Visible window span in seconds.
     */
    fun scrubByTranslation(translationPx: Float, widthPx: Float, windowSec: Double) {
        val target = PlayheadWindowGeometry.draggedNow(
            startNowMs = dragStartMs,
            translationPx = translationPx,
            windowSec = windowSec,
            width = widthPx,
            bounds = _uiState.value.scrubBoundsMs
        )
        scrubToMs(target)
    }

    /**
     * Ends a scrub: seeks to the live position and resumes playback if it was running before
     * the grab (and the position is not at the very end).
     */
    fun endScrub() {
        val current = _uiState.value
        val target = current.dragPositionMs
        _uiState.update { it.copy(isDragging = false) }
        seekTo(target)
        if (dragWasPlaying && target < current.duration) {
            resume()
        }
        dragWasPlaying = false
    }

    /**
     * Seeks to a fraction (0…1) of the trimmed track — the mini overview's absolute seek.
     * Fraction `f` maps to a range-relative position `f · effectiveDuration` (shared-109).
     */
    fun seekToFraction(fraction: Float) {
        seekToProgress(fraction)
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

        // Cancel any pending start-gong sequence and stop a ringing gong
        startGongJob?.cancel()
        startGongJob = null
        gongPlayer.stop()
        isStartGongSequenceActive = false

        waveformJob?.cancel()
        waveformJob = null

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
        // shared-106: ring the end gong before releasing the audio session, so it
        // stays audible — also on the lock screen — until it has fully rung out.
        // The completion screen is already shown above. The session must be released
        // in every completion path exactly once: after the gong rings out when one is
        // enabled, or immediately otherwise (without this the GUIDED_MEDITATION session
        // would leak and block the timer audio after a gong-free meditation).
        if (_uiState.value.meditation?.endGongEnabled == true) {
            gongPlayer.play(_uiState.value.meditation?.gongSoundId ?: Praxis.DEFAULT_GONG_SOUND_ID, gongVolume) {
                audioSessionCoordinator.releaseAudioSession(AudioSource.GUIDED_MEDITATION)
            }
        } else {
            audioSessionCoordinator.releaseAudioSession(AudioSource.GUIDED_MEDITATION)
        }
    }

    override fun onCleared() {
        super.onCleared()
        stop()
    }

    companion object {
        /** Breath pause between the start gong and the meditation audio. Matches iOS' 2.0 s (shared-106). */
        private const val BREATH_PAUSE_MS = 2000L

        private const val TAG = "GuidedMeditationPlayer"
    }
}
