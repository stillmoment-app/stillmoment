package com.stillmoment.presentation.viewmodel

import android.app.Application
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.mockito.kotlin.mock

/**
 * Regression tests for TimerViewModel.
 *
 * Naming convention: `regression_<ticket-id>_<short description>`
 * Example: `regression_shared_042_interval_gong_stops_on_reset`
 *
 * Add one test per bug fix. The test should fail on the un-fixed code
 * and pass after the fix. Reference the ticket number so the history
 * stays traceable.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelRegressionTest {
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

    @Suppress("UnusedPrivateMember") // Scaffold for future regression tests — used when tests are added
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

    // Add regression tests below, one per bug fix:
    //
    // @Test
    // fun `regression_shared_XXX_short description of the bug`() = runTest {
    //     // Given: the state that triggered the bug
    //     // When: the action that caused the regression
    //     // Then: the behaviour that must hold after the fix
    // }
}
