package com.stillmoment.presentation.viewmodel

import android.app.Application
import com.stillmoment.domain.models.TimerState
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
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for ViewModel foreground service interaction and protocol abstraction.
 * Verifies that the ViewModel can work with protocol-conforming fakes (no infrastructure imports).
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelForegroundServiceTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeTimerRepository: FakeTimerRepository
    private lateinit var fakeAudioService: FakeAudioService
    private lateinit var fakeForegroundService: FakeTimerForegroundService
    private lateinit var fakePraxisRepository: FakePraxisRepository
    private lateinit var fakeSoundCatalogRepository: FakeSoundCatalogRepository
    private lateinit var fakeCustomAudioRepository: FakeCustomAudioRepository
    private lateinit var mockApplication: Application

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeTimerRepository = FakeTimerRepository()
        fakeAudioService = FakeAudioService()
        fakeForegroundService = FakeTimerForegroundService()
        fakePraxisRepository = FakePraxisRepository()
        fakeSoundCatalogRepository = FakeSoundCatalogRepository()
        fakeCustomAudioRepository = FakeCustomAudioRepository()
        mockApplication = mock()
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun createViewModel(): TimerViewModel {
        return TimerViewModel(
            application = mockApplication,
            timerRepository = fakeTimerRepository,
            audioService = fakeAudioService,
            foregroundService = fakeForegroundService,
            praxisRepository = fakePraxisRepository,
            soundCatalogRepository = fakeSoundCatalogRepository,
            customAudioRepository = fakeCustomAudioRepository,
            attunementResolver = FakeAttunementResolver(),
            soundscapeResolver = FakeSoundscapeResolver()
        )
    }

    @Test
    fun `ViewModel uses protocol dependencies not concrete classes`() = runTest {
        // This test verifies that the ViewModel can be constructed
        // with protocol-conforming fakes (no infrastructure imports needed)
        val viewModel = createViewModel()
        advanceUntilIdle()

        // Verify initial state is correct
        assertEquals(TimerState.Idle, viewModel.uiState.value.timerState)
    }

    @Test
    fun `startTimer dispatches foreground service start`() = runTest {
        val viewModel = createViewModel()
        advanceUntilIdle()

        // When
        viewModel.startTimer()
        advanceUntilIdle()

        // Then - foreground service was started
        assertTrue(fakeForegroundService.serviceStarted)
    }

    @Test
    fun `resetTimer does not interact with foreground service`() = runTest {
        val viewModel = createViewModel()
        advanceUntilIdle()

        // When - reset without starting
        viewModel.resetTimer()
        advanceUntilIdle()

        // Then - no foreground service interaction
        assertFalse(fakeForegroundService.serviceStarted)
        assertFalse(fakeForegroundService.serviceStopped)
    }
}
