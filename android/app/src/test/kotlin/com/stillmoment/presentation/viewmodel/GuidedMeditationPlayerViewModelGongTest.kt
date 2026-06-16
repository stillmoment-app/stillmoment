package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.domain.models.AudioSource
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
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.Mockito
import org.mockito.kotlin.any
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Behavioural tests for the per-meditation start/end gong sequence (shared-106).
 *
 * The start gong rings before the audio (with a breath pause), the end gong rings
 * at completion before the session is released, and neither fires on resume/restart.
 * Mirrors iOS' GuidedMeditationPlayerViewModel gong flow.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class GuidedMeditationPlayerViewModelGongTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakePlayer: FakeGongAudioPlayerService
    private lateinit var fakeGong: FakeMeditationGongPlayer
    private lateinit var mockCoordinator: AudioSessionCoordinatorProtocol
    private lateinit var mockSettingsRepository: GuidedMeditationSettingsRepository
    private lateinit var mockPraxisRepository: PraxisRepository
    private lateinit var viewModel: GuidedMeditationPlayerViewModel

    private val gongMeditation =
        GuidedMeditation(
            fileUri = "content://test/uri",
            fileName = "test.mp3",
            duration = 600_000L,
            teacher = "Teacher",
            name = "With Gong",
            startGongEnabled = true,
            endGongEnabled = true,
            gongSoundId = "deep-resonance"
        )

    private val noGongMeditation =
        gongMeditation.copy(startGongEnabled = false, endGongEnabled = false)

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakePlayer = FakeGongAudioPlayerService()
        fakeGong = FakeMeditationGongPlayer()
        mockCoordinator = mock()
        mockSettingsRepository = mock()
        mockPraxisRepository = mock()
        whenever(mockCoordinator.requestAudioSession(any())).thenReturn(true)

        viewModel =
            GuidedMeditationPlayerViewModel(
                fakePlayer,
                mockCoordinator,
                mockSettingsRepository,
                fakeGong,
                mockPraxisRepository,
                mock(),
                mock()
            )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private suspend fun load(meditation: GuidedMeditation, prepSeconds: Int = 0) {
        whenever(mockSettingsRepository.getSettings())
            .thenReturn(GuidedMeditationSettings.Default.copy(preparationTimeSeconds = prepSeconds))
        whenever(mockPraxisRepository.load())
            .thenReturn(Praxis.Default.copy(gongVolume = 0.8f))
        viewModel.loadMeditation(meditation)
    }

    @Nested
    inner class StartGong {
        @Test
        fun `start gong rings before audio, audio waits for the breath pause`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(gongMeditation)
                advanceUntilIdle()

                // When: start playback (no preparation time)
                viewModel.startPlayback()
                advanceUntilIdle()

                // The gong rang at the per-meditation sound and the timer's gong volume,
                // but the audio has NOT started yet (breath pause still pending).
                assertEquals("deep-resonance", fakeGong.lastSoundId)
                assertEquals(0.8f, fakeGong.lastVolume)
                assertFalse(fakePlayer.playCalled)

                // Gong finishes → breath pause runs → audio starts.
                fakeGong.completeGong()
                advanceUntilIdle()

                assertTrue(fakePlayer.playCalled)
            }
        }

        @Test
        fun `no start gong when the meditation has it disabled`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(noGongMeditation)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()

                assertFalse(fakeGong.played)
                assertTrue(fakePlayer.playCalled)
            }
        }

        @Test
        fun `resume after pause does not ring the start gong again`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(gongMeditation)
                advanceUntilIdle()

                // Start: gong + breath pause + audio
                viewModel.startPlayback()
                advanceUntilIdle()
                fakeGong.completeGong()
                advanceUntilIdle()
                fakePlayer.emit(PlaybackState(isPlaying = true, currentPosition = 60_000L, duration = 600_000L))
                advanceUntilIdle()

                val gongCountAfterStart = fakeGong.playCount

                // Pause, then resume via the same entry point
                viewModel.startPlayback() // toggles to pause
                advanceUntilIdle()
                viewModel.startPlayback() // toggles to resume
                advanceUntilIdle()

                // No second start gong
                assertEquals(gongCountAfterStart, fakeGong.playCount)
            }
        }
    }

    @Nested
    inner class EndGong {
        @Test
        fun `end gong rings at completion before the session is released`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(gongMeditation)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()
                fakeGong.completeGong()
                advanceUntilIdle()
                fakeGong.reset()

                // When: audio reaches its end
                fakePlayer.completePlayback()
                advanceUntilIdle()

                // Then: the end gong rings, the completion screen shows, and the
                // session is NOT yet released (so the gong stays audible, locked too)
                assertTrue(fakeGong.played)
                assertEquals("deep-resonance", fakeGong.lastSoundId)
                assertTrue(viewModel.uiState.value.isCompleted)
                verify(mockCoordinator, never()).releaseAudioSession(eq(AudioSource.GUIDED_MEDITATION))

                // Once the end gong finishes, the session is released
                fakeGong.completeGong()
                advanceUntilIdle()
                verify(mockCoordinator).releaseAudioSession(eq(AudioSource.GUIDED_MEDITATION))
            }
        }

        @Test
        fun `no end gong when disabled - completion screen shows without gong`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(noGongMeditation)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()

                fakePlayer.completePlayback()
                advanceUntilIdle()

                assertFalse(fakeGong.played)
                assertTrue(viewModel.uiState.value.isCompleted)
                // Without an end gong there is no completion callback to release the
                // session — the completion path itself must release it exactly once,
                // otherwise the GUIDED_MEDITATION session leaks and blocks the timer.
                verify(mockCoordinator).releaseAudioSession(eq(AudioSource.GUIDED_MEDITATION))
            }
        }
    }
}

/**
 * Fake AudioPlayerService that records play/stop and drives the completion path.
 */
private class FakeGongAudioPlayerService : AudioPlayerServiceProtocol {
    private val _state = MutableStateFlow(PlaybackState())
    override val playbackState: StateFlow<PlaybackState> = _state.asStateFlow()

    var playCalled = false
        private set
    var stopCalled = false
        private set

    private var completionCallback: (() -> Unit)? = null

    fun emit(state: PlaybackState) {
        _state.value = state
    }

    fun completePlayback() {
        completionCallback?.invoke()
    }

    override fun play(uri: Uri, duration: Long, trimStartMs: Long?, trimEndMs: Long?) {
        playCalled = true
    }

    override fun pause() {}

    override fun resume() {}

    override fun seekTo(position: Long) {}

    override fun stop() {
        stopCalled = true
    }

    override fun setOnCompletionListener(callback: () -> Unit) {
        completionCallback = callback
    }
}

/**
 * Fake gong player that records calls and lets the test drive completion.
 */
private class FakeMeditationGongPlayer : MeditationGongPlayerProtocol {
    var played = false
        private set
    var playCount = 0
        private set
    var lastSoundId: String? = null
        private set
    var lastVolume: Float? = null
        private set

    private var pendingComplete: (() -> Unit)? = null

    override fun play(soundId: String, volume: Float, onComplete: () -> Unit) {
        played = true
        playCount++
        lastSoundId = soundId
        lastVolume = volume
        pendingComplete = onComplete
    }

    override fun stop() {
        pendingComplete = null
    }

    /** Drives the gong-finished callback. */
    fun completeGong() {
        val complete = pendingComplete
        pendingComplete = null
        complete?.invoke()
    }

    fun reset() {
        played = false
        lastSoundId = null
        lastVolume = null
    }
}
