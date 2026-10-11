package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.models.MeditationPhase
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
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.UnconfinedTestDispatcher
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
            .thenReturn(
                GuidedMeditationSettings.Default.copy(
                    preparationTimeEnabled = prepSeconds > 0,
                    preparationTimeSeconds = prepSeconds
                )
            )
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

    /**
     * Start gong or preparation time with the screen locked right away (android-098).
     * Android 15+ refuses audio focus in the background without a foreground service, so
     * both are taken at the tap, before gong or countdown run.
     */
    @Nested
    inner class StartWithScreenLocked {
        @Test
        fun `with a start gong the meditation is announced and the audio session taken at the tap`() =
            runTest(testDispatcher) {
                load(gongMeditation)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()

                // Gong rings, audio not yet started — but the session is already ours and the
                // meditation is on the lock screen and in the notification.
                assertTrue(fakeGong.played)
                assertFalse(fakePlayer.playCalled)
                verify(mockCoordinator).requestAudioSession(AudioSource.GUIDED_MEDITATION)
                assertEquals(gongMeditation, fakePlayer.announcedMeditation)
            }

        @Test
        fun `with preparation time the meditation is announced and the audio session taken at the tap`() =
            runTest(testDispatcher) {
                load(noGongMeditation, prepSeconds = 10)
                advanceUntilIdle()

                viewModel.startPlayback()
                testScheduler.runCurrent()

                assertTrue(viewModel.uiState.value.isPreparing)
                assertFalse(fakePlayer.playCalled)
                verify(mockCoordinator).requestAudioSession(AudioSource.GUIDED_MEDITATION)
                assertEquals(noGongMeditation, fakePlayer.announcedMeditation)
            }

        @Test
        fun `after preparation and start gong the meditation plays`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(gongMeditation, prepSeconds = 5)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()
                fakeGong.completeGong()
                advanceUntilIdle()

                assertTrue(fakePlayer.playCalled)
            }
        }

        @Test
        fun `without start gong and preparation nothing is announced beforehand`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(noGongMeditation)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()

                assertEquals(null, fakePlayer.announcedMeditation)
                assertTrue(fakePlayer.playCalled)
            }
        }

        @Test
        fun `when the audio session is refused at the tap, neither gong nor countdown starts`() =
            runTest(testDispatcher) {
                whenever(mockCoordinator.requestAudioSession(any())).thenReturn(false)
                load(gongMeditation, prepSeconds = 10)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()

                assertFalse(fakeGong.played)
                assertFalse(viewModel.uiState.value.isPreparing)
                assertEquals(null, fakePlayer.announcedMeditation)
                assertTrue(viewModel.uiState.value.error != null)
            }

        @Test
        fun `closing the player during the start gong ends everything and nothing plays afterwards`() =
            runTest(testDispatcher) {
                load(gongMeditation)
                advanceUntilIdle()
                viewModel.startPlayback()
                advanceUntilIdle()

                viewModel.stop()
                fakeGong.completeGong()
                advanceUntilIdle()

                assertTrue(fakePlayer.stopCalled)
                verify(mockCoordinator).releaseAudioSession(AudioSource.GUIDED_MEDITATION)
                assertFalse(fakePlayer.playCalled)
            }

        @Test
        fun `closing the player during preparation ends everything and nothing plays afterwards`() =
            runTest(testDispatcher) {
                load(gongMeditation, prepSeconds = 5)
                advanceUntilIdle()
                viewModel.startPlayback()
                testScheduler.runCurrent()

                viewModel.stop()
                advanceUntilIdle()

                assertTrue(fakePlayer.stopCalled)
                verify(mockCoordinator).releaseAudioSession(AudioSource.GUIDED_MEDITATION)
                assertFalse(fakeGong.played)
                assertFalse(fakePlayer.playCalled)
            }

        @Test
        fun `if the audio session is lost before the meditation begins, the announcement ends`() =
            runTest(testDispatcher) {
                // Granted at the tap, refused after the countdown (e.g. a phone call took it)
                whenever(mockCoordinator.requestAudioSession(any())).thenReturn(true, false)
                load(noGongMeditation, prepSeconds = 3)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()

                // No notification may stay behind for a meditation that never plays
                assertFalse(fakePlayer.playCalled)
                assertTrue(fakePlayer.stopCalled)
            }
    }

    /**
     * Stop from outside (lock screen, notification, headset or Bluetooth stop, voice command)
     * while the meditation has not begun yet: nothing may start afterwards.
     */
    @Nested
    inner class StopFromOutsideBeforeAudio {
        @Test
        fun `stop from outside during preparation - nothing plays afterwards, player reset`() =
            runTest(testDispatcher) {
                load(gongMeditation, prepSeconds = 5)
                advanceUntilIdle()
                viewModel.startPlayback()
                testScheduler.runCurrent()

                fakePlayer.stopFromOutside()
                advanceUntilIdle()

                assertFalse(viewModel.uiState.value.isPreparing)
                assertFalse(fakeGong.played)
                assertFalse(fakePlayer.playCalled)
                verify(mockCoordinator).releaseAudioSession(AudioSource.GUIDED_MEDITATION)
            }

        @Test
        fun `stop from outside during the start gong - nothing plays afterwards`() = runTest(testDispatcher) {
            load(gongMeditation)
            advanceUntilIdle()
            viewModel.startPlayback()
            advanceUntilIdle()

            fakePlayer.stopFromOutside()
            advanceUntilIdle()
            fakeGong.completeGong()
            advanceUntilIdle()

            assertFalse(fakePlayer.playCalled)
            verify(mockCoordinator).releaseAudioSession(AudioSource.GUIDED_MEDITATION)
        }

        @Test
        fun `stop from outside during the breath pause - nothing plays afterwards`() = runTest(testDispatcher) {
            load(gongMeditation)
            advanceUntilIdle()
            viewModel.startPlayback()
            advanceUntilIdle()
            fakeGong.completeGong()
            testScheduler.runCurrent()

            fakePlayer.stopFromOutside()
            advanceUntilIdle()

            assertFalse(fakePlayer.playCalled)
        }

        @Test
        fun `after a stop from outside a new start works again`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(gongMeditation)
                advanceUntilIdle()
                viewModel.startPlayback()
                advanceUntilIdle()
                fakePlayer.stopFromOutside()
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()
                fakeGong.completeGong()
                advanceUntilIdle()

                assertTrue(fakePlayer.playCalled)
            }
        }
    }

    /**
     * Until the meditation audio begins, the player stays in the calm pre-roll view — like
     * during the preparation time: no play button, no waveform, nothing to scrub (shared-143).
     * A stray play or seek must not start the meditation a second time.
     */
    @Nested
    inner class CalmViewUntilMeditationBegins {
        @Test
        fun `player stays in the calm view while the start gong rings`() = runTest(testDispatcher) {
            load(gongMeditation)
            advanceUntilIdle()

            viewModel.startPlayback()
            advanceUntilIdle()

            assertEquals(MeditationPhase.PreRoll, viewModel.uiState.value.phase)
        }

        @Test
        fun `player stays in the calm view during the breath pause`() = runTest(testDispatcher) {
            load(gongMeditation)
            advanceUntilIdle()
            viewModel.startPlayback()
            advanceUntilIdle()

            fakeGong.completeGong()
            testScheduler.runCurrent()

            assertFalse(fakePlayer.playCalled)
            assertEquals(MeditationPhase.PreRoll, viewModel.uiState.value.phase)
        }

        @Test
        fun `after gong and breath pause the meditation begins once and the player shows it`() =
            runTest(testDispatcher) {
                Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                    uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                    load(gongMeditation)
                    advanceUntilIdle()
                    viewModel.startPlayback()
                    advanceUntilIdle()

                    fakeGong.completeGong()
                    advanceUntilIdle()

                    assertEquals(1, fakePlayer.playCount)
                    assertEquals(MeditationPhase.Playing, viewModel.uiState.value.phase)
                }
            }

        @Test
        fun `play tapped during the start gong does not start the meditation early or twice`() =
            runTest(testDispatcher) {
                Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                    uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                    load(gongMeditation)
                    advanceUntilIdle()
                    viewModel.startPlayback()
                    advanceUntilIdle()

                    viewModel.togglePlayPause()
                    advanceUntilIdle()
                    assertFalse(fakePlayer.playCalled)

                    fakeGong.completeGong()
                    advanceUntilIdle()

                    assertEquals(1, fakePlayer.playCount)
                }
            }

        @Test
        fun `play tapped during the breath pause does not start the meditation early or twice`() =
            runTest(testDispatcher) {
                Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                    uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                    load(gongMeditation)
                    advanceUntilIdle()
                    viewModel.startPlayback()
                    advanceUntilIdle()
                    fakeGong.completeGong()
                    testScheduler.runCurrent()

                    viewModel.togglePlayPause()
                    testScheduler.runCurrent()
                    assertFalse(fakePlayer.playCalled)

                    advanceUntilIdle()

                    assertEquals(1, fakePlayer.playCount)
                    assertEquals(0, fakePlayer.resumeCount)
                }
            }

        @Test
        fun `play tapped during preparation does not start the meditation`() = runTest(testDispatcher) {
            load(gongMeditation, prepSeconds = 5)
            advanceUntilIdle()
            viewModel.startPlayback()
            testScheduler.runCurrent()

            viewModel.togglePlayPause()
            testScheduler.runCurrent()

            assertFalse(fakePlayer.playCalled)
            assertTrue(viewModel.uiState.value.isPreparing)
        }

        @Test
        fun `scrubbing before the meditation begins changes nothing`() = runTest(testDispatcher) {
            load(gongMeditation)
            advanceUntilIdle()
            viewModel.startPlayback()
            advanceUntilIdle()

            viewModel.beginScrub()
            viewModel.scrubToMs(120_000L)
            viewModel.endScrub()
            viewModel.seekToFraction(0.5f)
            advanceUntilIdle()

            assertEquals(0, fakePlayer.seekCount)
            assertEquals(0L, viewModel.uiState.value.currentPosition)
            assertFalse(viewModel.uiState.value.isDragging)
        }

        @Test
        fun `preparation, gong and breath pause stay in the calm view without a playing view in between`() =
            runTest(testDispatcher) {
                Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                    uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                    load(gongMeditation, prepSeconds = 3)
                    advanceUntilIdle()

                    // Every emitted phase, unconflated
                    val phases = mutableListOf<MeditationPhase>()
                    backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
                        viewModel.uiState.collect { phases += it.phase }
                    }

                    viewModel.startPlayback()
                    advanceUntilIdle()
                    // Countdown done, gong rings, audio not yet started
                    assertTrue(fakeGong.played)
                    assertFalse(fakePlayer.playCalled)

                    // From the tap through countdown into the gong: only the calm view
                    val sinceStart = phases.dropWhile { it == MeditationPhase.Playing }
                    assertTrue(sinceStart.isNotEmpty())
                    assertTrue(sinceStart.all { it == MeditationPhase.PreRoll })

                    fakeGong.completeGong()
                    advanceUntilIdle()

                    assertEquals(MeditationPhase.Playing, phases.last())
                    assertEquals(1, fakePlayer.playCount)
                }
            }

        @Test
        fun `without gong and preparation the player shows the meditation right away`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(noGongMeditation)
                advanceUntilIdle()

                viewModel.startPlayback()
                advanceUntilIdle()

                assertEquals(MeditationPhase.Playing, viewModel.uiState.value.phase)
                assertEquals(1, fakePlayer.playCount)
            }
        }

        @Test
        fun `after a stop from outside during the gong, play starts the meditation directly`() =
            runTest(testDispatcher) {
                Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                    uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                    load(gongMeditation)
                    advanceUntilIdle()
                    viewModel.startPlayback()
                    advanceUntilIdle()
                    fakePlayer.stopFromOutside()
                    advanceUntilIdle()
                    val gongsBefore = fakeGong.playCount

                    // The player shows the play button again; tapping it plays right away
                    assertEquals(MeditationPhase.Playing, viewModel.uiState.value.phase)
                    viewModel.togglePlayPause()
                    advanceUntilIdle()

                    assertEquals(1, fakePlayer.playCount)
                    assertEquals(gongsBefore, fakeGong.playCount)
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
                // The notification (foreground service) stays while the end gong rings,
                // so it is audible with the screen locked (android-098)
                assertFalse(fakePlayer.presenceEnded)

                // Once the end gong finishes, the session is released and the notification ends
                fakeGong.completeGong()
                advanceUntilIdle()
                verify(mockCoordinator).releaseAudioSession(eq(AudioSource.GUIDED_MEDITATION))
                assertTrue(fakePlayer.presenceEnded)
                assertTrue(viewModel.uiState.value.isCompleted)
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
                assertTrue(fakePlayer.presenceEnded)
            }
        }

        @Test
        fun `restarting while the end gong rings is not ended by the gong finishing`() = runTest(testDispatcher) {
            Mockito.mockStatic(Uri::class.java).use { uriStatic ->
                uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(mock())

                load(gongMeditation)
                advanceUntilIdle()
                viewModel.startPlayback()
                advanceUntilIdle()
                fakeGong.completeGong()
                advanceUntilIdle()
                fakePlayer.completePlayback()
                advanceUntilIdle()

                // Restart while the end gong still rings, then the gong finishes
                viewModel.togglePlayPause()
                advanceUntilIdle()
                fakeGong.completeGong()
                advanceUntilIdle()

                assertFalse(fakePlayer.presenceEnded)
                verify(mockCoordinator, never()).releaseAudioSession(eq(AudioSource.GUIDED_MEDITATION))
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

    private val _nowPlaying = MutableStateFlow<GuidedMeditation?>(null)
    override val nowPlaying: StateFlow<GuidedMeditation?> = _nowPlaying.asStateFlow()

    var playCalled = false
        private set
    var playCount = 0
        private set
    var seekCount = 0
        private set
    var resumeCount = 0
        private set
    var stopCalled = false
        private set
    var presenceEnded = false
        private set

    private var completionCallback: (() -> Unit)? = null

    fun emit(state: PlaybackState) {
        _state.value = state
    }

    fun completePlayback() {
        completionCallback?.invoke()
    }

    /** Stop from the lock screen, the notification or a headset button. */
    fun stopFromOutside() {
        stop()
    }

    var announcedMeditation: GuidedMeditation? = null
        private set

    override fun announce(meditation: GuidedMeditation) {
        announcedMeditation = meditation
        _nowPlaying.value = meditation
    }

    override fun play(meditation: GuidedMeditation) {
        playCalled = true
        playCount++
        _nowPlaying.value = meditation
    }

    override fun pause() {}

    override fun resume() {
        resumeCount++
    }

    override fun seekTo(position: Long) {
        seekCount++
    }

    override fun stop() {
        stopCalled = true
        _nowPlaying.value = null
    }

    override fun endLockScreenPresence() {
        presenceEnded = true
        _nowPlaying.value = null
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
