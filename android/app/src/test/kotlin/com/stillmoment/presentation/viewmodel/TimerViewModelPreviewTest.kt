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
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for ViewModel audio preview delegation.
 * Verifies that preview calls are forwarded to AudioServiceProtocol with correct parameters.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelPreviewTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeSettingsRepository: FakeSettingsRepository
    private lateinit var fakeTimerRepository: FakeTimerRepository
    private lateinit var fakeAudioService: FakeAudioService
    private lateinit var fakeForegroundService: FakeTimerForegroundService
    private lateinit var fakePraxisRepository: FakePraxisRepository
    private lateinit var mockApplication: Application

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeSettingsRepository = FakeSettingsRepository()
        fakeTimerRepository = FakeTimerRepository()
        fakeAudioService = FakeAudioService()
        fakeForegroundService = FakeTimerForegroundService()
        fakePraxisRepository = FakePraxisRepository()
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
            praxisRepository = fakePraxisRepository
        )
    }

    @Test
    fun `playGongPreview delegates to audio service with current volume`() = runTest {
        val viewModel = createViewModel()
        advanceUntilIdle()

        // When
        viewModel.playGongPreview("singing-bowl")

        // Then
        assertEquals("singing-bowl", fakeAudioService.lastGongPreviewSoundId)
        assertEquals(
            viewModel.uiState.value.settings.gongVolume,
            fakeAudioService.lastGongPreviewVolume
        )
    }

    @Test
    fun `stopGongPreview delegates to audio service`() = runTest {
        val viewModel = createViewModel()
        advanceUntilIdle()

        // When
        viewModel.stopGongPreview()

        // Then
        assertTrue(fakeAudioService.gongPreviewStopped)
    }

    @Test
    fun `playBackgroundPreview delegates to audio service with current volume`() = runTest {
        val viewModel = createViewModel()
        advanceUntilIdle()

        // When
        viewModel.playBackgroundPreview("forest")

        // Then
        assertEquals("forest", fakeAudioService.lastBackgroundPreviewSoundId)
        assertEquals(
            viewModel.uiState.value.settings.backgroundSoundVolume,
            fakeAudioService.lastBackgroundPreviewVolume
        )
    }

    @Test
    fun `stopBackgroundPreview delegates to audio service`() = runTest {
        val viewModel = createViewModel()
        advanceUntilIdle()

        // When
        viewModel.stopBackgroundPreview()

        // Then
        assertTrue(fakeAudioService.backgroundPreviewStopped)
    }

    @Test
    fun `hideSettings stops all previews`() = runTest {
        val viewModel = createViewModel()
        advanceUntilIdle()
        viewModel.showSettings()
        advanceUntilIdle()

        // When
        viewModel.hideSettings()

        // Then
        assertTrue(fakeAudioService.gongPreviewStopped)
        assertTrue(fakeAudioService.backgroundPreviewStopped)
        assertFalse(viewModel.uiState.value.showSettings)
    }
}
