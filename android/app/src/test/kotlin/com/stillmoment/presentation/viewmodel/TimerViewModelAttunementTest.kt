package com.stillmoment.presentation.viewmodel

import android.app.Application
import com.stillmoment.domain.models.Praxis
import com.stillmoment.testutil.MockAttunementResolver
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
 * Unit tests for attunement duration restoration logic in TimerViewModel.
 * When a user enables an attunement that clamps the duration,
 * disabling the attunement should restore the original duration.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelAttunementTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeTimerRepository: FakeTimerRepository
    private lateinit var fakeAudioService: FakeAudioService
    private lateinit var fakeForegroundService: FakeTimerForegroundService
    private lateinit var fakePraxisRepository: FakePraxisRepository
    private lateinit var fakeSoundCatalogRepository: FakeSoundCatalogRepository
    private lateinit var mockApplication: Application

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
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
            timerRepository = fakeTimerRepository,
            audioService = fakeAudioService,
            foregroundService = fakeForegroundService,
            praxisRepository = fakePraxisRepository,
            soundCatalogRepository = fakeSoundCatalogRepository,
            attunementResolver = MockAttunementResolver(),
            soundscapeResolver = FakeSoundscapeResolver()
        )
    }

    @Test
    fun `disabling attunement restores pre-attunement duration`() = runTest {
        // Given - User has 1 minute selected
        fakePraxisRepository.storedPraxis = Praxis.create(durationMinutes = 1)
        val viewModel = createViewModel()
        advanceUntilIdle()
        assertEquals(1, viewModel.uiState.value.selectedMinutes)

        // When - Enable attunement (clamps to 3 min)
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(
                attunementId = "breath",
                attunementEnabled = true,
                durationMinutes = 3
            ),
        )
        advanceUntilIdle()
        assertEquals(3, viewModel.uiState.value.selectedMinutes)

        // When - Disable attunement
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(
                attunementId = null,
                attunementEnabled = false,
            ),
        )
        advanceUntilIdle()

        // Then - Duration should restore to pre-attunement value
        assertEquals(1, viewModel.uiState.value.selectedMinutes, "Should restore to pre-attunement duration")
    }

    @Test
    fun `toggle off preserves attunementId selection`() = runTest {
        // Given - ViewModel with attunement enabled
        val viewModel = createViewModel()
        advanceUntilIdle()
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(
                attunementId = "breath",
                attunementEnabled = true,
                durationMinutes = 5
            )
        )
        advanceUntilIdle()
        assertEquals("breath", viewModel.uiState.value.settings.attunementId)
        assertEquals(true, viewModel.uiState.value.settings.attunementEnabled)

        // When - Toggle off (keep attunementId, only disable)
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(attunementEnabled = false)
        )
        advanceUntilIdle()

        // Then - attunementId is still preserved, only attunementEnabled changed
        assertEquals(false, viewModel.uiState.value.settings.attunementEnabled)
        assertEquals(
            "breath",
            viewModel.uiState.value.settings.attunementId,
            "Selection should be preserved when toggle is turned off"
        )
    }

    @Test
    fun `toggle on restores previous selection`() = runTest {
        // Given - ViewModel with attunement previously selected but now disabled
        val viewModel = createViewModel()
        advanceUntilIdle()
        // First enable with a selection
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(
                attunementId = "breath",
                attunementEnabled = true,
                durationMinutes = 5
            )
        )
        advanceUntilIdle()
        // Then disable (preserving the attunementId)
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(attunementEnabled = false)
        )
        advanceUntilIdle()
        assertEquals(false, viewModel.uiState.value.settings.attunementEnabled)
        assertEquals("breath", viewModel.uiState.value.settings.attunementId)

        // When - Toggle on again
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(attunementEnabled = true)
        )
        advanceUntilIdle()

        // Then - attunementId is still "breath"
        assertEquals(true, viewModel.uiState.value.settings.attunementEnabled)
        assertEquals(
            "breath",
            viewModel.uiState.value.settings.attunementId,
            "Selection should be restored when toggle is turned back on"
        )
    }

    @Test
    fun `disabling attunement does not restore when duration was above minimum`() = runTest {
        // Given - User has 10 minutes selected (above the 3-minute minimum)
        fakePraxisRepository.storedPraxis = Praxis.create(durationMinutes = 10)
        val viewModel = createViewModel()
        advanceUntilIdle()
        assertEquals(10, viewModel.uiState.value.selectedMinutes)

        // When - Enable attunement (10 > 3, no clamping)
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(
                attunementId = "breath",
                attunementEnabled = true,
                durationMinutes = 10
            ),
        )
        advanceUntilIdle()
        assertEquals(10, viewModel.uiState.value.selectedMinutes)

        // When - Disable attunement
        viewModel.updateSettings(
            viewModel.uiState.value.settings.copy(
                attunementId = null,
                attunementEnabled = false,
            ),
        )
        advanceUntilIdle()

        // Then - Duration should stay at 10
        assertEquals(10, viewModel.uiState.value.selectedMinutes, "Should stay at 10 when no clamping occurred")
    }
}
