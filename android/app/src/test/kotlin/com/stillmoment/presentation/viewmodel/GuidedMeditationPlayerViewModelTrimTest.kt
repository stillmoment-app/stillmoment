package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.MeditationGongPlayerProtocol
import com.stillmoment.domain.services.PlaybackState
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
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.Mockito
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever
import org.mockito.kotlin.wheneverBlocking

/**
 * Behavioral tests for the trim-aware playback mapping (shared-105):
 * range-relative display and clamping of seeks/skips into the trim range.
 *
 * Uses a fake AudioPlayerService so the absolute file position reported by the
 * service can be driven directly, mirroring what MediaPlayer would report.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class GuidedMeditationPlayerViewModelTrimTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakePlayer: FakeAudioPlayerService
    private lateinit var mockCoordinator: AudioSessionCoordinatorProtocol
    private lateinit var mockSettingsRepository: GuidedMeditationSettingsRepository
    private lateinit var mockGongPlayer: MeditationGongPlayerProtocol
    private lateinit var mockPraxisRepository: PraxisRepository
    private lateinit var viewModel: GuidedMeditationPlayerViewModel

    // 20-min file, audible range 1:00..15:00 → effective 14:00
    private val trimmedMeditation =
        GuidedMeditation(
            fileUri = "content://test/uri",
            fileName = "test.mp3",
            duration = 1_200_000L,
            teacher = "Teacher",
            name = "Trimmed",
            trimStartMs = 60_000L,
            trimEndMs = 900_000L
        )

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakePlayer = FakeAudioPlayerService()
        mockCoordinator = mock()
        mockSettingsRepository = mock()
        mockGongPlayer = mock()
        mockPraxisRepository = mock()
        whenever(mockCoordinator.requestAudioSession(any())).thenReturn(true)
        wheneverBlocking { mockPraxisRepository.load() }.thenReturn(Praxis.Default)

        viewModel =
            GuidedMeditationPlayerViewModel(
                fakePlayer,
                mockCoordinator,
                mockSettingsRepository,
                mockGongPlayer,
                mockPraxisRepository
            )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private suspend fun loadTrimmed() {
        whenever(mockSettingsRepository.getSettings())
            .thenReturn(GuidedMeditationSettings.Default)
        viewModel.loadMeditation(trimmedMeditation)
    }

    @Nested
    inner class RangeRelativeDisplay {
        @Test
        fun `loaded duration is the effective duration`() = runTest(testDispatcher) {
            loadTrimmed()
            advanceUntilIdle()

            // 15:00 - 1:00 = 14:00
            assertEquals(840_000L, viewModel.uiState.value.duration)
            assertEquals("14:00", viewModel.uiState.value.formattedDuration)
        }

        @Test
        fun `position is reported relative to the trim start`() = runTest(testDispatcher) {
            loadTrimmed()
            advanceUntilIdle()

            // Service reports an absolute file position of 3:00
            fakePlayer.emit(PlaybackState(isPlaying = true, currentPosition = 180_000L, duration = 1_200_000L))
            advanceUntilIdle()

            // Relative to a 1:00 start → 2:00 displayed
            assertEquals(120_000L, viewModel.uiState.value.currentPosition)
            assertEquals("2:00", viewModel.uiState.value.formattedPosition)
        }

        @Test
        fun `progress is computed over the effective duration`() = runTest(testDispatcher) {
            loadTrimmed()
            advanceUntilIdle()

            // Halfway through the trimmed range: 1:00 + 7:00 = 8:00 absolute
            fakePlayer.emit(PlaybackState(isPlaying = true, currentPosition = 480_000L, duration = 1_200_000L))
            advanceUntilIdle()

            assertEquals(0.5f, viewModel.uiState.value.progress, 0.001f)
        }
    }

    @Nested
    inner class SeekClamping {
        @Test
        fun `seekTo translates a relative position to absolute file time`() = runTest(testDispatcher) {
            loadTrimmed()
            advanceUntilIdle()

            // Seek to 2:00 within the trimmed range
            viewModel.seekTo(120_000L)

            // Absolute = trim start (1:00) + 2:00 = 3:00
            assertEquals(180_000L, fakePlayer.lastSeekTo)
        }

        @Test
        fun `skip forward never leaves the trim range`() = runTest(testDispatcher) {
            loadTrimmed()
            advanceUntilIdle()

            // Near the end of the trimmed range (13:50 relative = 14:50 absolute)
            fakePlayer.emit(PlaybackState(isPlaying = true, currentPosition = 890_000L, duration = 1_200_000L))
            advanceUntilIdle()

            // Skip forward 30s would overshoot the 14:00 effective end
            viewModel.skipForward(30)

            // Clamped to the effective end (14:00 relative = 15:00 absolute)
            assertEquals(900_000L, fakePlayer.lastSeekTo)
        }

        @Test
        fun `skip backward never leaves the trim range`() = runTest(testDispatcher) {
            loadTrimmed()
            advanceUntilIdle()

            // Just after the trimmed start (0:05 relative = 1:05 absolute)
            fakePlayer.emit(PlaybackState(isPlaying = true, currentPosition = 65_000L, duration = 1_200_000L))
            advanceUntilIdle()

            // Skip back 10s would underflow before the 1:00 start
            viewModel.skipBackward(10)

            // Clamped to the effective start (0:00 relative = 1:00 absolute)
            assertEquals(60_000L, fakePlayer.lastSeekTo)
        }
    }

    @Nested
    inner class RestartAfterCompletion {
        @Test
        fun `restart after completion begins at the trim start`() = runTest(testDispatcher) {
            // Uri.parse is an Android stub; stub it so play() can run in a JVM test.
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                loadTrimmed()
                advanceUntilIdle()

                // Start playback so the completion listener is registered, then finish.
                viewModel.play()
                advanceUntilIdle()
                fakePlayer.completePlayback()
                advanceUntilIdle()

                // Sanity: the session is marked completed.
                assertEquals(true, viewModel.uiState.value.isCompleted)

                // When: the user restarts via the play/pause toggle
                viewModel.togglePlayPause()
                advanceUntilIdle()

                // Then: the seek targets the absolute trim start (1:00), not 0.
                assertEquals(60_000L, fakePlayer.lastSeekTo)
            }
        }
    }
}

/**
 * Fake AudioPlayerService that lets a test drive the absolute playback position.
 */
private class FakeAudioPlayerService : AudioPlayerServiceProtocol {
    private val _state = MutableStateFlow(PlaybackState())
    override val playbackState: StateFlow<PlaybackState> = _state.asStateFlow()

    var lastSeekTo: Long? = null
        private set

    private var completionCallback: (() -> Unit)? = null

    fun emit(state: PlaybackState) {
        _state.value = state
    }

    /** Drives the completion path so the ViewModel marks the session as completed. */
    fun completePlayback() {
        completionCallback?.invoke()
    }

    override fun play(uri: Uri, duration: Long, trimStartMs: Long?, trimEndMs: Long?) {}

    override fun pause() {}

    override fun resume() {}

    override fun seekTo(position: Long) {
        lastSeekTo = position
    }

    override fun stop() {}

    override fun setOnCompletionListener(callback: () -> Unit) {
        completionCallback = callback
    }
}
