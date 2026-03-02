package com.stillmoment.presentation.viewmodel

import android.app.Application
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.Praxis
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for introduction duration restoration logic in TimerViewModel.
 * When a user enables an introduction that clamps the duration,
 * disabling the introduction should restore the original duration.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelIntroductionTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeSettingsRepository: FakeSettingsRepository
    private lateinit var fakeTimerRepository: FakeTimerRepository
    private lateinit var fakeAudioService: FakeAudioService
    private lateinit var fakeForegroundService: FakeTimerForegroundService
    private lateinit var fakePraxisRepository: FakePraxisRepository
    private lateinit var fakeSoundCatalogRepository: FakeSoundCatalogRepository
    private lateinit var mockApplication: Application

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeSettingsRepository = FakeSettingsRepository()
        fakeTimerRepository = FakeTimerRepository()
        fakeAudioService = FakeAudioService()
        fakeForegroundService = FakeTimerForegroundService()
        fakePraxisRepository = FakePraxisRepository()
        fakeSoundCatalogRepository = FakeSoundCatalogRepository()
        mockApplication = mock()
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun createViewModel(): TimerViewModel {
        return TimerViewModel(
            application = mockApplication,
            settingsRepository = fakeSettingsRepository,
            timerRepository = fakeTimerRepository,
            audioService = fakeAudioService,
            foregroundService = fakeForegroundService,
            praxisRepository = fakePraxisRepository,
            soundCatalogRepository = fakeSoundCatalogRepository
        )
    }

    @Test
    fun `disabling introduction restores pre-introduction duration`() = runTest {
        // Given - User has 1 minute selected
        val initialSettings = MeditationSettings(durationMinutes = 1)
        fakeSettingsRepository.updateSettings(initialSettings)
        fakePraxisRepository.storedPraxis = Praxis.create(durationMinutes = 1)
        val viewModel = createViewModel()
        advanceUntilIdle()
        assertEquals(1, viewModel.uiState.value.selectedMinutes)

        // When - Enable introduction (clamps to 3 min)
        viewModel.updateSettings(
            initialSettings.copy(introductionId = "breath", introductionEnabled = true, durationMinutes = 3),
        )
        advanceUntilIdle()
        assertEquals(3, viewModel.uiState.value.selectedMinutes)

        // When - Disable introduction
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(
                introductionId = null,
                introductionEnabled = false,
            ),
        )
        advanceUntilIdle()

        // Then - Duration should restore to pre-introduction value
        assertEquals(1, viewModel.uiState.value.selectedMinutes, "Should restore to pre-introduction duration")
    }

    @Test
    fun `disabling introduction does not restore when duration was above minimum`() = runTest {
        // Given - User has 10 minutes selected (above the 3-minute minimum)
        val initialSettings = MeditationSettings(durationMinutes = 10)
        fakeSettingsRepository.updateSettings(initialSettings)
        val viewModel = createViewModel()
        advanceUntilIdle()
        assertEquals(10, viewModel.uiState.value.selectedMinutes)

        // When - Enable introduction (10 > 3, no clamping)
        viewModel.updateSettings(
            initialSettings.copy(introductionId = "breath", introductionEnabled = true, durationMinutes = 10),
        )
        advanceUntilIdle()
        assertEquals(10, viewModel.uiState.value.selectedMinutes)

        // When - Disable introduction
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(
                introductionId = null,
                introductionEnabled = false,
            ),
        )
        advanceUntilIdle()

        // Then - Duration should stay at 10
        assertEquals(10, viewModel.uiState.value.selectedMinutes, "Should stay at 10 when no clamping occurred")
    }
}
