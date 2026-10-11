package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.models.MeditationPhase
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * An interruption (phone call, voice assistant, alarm) during preparation time, start gong or
 * breath pause (shared-146): the meditation does not start during the interruption. When the
 * system gives the sound back, the pre-roll begins again by itself and the meditation begins
 * exactly once. Running playback is paused and resumed by the audio service itself.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class GuidedMeditationPlayerViewModelInterruptionTest {
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
            endGongEnabled = false,
            gongSoundId = "deep-resonance"
        )

    private val noGongMeditation = gongMeditation.copy(startGongEnabled = false)

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

    private suspend fun TestScope.load(meditation: GuidedMeditation, prepSeconds: Int = 0) {
        whenever(mockSettingsRepository.getSettings())
            .thenReturn(
                GuidedMeditationSettings.Default.copy(
                    preparationTimeEnabled = prepSeconds > 0,
                    preparationTimeSeconds = prepSeconds
                )
            )
        whenever(mockPraxisRepository.load()).thenReturn(Praxis.Default)
        viewModel.loadMeditation(meditation)
        advanceUntilIdle()
    }

    /** Lets the start gong ring out and the breath pause pass. */
    private fun TestScope.finishGongAndBreathPause() {
        fakeGong.completeGong()
        advanceUntilIdle()
    }

    /** The player waits paused at the start, with the play button. */
    private fun assertWaitingAtStart() {
        val state = viewModel.uiState.value
        assertEquals(MeditationPhase.Playing, state.phase)
        assertFalse(state.isPlaying)
        assertEquals(0L, state.currentPosition)
    }

    @Nested
    inner class InterruptionDuringPreRoll {
        @Test
        fun `during preparation the meditation does not start while interrupted`() = runTest(testDispatcher) {
            load(gongMeditation, prepSeconds = 5)
            viewModel.startPlayback()
            advanceTimeBy(2_000L)
            runCurrent()

            fakePlayer.beginInterruption()
            advanceUntilIdle()

            assertFalse(fakeGong.played)
            assertEquals(0, fakePlayer.playCount)
            assertWaitingAtStart()
        }

        @Test
        fun `during the start gong the gong falls silent and nothing starts`() = runTest(testDispatcher) {
            load(gongMeditation)
            viewModel.startPlayback()
            advanceUntilIdle()
            assertTrue(fakeGong.isRinging)

            fakePlayer.beginInterruption()
            advanceUntilIdle()
            fakeGong.completeGong()
            advanceUntilIdle()

            assertFalse(fakeGong.isRinging)
            assertEquals(0, fakePlayer.playCount)
            assertWaitingAtStart()
        }

        @Test
        fun `during the breath pause nothing starts`() = runTest(testDispatcher) {
            load(gongMeditation)
            viewModel.startPlayback()
            advanceUntilIdle()
            fakeGong.completeGong()
            advanceTimeBy(500L)
            runCurrent()

            fakePlayer.beginInterruption()
            advanceTimeBy(2_000L)
            runCurrent()
            advanceUntilIdle()

            assertEquals(0, fakePlayer.playCount)
            assertWaitingAtStart()
        }

        @Test
        fun `the announcement and the audio session stay during the interruption`() = runTest(testDispatcher) {
            load(gongMeditation)
            viewModel.startPlayback()
            advanceUntilIdle()

            fakePlayer.beginInterruption()
            advanceUntilIdle()

            assertFalse(fakePlayer.stopCalled)
            assertEquals(gongMeditation, fakePlayer.nowPlaying.value)
        }
    }

    @Nested
    inner class AfterInterruptionDuringPreRoll {
        @Test
        fun `when the sound comes back the preparation starts again and the meditation begins once`() =
            runTest(testDispatcher) {
                load(gongMeditation, prepSeconds = 5)
                viewModel.startPlayback()
                advanceTimeBy(2_000L)
                runCurrent()
                fakePlayer.beginInterruption()
                advanceUntilIdle()

                fakePlayer.endInterruption()
                runCurrent()

                assertTrue(viewModel.uiState.value.isPreparing)
                assertEquals(5, viewModel.uiState.value.countdownRemainingSeconds)
                advanceUntilIdle()
                assertTrue(fakeGong.isRinging)
                finishGongAndBreathPause()

                assertEquals(1, fakePlayer.playCount)
                assertEquals(1, fakeGong.playCount)
            }

        @Test
        fun `when the sound comes back the start gong rings again and the meditation begins once`() =
            runTest(testDispatcher) {
                load(gongMeditation)
                viewModel.startPlayback()
                advanceUntilIdle()
                fakePlayer.beginInterruption()
                advanceUntilIdle()

                fakePlayer.endInterruption()
                advanceUntilIdle()

                assertEquals(2, fakeGong.playCount)
                assertTrue(viewModel.uiState.value.isStartGongSequenceActive)
                finishGongAndBreathPause()

                assertEquals(1, fakePlayer.playCount)
                assertEquals(0L, viewModel.uiState.value.currentPosition)
            }

        @Test
        fun `without the sound coming back a tap on play starts the pre-roll again`() = runTest(testDispatcher) {
            load(gongMeditation)
            viewModel.startPlayback()
            advanceUntilIdle()
            fakePlayer.beginInterruption()
            advanceUntilIdle()

            viewModel.togglePlayPause()
            advanceUntilIdle()

            assertEquals(2, fakeGong.playCount)
            assertEquals(0, fakePlayer.playCount)
            finishGongAndBreathPause()
            assertEquals(1, fakePlayer.playCount)
        }

        @Test
        fun `a second interruption in the restarted pre-roll still begins the meditation only once`() =
            runTest(testDispatcher) {
                load(gongMeditation)
                viewModel.startPlayback()
                advanceUntilIdle()
                fakePlayer.beginInterruption()
                advanceUntilIdle()
                fakePlayer.endInterruption()
                advanceUntilIdle()

                fakePlayer.beginInterruption()
                advanceUntilIdle()
                assertEquals(0, fakePlayer.playCount)
                fakePlayer.endInterruption()
                advanceUntilIdle()
                finishGongAndBreathPause()

                assertEquals(1, fakePlayer.playCount)
                assertEquals(3, fakeGong.playCount)
            }

        @Test
        fun `a tap on play while the call still holds the sound shows no error, the pre-roll follows the call`() =
            runTest(testDispatcher) {
                load(gongMeditation)
                viewModel.startPlayback()
                advanceUntilIdle()
                fakePlayer.beginInterruption()
                advanceUntilIdle()

                whenever(mockCoordinator.requestAudioSession(any())).thenReturn(false)
                viewModel.togglePlayPause()
                advanceUntilIdle()

                assertNull(viewModel.uiState.value.error)
                assertEquals(1, fakeGong.playCount)
                assertWaitingAtStart()

                whenever(mockCoordinator.requestAudioSession(any())).thenReturn(true)
                fakePlayer.endInterruption()
                advanceUntilIdle()
                finishGongAndBreathPause()

                assertEquals(2, fakeGong.playCount)
                assertEquals(1, fakePlayer.playCount)
            }

        @Test
        fun `closing the player before the sound comes back starts nothing`() = runTest(testDispatcher) {
            load(gongMeditation, prepSeconds = 5)
            viewModel.startPlayback()
            runCurrent()
            fakePlayer.beginInterruption()
            advanceUntilIdle()

            viewModel.stop()
            fakePlayer.endInterruption()
            advanceUntilIdle()

            assertFalse(viewModel.uiState.value.isPreparing)
            assertFalse(fakeGong.played)
            assertEquals(0, fakePlayer.playCount)
        }

        @Test
        fun `after a stop from outside a tap on play starts the meditation directly`() = runTest(testDispatcher) {
            load(gongMeditation)
            viewModel.startPlayback()
            advanceUntilIdle()
            fakePlayer.beginInterruption()
            advanceUntilIdle()

            fakePlayer.stopFromOutside()
            advanceUntilIdle()
            viewModel.togglePlayPause()
            advanceUntilIdle()

            assertEquals(1, fakePlayer.playCount)
            assertEquals(1, fakeGong.playCount)
        }
    }

    @Nested
    inner class InterruptionDuringPlayback {
        @Test
        fun `an interruption while the meditation loads shows it paused, not loading`() = runTest(testDispatcher) {
            load(noGongMeditation)
            viewModel.startPlayback()
            advanceUntilIdle()
            assertTrue(viewModel.uiState.value.isLoading)

            fakePlayer.beginInterruption()
            advanceUntilIdle()

            assertFalse(viewModel.uiState.value.isLoading)
            assertWaitingAtStart()
        }

        @Test
        fun `an interruption after the meditation began does not ring the gong or start it again`() =
            runTest(testDispatcher) {
                load(gongMeditation)
                viewModel.startPlayback()
                advanceUntilIdle()
                finishGongAndBreathPause()

                fakePlayer.beginInterruption()
                advanceUntilIdle()
                fakePlayer.endInterruption()
                advanceUntilIdle()

                assertEquals(1, fakePlayer.playCount)
                assertEquals(1, fakeGong.playCount)
            }

        @Test
        fun `without pre-roll an interruption leaves the meditation to the audio service`() = runTest(testDispatcher) {
            load(noGongMeditation)
            viewModel.startPlayback()
            advanceUntilIdle()

            fakePlayer.beginInterruption()
            advanceUntilIdle()
            fakePlayer.endInterruption()
            advanceUntilIdle()

            assertEquals(1, fakePlayer.playCount)
            assertFalse(fakeGong.played)
            assertFalse(fakePlayer.stopCalled)
        }
    }

    @Test
    fun `the audio session is taken once at the tap, not again when the pre-roll restarts`() = runTest(testDispatcher) {
        load(gongMeditation)
        viewModel.startPlayback()
        advanceUntilIdle()
        fakePlayer.beginInterruption()
        advanceUntilIdle()

        fakePlayer.endInterruption()
        advanceUntilIdle()

        verify(mockCoordinator).requestAudioSession(AudioSource.GUIDED_MEDITATION)
    }
}
