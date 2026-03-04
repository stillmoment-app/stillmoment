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
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for ViewModel settings hint visibility and persistence behavior.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelSettingsHintTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeSettingsRepository: FakeSettingsRepository
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
        fakeSettingsRepository = FakeSettingsRepository()
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
            settingsRepository = fakeSettingsRepository,
            timerRepository = fakeTimerRepository,
            audioService = fakeAudioService,
            foregroundService = fakeForegroundService,
            praxisRepository = fakePraxisRepository,
            soundCatalogRepository = fakeSoundCatalogRepository,
            customAudioRepository = fakeCustomAudioRepository
        )
    }

    @Test
    fun `shows hint when user has not seen it before`() = runTest {
        // Given - hint has not been seen
        fakeSettingsRepository.hasSeenHint = false

        // When
        val viewModel = createViewModel()
        advanceUntilIdle()

        // Then
        assertTrue(viewModel.uiState.value.showSettingsHint)
    }

    @Test
    fun `hides hint when user has already seen it`() = runTest {
        // Given - hint has been seen
        fakeSettingsRepository.hasSeenHint = true

        // When
        val viewModel = createViewModel()
        advanceUntilIdle()

        // Then
        assertFalse(viewModel.uiState.value.showSettingsHint)
    }

    @Test
    fun `dismissSettingsHint persists via repository`() = runTest {
        // Given - hint has not been seen
        fakeSettingsRepository.hasSeenHint = false
        val viewModel = createViewModel()
        advanceUntilIdle()
        assertTrue(viewModel.uiState.value.showSettingsHint)

        // When
        viewModel.dismissSettingsHint()
        advanceUntilIdle()

        // Then - hint hidden in UI
        assertFalse(viewModel.uiState.value.showSettingsHint)
        // And persisted via repository
        assertTrue(fakeSettingsRepository.hasSeenHint)
    }

    @Test
    fun `showSettings dismisses hint and persists`() = runTest {
        // Given - hint visible
        fakeSettingsRepository.hasSeenHint = false
        val viewModel = createViewModel()
        advanceUntilIdle()
        assertTrue(viewModel.uiState.value.showSettingsHint)

        // When - user taps settings
        viewModel.showSettings()
        advanceUntilIdle()

        // Then - hint dismissed and persisted
        assertFalse(viewModel.uiState.value.showSettingsHint)
        assertTrue(viewModel.uiState.value.showSettings)
        assertTrue(fakeSettingsRepository.hasSeenHint)
    }

    @Test
    fun `dismissSettingsHint is idempotent when already dismissed`() = runTest {
        // Given - hint already seen
        fakeSettingsRepository.hasSeenHint = true
        val viewModel = createViewModel()
        advanceUntilIdle()

        // When - dismiss called again
        viewModel.dismissSettingsHint()
        advanceUntilIdle()

        // Then - still seen, no side effects
        assertFalse(viewModel.uiState.value.showSettingsHint)
        assertTrue(fakeSettingsRepository.hasSeenHint)
    }
}
