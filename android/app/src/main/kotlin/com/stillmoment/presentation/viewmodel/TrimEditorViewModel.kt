package com.stillmoment.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.models.TrimEditorState
import com.stillmoment.domain.models.TrimPoint
import com.stillmoment.domain.models.TrimZoomWindow
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformProviderProtocol
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * How long the short auto-previews play after committing a mark (shared-107).
 * Injectable so tests can shorten them. Values match iOS (2.2 s / 1.4 s) in ms.
 */
data class TrimPreviewDurations(
    val afterMarkDragMs: Long,
    val afterNudgeMs: Long
) {
    companion object {
        val Standard = TrimPreviewDurations(afterMarkDragMs = 2_200L, afterNudgeMs = 1_400L)
    }
}

/**
 * UI state for the full-screen waveform trim editor (shared-107/108).
 *
 * Playhead, playing, previewing and the zoom window are UI concerns; the immutable
 * selection lives in [editorState].
 */
data class TrimEditorUiState(
    val editorState: TrimEditorState,
    val waveform: MeditationWaveform? = null,
    val waveformLoadFailed: Boolean = false,
    val isPlaying: Boolean = false,
    val isPreviewing: Boolean = false,
    val playheadTimeMs: Long = 0L,
    val window: ClosedRange<Long> = 0L..0L
) {
    /** True while the window shows less than the whole file (drives minimap/zoom-out). */
    val isZoomed: Boolean
        get() = (window.endInclusive - window.start) < (editorState.duration - BOUNDARY_TOLERANCE_MS)

    /** True while the waveform is still loading and has not failed. */
    val isLoadingWaveform: Boolean
        get() = waveform == null && !waveformLoadFailed

    private companion object {
        const val BOUNDARY_TOLERANCE_MS = 1_000L
    }
}

/**
 * ViewModel for the full-screen waveform trim editor (shared-107/108).
 *
 * Owns the immutable [TrimEditorState] and forwards intents to it. Loads the waveform
 * lazily through [WaveformProviderProtocol] and drives audio through the shared
 * meditation-preview path ([AudioServiceProtocol]).
 *
 * Playback model (mirrors iOS): the playhead is its own, always-present position.
 * Dragging it ([seek]) pauses playback first and moves only the playhead;
 * [playheadDragEnded] starts playback from there. Releasing a mark drag or nudging
 * auditions the cut with a short auto-preview (start: first seconds of the range; end:
 * last seconds up to the mark) and parks the playhead at the mark. Playback pauses at the
 * end point, unless it starts at/after the end point (the escape hatch to listen past the
 * cut). Lock-screen preview behavior is device-only; not unit-tested.
 */
@HiltViewModel
class TrimEditorViewModel
@Inject
constructor(
    private val audioService: AudioServiceProtocol,
    private val waveformProvider: WaveformProviderProtocol,
    private val logger: LoggerProtocol,
    private val previewDurations: TrimPreviewDurations = TrimPreviewDurations.Standard
) : ViewModel() {
    private lateinit var meditation: GuidedMeditation

    private val _uiState = MutableStateFlow(
        TrimEditorUiState(editorState = TrimEditorState(0L, 0L, 0L, TrimPoint.START))
    )
    val uiState: StateFlow<TrimEditorUiState> = _uiState.asStateFlow()

    private var waveformJob: Job? = null
    private var previewJob: Job? = null

    /**
     * True when the current playback was anchored at/after the end point — it then runs
     * to the file end instead of pausing at the end point (auditioning the end position).
     */
    private var playsToFileEnd = false

    init {
        observePreviewPosition()
        observePreviewCompletion()
    }

    /** Seeds the editor from a meditation. Call once when the screen appears. */
    fun loadMeditation(meditation: GuidedMeditation) {
        this.meditation = meditation
        val state = TrimEditorState.fromMeditation(meditation)
        _uiState.value = TrimEditorUiState(
            editorState = state,
            playheadTimeMs = state.start,
            window = 0L..maxOf(state.duration, 0L)
        )
    }

    // MARK: - Waveform Loading

    /** Loads the waveform through the provider (cache hit is instant, miss generates). */
    fun loadWaveform() {
        val current = _uiState.value
        if (current.waveform != null || current.waveformLoadFailed) {
            return
        }
        waveformJob?.cancel()
        waveformJob = viewModelScope.launch {
            try {
                val loaded = waveformProvider.waveform(meditation)
                _uiState.update { it.copy(waveform = loaded) }
            } catch (e: WaveformGenerationException) {
                logger.e(TAG, "Failed to load waveform for trim editor", e)
                _uiState.update { it.copy(waveformLoadFailed = true) }
            }
        }
    }

    // MARK: - Editor Intents

    /** Selects which point is active and moves the playhead onto it. */
    fun selectPoint(point: TrimPoint) {
        cancelPreview()
        val state = _uiState.value.editorState.selecting(point)
        _uiState.update { it.copy(editorState = state) }
        anchorPlayhead(state.activeValue)
    }

    /** Moves a point (clamped + min-distance by the domain) and selects it. */
    fun movePoint(point: TrimPoint, toMs: Long) {
        cancelPreview()
        _uiState.update { it.copy(editorState = it.editorState.moving(point, toMs)) }
    }

    /** Mark drag released — auditions the cut, parks the playhead, recenters the zoom. */
    fun markDragEnded() {
        auditionActivePoint(previewDurations.afterMarkDragMs)
        recenterWindowOnActivePoint()
    }

    /** Nudges the active point by ±1 s, auditions the new cut, keeps the window centered. */
    fun nudgeActivePoint(deltaMs: Long) {
        _uiState.update { it.copy(editorState = it.editorState.nudgingActivePoint(deltaMs)) }
        auditionActivePoint(previewDurations.afterNudgeMs)
        recenterWindowOnActivePoint()
    }

    /** Resets the selection to the full file and parks the playhead at 0, paused. */
    fun useWholeFile() {
        cancelPreview()
        pausePlayback()
        val state = _uiState.value.editorState.usingWholeFile()
        playsToFileEnd = false
        _uiState.update {
            it.copy(
                editorState = state,
                playheadTimeMs = 0L,
                window = wholeFileWindow(state)
            )
        }
    }

    // MARK: - Zoom (shared-108)

    /** Selects the point and frames it in a zoom window. Short files never zoom. */
    fun focusPoint(point: TrimPoint) {
        selectPoint(point)
        val state = _uiState.value.editorState
        _uiState.update {
            it.copy(window = TrimZoomWindow.frame(state.activeValue, point, state.duration))
        }
    }

    /** Zooms back to the overview; marks and playhead untouched. */
    fun zoomOut() {
        _uiState.update { it.copy(window = wholeFileWindow(it.editorState)) }
    }

    /** Moves the zoom window so it is centered on [centerMs]. */
    fun panWindow(centerMs: Long) {
        _uiState.update {
            it.copy(window = TrimZoomWindow.pan(centerMs, it.editorState.duration))
        }
    }

    // MARK: - Seeking (playhead lane)

    /** Moves the playhead while dragging; pauses a running playback/preview first. */
    fun seek(toMs: Long) {
        cancelPreview()
        pausePlayback()
        val state = _uiState.value.editorState
        val clamped = toMs.coerceIn(0L, state.duration)
        playsToFileEnd = clamped >= state.end
        _uiState.update { it.copy(playheadTimeMs = clamped) }
    }

    /** Playhead drag released — playback starts from the new position. */
    fun playheadDragEnded() {
        cancelPreview()
        startPlayback()
    }

    // MARK: - Playback

    /** ▶ plays from the playhead, ⏸ pauses and keeps the position. */
    fun togglePlayback() {
        if (_uiState.value.isPlaying) {
            pausePlayback()
            return
        }
        cancelPreview()
        startPlayback()
    }

    /** Stops all audio — called when the editor disappears. */
    fun viewDisappeared() {
        previewJob?.cancel()
        previewJob = null
        waveformJob?.cancel()
        waveformJob = null
        audioService.stopMeditationPreview()
        _uiState.update { it.copy(isPlaying = false, isPreviewing = false) }
    }

    // MARK: - Private

    private fun wholeFileWindow(state: TrimEditorState): ClosedRange<Long> = 0L..maxOf(state.duration, 0L)

    private fun recenterWindowOnActivePoint() {
        if (!_uiState.value.isZoomed) {
            return
        }
        val state = _uiState.value.editorState
        _uiState.update {
            it.copy(window = TrimZoomWindow.frame(state.activeValue, state.activePoint, state.duration))
        }
    }

    private fun observePreviewPosition() {
        viewModelScope.launch {
            audioService.meditationPreviewPositionFlow.collect { position ->
                val state = _uiState.value
                if (state.isPlaying || state.isPreviewing) {
                    handlePlaybackPosition(position)
                }
            }
        }
    }

    private fun observePreviewCompletion() {
        viewModelScope.launch {
            audioService.meditationPreviewCompletionFlow.collect {
                previewJob?.cancel()
                previewJob = null
                _uiState.update { it.copy(isPlaying = false, isPreviewing = false) }
            }
        }
    }

    private fun handlePlaybackPosition(position: Long) {
        val state = _uiState.value
        if (!playsToFileEnd && position >= state.editorState.end) {
            pauseAtEndPoint()
            return
        }
        _uiState.update { it.copy(playheadTimeMs = position) }
    }

    private fun startPlayback() {
        val position = _uiState.value.playheadTimeMs
        if (!startPreviewPlayback(position)) {
            return
        }
        playsToFileEnd = position >= _uiState.value.editorState.end
        _uiState.update { it.copy(isPlaying = true) }
    }

    private fun pausePlayback() {
        if (!_uiState.value.isPlaying) {
            return
        }
        audioService.stopMeditationPreview()
        _uiState.update { it.copy(isPlaying = false) }
    }

    private fun pauseAtEndPoint() {
        previewJob?.cancel()
        previewJob = null
        audioService.stopMeditationPreview()
        _uiState.update {
            it.copy(isPlaying = false, isPreviewing = false, playheadTimeMs = it.editorState.end)
        }
    }

    /** Moves the playhead onto a mark; keeps playing (seek) when playing. */
    private fun anchorPlayhead(position: Long) {
        playsToFileEnd = position >= _uiState.value.editorState.end
        _uiState.update { it.copy(playheadTimeMs = position) }
        if (_uiState.value.isPlaying) {
            audioService.seekMeditationPreview(position)
        }
    }

    /**
     * Auditions the cut inside the audible window: start plays the first seconds of the
     * range; end plays the last seconds UP TO the mark (never the cut-off audio).
     */
    private fun auditionActivePoint(durationMs: Long) {
        val state = _uiState.value.editorState
        when (state.activePoint) {
            TrimPoint.START -> playPreview(state.start, durationMs, parkAtMs = state.start)
            TrimPoint.END -> {
                val from = maxOf(state.end - durationMs, state.start)
                playPreview(from, durationMs, parkAtMs = state.end)
            }
        }
    }

    private fun playPreview(fromMs: Long, durationMs: Long, parkAtMs: Long) {
        cancelPreview()
        pausePlayback()
        playsToFileEnd = fromMs >= _uiState.value.editorState.end
        _uiState.update { it.copy(playheadTimeMs = fromMs) }
        if (!startPreviewPlayback(fromMs)) {
            return
        }
        _uiState.update { it.copy(isPreviewing = true) }
        previewJob = viewModelScope.launch {
            delay(durationMs)
            finishPreview(parkAtMs)
        }
    }

    private fun finishPreview(parkAtMs: Long) {
        audioService.stopMeditationPreview()
        previewJob = null
        _uiState.update { it.copy(isPreviewing = false, playheadTimeMs = parkAtMs) }
    }

    private fun cancelPreview() {
        previewJob?.cancel()
        previewJob = null
        if (!_uiState.value.isPreviewing) {
            return
        }
        audioService.stopMeditationPreview()
        _uiState.update { it.copy(isPreviewing = false) }
    }

    /** Starts the preview player at [position]. Returns false if no file is set. */
    private fun startPreviewPlayback(position: Long): Boolean {
        audioService.playMeditationPreview(meditation.fileUri)
        audioService.seekMeditationPreview(position)
        return true
    }

    private companion object {
        const val TAG = "TrimEditor"
    }
}
