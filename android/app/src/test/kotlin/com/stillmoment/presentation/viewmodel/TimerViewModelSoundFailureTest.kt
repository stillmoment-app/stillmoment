package com.stillmoment.presentation.viewmodel

import android.app.Application
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
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
import org.mockito.kotlin.mock

/**
 * When a sound cannot be played during a silent meditation, the user sees one calm,
 * localized message (Pendant zu iOS `TimerViewModelAudioErrorTests`).
 *
 * Which sounds report a failure (session, background, start/interval/end gong) is
 * covered in `AudioServiceTimerSoundFailureTest`; here: report → message.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelSoundFailureTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeAudioService: FakeAudioService
    private lateinit var fakeForegroundService: FakeTimerForegroundService

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeAudioService = FakeAudioService()
        fakeForegroundService = FakeTimerForegroundService()
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun createViewModel(): TimerViewModel = TimerViewModel(
        application = mock<Application>(),
        timerRepository = FakeTimerRepository(),
        audioService = fakeAudioService,
        foregroundService = fakeForegroundService,
        praxisRepository = FakePraxisRepository(),
        soundCatalogRepository = FakeSoundCatalogRepository(),
        soundscapeResolver = FakeSoundscapeResolver()
    )

    @Nested
    inner class SoundCannotBePlayed {
        @Test
        fun `user sees the sound failed message`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            fakeAudioService.timerSoundFailedBacking.emit(Unit)
            advanceUntilIdle()

            assertEquals(TimerError.SoundFailed, viewModel.uiState.value.error)
        }

        @Test
        fun `message appears during a running session without ending it`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.startTimer()
            advanceUntilIdle()

            fakeAudioService.timerSoundFailedBacking.emit(Unit)
            advanceUntilIdle()

            assertEquals(TimerError.SoundFailed, viewModel.uiState.value.error)
            assertTrue(fakeForegroundService.serviceStarted)
            assertFalse(fakeForegroundService.serviceStopped)
        }

        @Test
        fun `repeated failures show the same single message`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            fakeAudioService.timerSoundFailedBacking.emit(Unit)
            advanceUntilIdle()
            fakeAudioService.timerSoundFailedBacking.emit(Unit)
            advanceUntilIdle()

            assertEquals(TimerError.SoundFailed, viewModel.uiState.value.error)
        }
    }

    @Nested
    inner class AllSoundsPlay {
        @Test
        fun `user sees no message`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.startTimer()
            advanceUntilIdle()

            assertNull(viewModel.uiState.value.error)
        }
    }
}
