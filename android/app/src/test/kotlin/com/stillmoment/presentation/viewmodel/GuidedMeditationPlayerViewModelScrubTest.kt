package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.MeditationGongPlayerProtocol
import com.stillmoment.domain.services.PlaybackState
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformProviderProtocol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
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
import org.mockito.Mockito
import org.mockito.kotlin.any
import org.mockito.kotlin.mock

/**
 * Unit tests for the scrub / waveform behaviour added to [GuidedMeditationPlayerViewModel]
 * in shared-109. Drives intents and asserts state through fakes — no real audio.
 *
 * The player's UI state is range-relative (0 = trim start), so the scrub bounds and the
 * resting-time states all work inside `[0, effectiveDuration]`.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class GuidedMeditationPlayerViewModelScrubTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var player: ScrubFakePlayerService
    private lateinit var coordinator: ScrubFakeCoordinator
    private lateinit var settings: ScrubFakeSettingsRepository
    private lateinit var gong: ScrubFakeGongPlayer
    private lateinit var praxis: ScrubFakePraxisRepository
    private lateinit var waveform: ScrubFakeWaveformProvider
    private lateinit var viewModel: GuidedMeditationPlayerViewModel

    // 10-min file, trimmed to [60s, 540s] → effective duration 480s (8:00).
    private val meditation = GuidedMeditation(
        fileUri = "content://test/uri",
        fileName = "test.mp3",
        duration = 600_000L,
        teacher = "Teacher",
        name = "Name",
        trimStartMs = 60_000L,
        trimEndMs = 540_000L
    )

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        player = ScrubFakePlayerService()
        coordinator = ScrubFakeCoordinator()
        settings = ScrubFakeSettingsRepository()
        gong = ScrubFakeGongPlayer()
        praxis = ScrubFakePraxisRepository()
        waveform = ScrubFakeWaveformProvider()
        viewModel = GuidedMeditationPlayerViewModel(
            player, coordinator, settings, gong, praxis, waveform, mock()
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private suspend fun load() {
        viewModel.loadMeditation(meditation)
    }

    @Nested
    inner class WaveformLoading {
        @Test
        fun `loads the waveform through the provider`() = runTest(testDispatcher) {
            load()
            viewModel.loadWaveform()
            advanceUntilIdle()

            assertNotNull(viewModel.uiState.value.waveform)
            assertFalse(viewModel.uiState.value.waveformLoadFailed)
        }

        @Test
        fun `marks the waveform as failed when generation throws`() = runTest(testDispatcher) {
            waveform.error = WaveformGenerationException.DecodingFailed("boom")
            load()
            viewModel.loadWaveform()
            advanceUntilIdle()

            assertTrue(viewModel.uiState.value.waveformLoadFailed)
        }
    }

    @Nested
    inner class ScrubState {
        @Test
        fun `grabbing the wave pauses playback and starts dragging`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            startPlaying(positionMs = 120_000L)
            advanceUntilIdle()

            viewModel.beginScrub()

            assertTrue(viewModel.uiState.value.isDragging)
            assertTrue(player.paused)
        }

        @Test
        fun `drag position is range-relative and clamped to the effective duration`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            startPlaying(positionMs = 100_000L)
            advanceUntilIdle()

            viewModel.beginScrub()
            viewModel.scrubToMs(999_000L) // far past the trimmed end (480s)

            assertEquals(480_000L, viewModel.uiState.value.dragPositionMs)
        }

        @Test
        fun `releasing seeks to the drag position and resumes when it was playing`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            startPlaying(positionMs = 100_000L)
            advanceUntilIdle()

            viewModel.beginScrub()
            viewModel.scrubToMs(200_000L)
            viewModel.endScrub()

            assertFalse(viewModel.uiState.value.isDragging)
            // Range-relative 200s → absolute file time 60s + 200s = 260s.
            assertEquals(260_000L, player.lastSeekMs)
            assertTrue(player.resumed)
        }

        @Test
        fun `releasing does not resume when it was paused before the grab`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            // Paused at 100s (range-relative) — not playing.
            player.emit(PlaybackState(isPlaying = false, currentPosition = 160_000L, duration = 600_000L))
            advanceUntilIdle()

            viewModel.beginScrub()
            viewModel.scrubToMs(200_000L)
            viewModel.endScrub()

            assertFalse(player.resumed)
        }
    }

    @Nested
    inner class RemainingLine {
        @Test
        fun `running shows the remaining time`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            startPlaying(positionMs = 120_000L) // 120s into 480s → 360s = 6:00 left
            advanceUntilIdle()

            val state = viewModel.uiState.value.remainingLineState
            assertEquals(RemainingLineState.Remaining("6:00"), state)
        }

        @Test
        fun `paused shows the paused state`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            player.emit(PlaybackState(isPlaying = false, currentPosition = 180_000L, duration = 600_000L))
            advanceUntilIdle()

            assertEquals(RemainingLineState.Paused, viewModel.uiState.value.remainingLineState)
        }

        @Test
        fun `completed shows the finished state`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            // play() registers the completion listener; Uri.parse is an Android stub.
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())
                viewModel.play()
            }
            startPlaying(positionMs = 60_000L)
            advanceUntilIdle()
            player.fireCompletion()
            advanceUntilIdle()

            assertEquals(RemainingLineState.Finished, viewModel.uiState.value.remainingLineState)
        }
    }

    @Nested
    inner class FractionSeek {
        @Test
        fun `seek to fraction maps to range-relative position`() = runTest(testDispatcher) {
            load()
            advanceUntilIdle()
            startPlaying(positionMs = 0L)

            viewModel.seekToFraction(0.5f) // half of 480s = 240s relative

            // 240s relative → absolute 60s + 240s = 300s.
            assertEquals(300_000L, player.lastSeekMs)
        }
    }

    // MARK: - Helpers

    private fun startPlaying(positionMs: Long) {
        // positionMs is range-relative; the service reports absolute file time.
        player.emit(
            PlaybackState(
                isPlaying = true,
                currentPosition = meditation.effectiveStartMs + positionMs,
                duration = 600_000L
            )
        )
    }
}

// MARK: - Fakes

private class ScrubFakePlayerService : AudioPlayerServiceProtocol {
    private val backing = MutableStateFlow(PlaybackState())
    override val playbackState: StateFlow<PlaybackState> = backing.asStateFlow()

    var paused = false
    var resumed = false
    var lastSeekMs: Long = -1
    private var completion: (() -> Unit)? = null

    fun emit(state: PlaybackState) {
        backing.value = state
    }

    fun fireCompletion() {
        completion?.invoke()
    }

    override fun play(uri: android.net.Uri, duration: Long, trimStartMs: Long?, trimEndMs: Long?) = Unit
    override fun pause() {
        paused = true
        backing.value = backing.value.copy(isPlaying = false)
    }

    override fun resume() {
        resumed = true
        backing.value = backing.value.copy(isPlaying = true)
    }

    override fun seekTo(position: Long) {
        lastSeekMs = position
    }

    override fun stop() = Unit
    override fun setOnCompletionListener(callback: () -> Unit) {
        completion = callback
    }
}

private class ScrubFakeCoordinator : AudioSessionCoordinatorProtocol {
    private val active = MutableStateFlow<AudioSource?>(null)
    override val activeSource: StateFlow<AudioSource?> = active.asStateFlow()
    override fun registerConflictHandler(source: AudioSource, handler: () -> Unit) = Unit
    override fun registerPauseHandler(source: AudioSource, handler: () -> Unit) = Unit
    override fun requestAudioSession(source: AudioSource): Boolean {
        active.value = source
        return true
    }

    override fun releaseAudioSession(source: AudioSource) {
        active.value = null
    }
}

private class ScrubFakeSettingsRepository : GuidedMeditationSettingsRepository {
    override val settingsFlow = kotlinx.coroutines.flow.flowOf(GuidedMeditationSettings.Default)
    override suspend fun getSettings(): GuidedMeditationSettings = GuidedMeditationSettings.Default
    override suspend fun updateSettings(settings: GuidedMeditationSettings) = Unit
}

private class ScrubFakeGongPlayer : MeditationGongPlayerProtocol {
    override fun play(soundId: String, volume: Float, onComplete: () -> Unit) = onComplete()
    override fun stop() = Unit
}

private class ScrubFakePraxisRepository : PraxisRepository {
    override val praxisFlow = kotlinx.coroutines.flow.flowOf(Praxis())
    override suspend fun load(): Praxis = Praxis()
    override suspend fun save(praxis: Praxis) = Unit
}

private class ScrubFakeWaveformProvider : WaveformProviderProtocol {
    var error: WaveformGenerationException? = null
    private val sample = MeditationWaveform(List(MeditationWaveform.SAMPLE_COUNT) { 0.5f })

    override suspend fun waveform(meditation: GuidedMeditation): MeditationWaveform {
        error?.let { throw it }
        return sample
    }

    override fun precompute(meditation: GuidedMeditation) = Unit
    override fun removeCached(id: String) = Unit
}
