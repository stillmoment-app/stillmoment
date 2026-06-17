package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.models.TrimPoint
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformProviderProtocol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for [TrimEditorViewModel] (shared-107/108).
 *
 * Drives intents and asserts state transitions + the audio-preview contract through a
 * fake [AudioServiceProtocol] and a fake [WaveformProviderProtocol]. No real audio.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TrimEditorViewModelTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var audio: RecordingAudioService
    private lateinit var provider: FakeProvider
    private lateinit var viewModel: TrimEditorViewModel

    // 20-min file → room for zoom and the 25 s minimum range.
    private val meditation = GuidedMeditation(
        fileUri = "content://test/uri",
        fileName = "test.mp3",
        duration = 1_200_000L,
        teacher = "Teacher",
        name = "Name"
    )

    private val durations = TrimPreviewDurations(afterMarkDragMs = 2_200L, afterNudgeMs = 1_400L)

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        audio = RecordingAudioService()
        provider = FakeProvider()
        viewModel = TrimEditorViewModel(audio, provider, mock(), durations)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun load(med: GuidedMeditation = meditation) {
        viewModel.loadMeditation(med)
    }

    @Nested
    inner class Initialization {
        @Test
        fun `seeds the editor state and playhead from the meditation`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertEquals(0L, state.editorState.start)
            assertEquals(1_200_000L, state.editorState.end)
            assertEquals(0L, state.playheadTimeMs)
            assertEquals(0L..1_200_000L, state.window)
        }
    }

    @Nested
    inner class WaveformLoading {
        @Test
        fun `loads the waveform through the provider`() = runTest(testDispatcher) {
            load()
            viewModel.loadWaveform()
            advanceUntilIdle()

            assertNotNull(viewModel.uiState.value.waveform)
            assertFalse(viewModel.uiState.value.isLoadingWaveform)
        }

        @Test
        fun `marks the waveform as failed when generation throws`() = runTest(testDispatcher) {
            provider.error = WaveformGenerationException.DecodingFailed("boom")
            load()
            viewModel.loadWaveform()
            advanceUntilIdle()

            assertTrue(viewModel.uiState.value.waveformLoadFailed)
            assertFalse(viewModel.uiState.value.isLoadingWaveform)
        }
    }

    @Nested
    inner class EditorIntents {
        @Test
        fun `moving a point clamps it and selects it`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()

            viewModel.movePoint(TrimPoint.START, 100_000L)
            advanceUntilIdle()

            val state = viewModel.uiState.value.editorState
            assertEquals(100_000L, state.start)
            assertEquals(TrimPoint.START, state.activePoint)
        }

        @Test
        fun `selecting a point moves the playhead onto it`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.movePoint(TrimPoint.END, 900_000L)
            advanceUntilIdle()

            viewModel.selectPoint(TrimPoint.END)
            advanceUntilIdle()

            assertEquals(900_000L, viewModel.uiState.value.playheadTimeMs)
        }

        @Test
        fun `useWholeFile resets selection and parks the playhead at zero`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.movePoint(TrimPoint.START, 100_000L)
            advanceUntilIdle()

            viewModel.useWholeFile()
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertEquals(0L, state.editorState.start)
            assertEquals(1_200_000L, state.editorState.end)
            assertEquals(0L, state.playheadTimeMs)
        }
    }

    @Nested
    inner class Zoom {
        @Test
        fun `focusing a point zooms the window around it`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.movePoint(TrimPoint.START, 300_000L)
            advanceUntilIdle()

            viewModel.focusPoint(TrimPoint.START)
            advanceUntilIdle()

            val window = viewModel.uiState.value.window
            assertTrue(window.endInclusive - window.start < meditation.duration)
            assertTrue(viewModel.uiState.value.isZoomed)
        }

        @Test
        fun `zoomOut returns to the whole file without changing marks`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.movePoint(TrimPoint.START, 300_000L)
            viewModel.focusPoint(TrimPoint.START)
            advanceUntilIdle()

            viewModel.zoomOut()
            advanceUntilIdle()

            assertFalse(viewModel.uiState.value.isZoomed)
            assertEquals(300_000L, viewModel.uiState.value.editorState.start)
        }

        @Test
        fun `short files never zoom`() = runTest(testDispatcher) {
            val shortFile = meditation.copy(duration = 90_000L)
            load(shortFile)
            advanceUntilIdle()

            viewModel.focusPoint(TrimPoint.START)
            advanceUntilIdle()

            assertFalse(viewModel.uiState.value.isZoomed)
        }
    }

    @Nested
    inner class Seeking {
        @Test
        fun `seek pauses playback first and moves only the playhead`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.togglePlayback() // start playing
            advanceUntilIdle()
            audio.stopCount = 0

            viewModel.seek(400_000L)
            advanceUntilIdle()

            assertEquals(400_000L, viewModel.uiState.value.playheadTimeMs)
            assertFalse(viewModel.uiState.value.isPlaying)
            assertTrue(audio.stopCount >= 1)
        }

        @Test
        fun `playhead drag end starts playback from the new position`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.seek(400_000L)
            advanceUntilIdle()

            viewModel.playheadDragEnded()
            advanceUntilIdle()

            assertTrue(viewModel.uiState.value.isPlaying)
            assertEquals(400_000L, audio.lastSeekMs)
        }
    }

    @Nested
    inner class Playback {
        @Test
        fun `togglePlayback starts then pauses keeping the position`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.seek(200_000L)
            advanceUntilIdle()

            viewModel.togglePlayback()
            advanceUntilIdle()
            assertTrue(viewModel.uiState.value.isPlaying)

            viewModel.togglePlayback()
            advanceUntilIdle()
            assertFalse(viewModel.uiState.value.isPlaying)
            assertEquals(200_000L, viewModel.uiState.value.playheadTimeMs)
        }

        @Test
        fun `playback pauses automatically at the end point`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.movePoint(TrimPoint.END, 600_000L)
            viewModel.seek(100_000L)
            viewModel.togglePlayback()
            advanceUntilIdle()

            // Position flow reports passing the end point.
            audio.emitPosition(600_000L)
            advanceUntilIdle()

            assertFalse(viewModel.uiState.value.isPlaying)
            assertEquals(600_000L, viewModel.uiState.value.playheadTimeMs)
        }

        @Test
        fun `viewDisappeared stops audio and clears playing state`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.togglePlayback()
            advanceUntilIdle()

            viewModel.viewDisappeared()
            advanceUntilIdle()

            assertFalse(viewModel.uiState.value.isPlaying)
            assertTrue(audio.stopCount >= 1)
        }
    }

    @Nested
    inner class Preview {
        @Test
        fun `mark drag end auditions the cut briefly then parks at the mark`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.movePoint(TrimPoint.START, 100_000L)
            advanceUntilIdle()

            viewModel.markDragEnded()
            // Preview is active immediately (before the auto-stop delay elapses).
            assertTrue(viewModel.uiState.value.isPreviewing)

            // After the preview duration the preview stops and parks at the mark.
            advanceTimeBy(2_300L)
            advanceUntilIdle()
            assertFalse(viewModel.uiState.value.isPreviewing)
            assertEquals(100_000L, viewModel.uiState.value.playheadTimeMs)
        }

        @Test
        fun `nudging the active point auditions the new cut`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            viewModel.movePoint(TrimPoint.START, 100_000L)
            advanceUntilIdle()

            viewModel.nudgeActivePoint(1_000L)
            // Preview is active immediately (before the auto-stop delay elapses).
            assertEquals(101_000L, viewModel.uiState.value.editorState.start)
            assertTrue(viewModel.uiState.value.isPreviewing)
        }
    }
}

/**
 * Fake [AudioServiceProtocol] for trim-editor tests: records preview play/seek/stop and
 * lets the test drive the preview position flow.
 */
private class RecordingAudioService : AudioServiceProtocol {
    var playCount = 0
    var stopCount = 0
    var lastSeekMs: Long? = null

    private val positionBacking = MutableStateFlow(0L)
    private val durationBacking = MutableStateFlow(0L)
    private val completionBacking = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    fun emitPosition(value: Long) {
        positionBacking.value = value
    }

    override val gongCompletionFlow: SharedFlow<Unit> = MutableSharedFlow()
    override val meditationPreviewPositionFlow: StateFlow<Long> = positionBacking.asStateFlow()
    override val meditationPreviewDurationFlow: StateFlow<Long> = durationBacking.asStateFlow()
    override val meditationPreviewCompletionFlow: SharedFlow<Unit> = completionBacking.asSharedFlow()

    override fun playGongPreview(soundId: String, volume: Float) = Unit
    override fun playIntervalGong(soundId: String, volume: Float) = Unit
    override fun stopGongPreview() = Unit
    override fun playBackgroundPreview(soundId: String, volume: Float) = Unit
    override fun setBackgroundPreviewVolume(volume: Float) = Unit
    override fun stopBackgroundPreview() = Unit

    override fun playMeditationPreview(fileUri: String) {
        playCount++
    }

    override fun stopMeditationPreview() {
        stopCount++
    }

    override fun seekMeditationPreview(positionMs: Long) {
        lastSeekMs = positionMs
    }
}

/** Fake [WaveformProviderProtocol] returning a full-resolution waveform or an error. */
private class FakeProvider : WaveformProviderProtocol {
    var error: WaveformGenerationException? = null

    override suspend fun waveform(meditation: GuidedMeditation): MeditationWaveform {
        error?.let { throw it }
        return MeditationWaveform(List(MeditationWaveform.SAMPLE_COUNT) { 0.5f })
    }

    override fun precompute(meditation: GuidedMeditation) = Unit
    override fun removeCached(id: String) = Unit
}
