package com.stillmoment.presentation.viewmodel

import android.app.Application
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerState
import com.stillmoment.domain.repositories.SettingsRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.TimerForegroundServiceProtocol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
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
 * Unit tests for TimerUiState and TimerViewModel.
 * Tests the pure data class logic and ViewModel behavior with fake dependencies.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelTest {
    // MARK: - TimerUiState Tests

    @Test
    fun `initial state has correct default values`() {
        val state = TimerUiState()

        assertEquals(TimerState.Idle, state.timerState)
        assertEquals(10, state.selectedMinutes)
        assertEquals(0, state.remainingSeconds)
        assertEquals(0f, state.progress)
        assertNull(state.errorMessage)
        assertFalse(state.showSettings)
        assertFalse(state.showSettingsHint)
    }

    @Test
    fun `default settings have correct values`() {
        val state = TimerUiState()
        val settings = state.settings

        assertFalse(settings.intervalGongsEnabled)
        assertEquals(5, settings.intervalMinutes)
        assertEquals("silent", settings.backgroundSoundId)
    }

    // MARK: - canStart Tests

    @Test
    fun `canStart returns true when idle with valid minutes`() {
        val state =
            TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Idle,
                    selectedMinutes = 10
                )
            )
        assertTrue(state.canStart)
    }

    @Test
    fun `canStart returns false when not idle`() {
        val runningState =
            TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Running,
                    selectedMinutes = 10
                )
            )
        assertFalse(runningState.canStart)
    }

    @Test
    fun `canStart returns false when minutes is zero`() {
        val state =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle, selectedMinutes = 0)
            )
        assertFalse(state.canStart)
    }

    // MARK: - canReset Tests

    @Test
    fun `canReset returns true when not idle`() {
        val runningState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Running)
            )
        assertTrue(runningState.canReset)

        val completedState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Completed)
            )
        assertTrue(completedState.canReset)
    }

    @Test
    fun `canReset returns false when idle`() {
        val idleState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle)
            )
        assertFalse(idleState.canReset)
    }

    // MARK: - isPreparation Tests

    @Test
    fun `isPreparation returns correct value based on state`() {
        val idleState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle)
            )
        assertFalse(idleState.isPreparation)

        val countdownState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Preparation)
            )
        assertTrue(countdownState.isPreparation)

        val runningState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Running)
            )
        assertFalse(runningState.isPreparation)

        val completedState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Completed)
            )
        assertFalse(completedState.isPreparation)
    }

    // MARK: - formattedTime Tests

    @Test
    fun `formattedTime shows countdown seconds during countdown state`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Preparation,
                    remainingPreparationSeconds = 15
                )
            )
        assertEquals("15", state.formattedTime)
    }

    @Test
    fun `formattedTime shows MM SS format when running`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 305 // 5:05
                )
            )
        assertEquals("05:05", state.formattedTime)
    }

    @Test
    fun `formattedTime handles zero remaining seconds`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 0
                )
            )
        assertEquals("00:00", state.formattedTime)
    }

    @Test
    fun `formattedTime formats full hour correctly`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 3600 // 60:00
                )
            )
        assertEquals("60:00", state.formattedTime)
    }

    @Test
    fun `formattedTime handles single digit countdown`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Preparation,
                    remainingPreparationSeconds = 5
                )
            )
        assertEquals("5", state.formattedTime)
    }

    // MARK: - Settings Integration Tests

    @Test
    fun `state with custom settings preserves values`() {
        val customSettings =
            MeditationSettings(
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                backgroundSoundId = "forest",
                durationMinutes = 20
            )

        val state = TimerUiState(settings = customSettings)

        assertTrue(state.settings.intervalGongsEnabled)
        assertEquals(10, state.settings.intervalMinutes)
        assertEquals("forest", state.settings.backgroundSoundId)
        assertEquals(20, state.settings.durationMinutes)
    }

    // MARK: - State Copy Tests

    @Test
    fun `copy preserves unchanged values`() {
        val original =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Running,
                    selectedMinutes = 15,
                    remainingSeconds = 500,
                    progress = 0.5f
                )
            )

        val updated =
            original.copy(
                displayState = original.displayState.copy(progress = 0.6f)
            )

        assertEquals(TimerState.Running, updated.timerState)
        assertEquals(15, updated.selectedMinutes)
        assertEquals(500, updated.remainingSeconds)
        assertEquals(0.6f, updated.progress)
    }

    @Test
    fun `copy with new state updates derived properties`() {
        val idle =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle)
            )
        assertTrue(idle.canStart)
        assertFalse(idle.canReset)

        val running =
            idle.copy(
                displayState = idle.displayState.copy(timerState = TimerState.Running)
            )
        assertFalse(running.canStart)
        assertTrue(running.canReset)
    }

    // MARK: - Settings Hint Tests

    @Test
    fun `showSettingsHint default is false`() {
        val state = TimerUiState()
        assertFalse(state.showSettingsHint)
    }

    @Test
    fun `showSettingsHint can be set to true`() {
        val state = TimerUiState(showSettingsHint = true)
        assertTrue(state.showSettingsHint)
    }

    @Test
    fun `showSettingsHint can be toggled via copy`() {
        val initial = TimerUiState(showSettingsHint = true)
        assertTrue(initial.showSettingsHint)

        val dismissed = initial.copy(showSettingsHint = false)
        assertFalse(dismissed.showSettingsHint)
    }

    @Test
    fun `showSettingsHint is independent of showSettings`() {
        // Hint visible, settings closed
        val hintVisible = TimerUiState(showSettingsHint = true, showSettings = false)
        assertTrue(hintVisible.showSettingsHint)
        assertFalse(hintVisible.showSettings)

        // Both can be false
        val bothHidden = TimerUiState(showSettingsHint = false, showSettings = false)
        assertFalse(bothHidden.showSettingsHint)
        assertFalse(bothHidden.showSettings)

        // Settings open, hint hidden (typical after user taps settings)
        val settingsOpen = TimerUiState(showSettingsHint = false, showSettings = true)
        assertFalse(settingsOpen.showSettingsHint)
        assertTrue(settingsOpen.showSettings)
    }

    // ============================================================
    // MARK: - ViewModel Tests with Protocol Abstractions
    // ============================================================

    @Nested
    inner class ViewModelSettingsHint {
        private val testDispatcher = StandardTestDispatcher()
        private lateinit var fakeSettingsRepository: FakeSettingsRepository
        private lateinit var fakeTimerRepository: FakeTimerRepository
        private lateinit var fakeAudioService: FakeAudioService
        private lateinit var fakeForegroundService: FakeTimerForegroundService
        private lateinit var mockApplication: Application

        @BeforeEach
        fun setUp() {
            Dispatchers.setMain(testDispatcher)
            fakeSettingsRepository = FakeSettingsRepository()
            fakeTimerRepository = FakeTimerRepository()
            fakeAudioService = FakeAudioService()
            fakeForegroundService = FakeTimerForegroundService()
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
                foregroundService = fakeForegroundService
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

    // ============================================================
    // MARK: - Introduction Duration Restoration Tests
    // ============================================================

    @Nested
    inner class IntroductionDurationRestoration {
        private val testDispatcher = StandardTestDispatcher()
        private lateinit var fakeSettingsRepository: FakeSettingsRepository
        private lateinit var fakeTimerRepository: FakeTimerRepository
        private lateinit var fakeAudioService: FakeAudioService
        private lateinit var fakeForegroundService: FakeTimerForegroundService
        private lateinit var mockApplication: Application

        @BeforeEach
        fun setUp() {
            Dispatchers.setMain(testDispatcher)
            fakeSettingsRepository = FakeSettingsRepository()
            fakeTimerRepository = FakeTimerRepository()
            fakeAudioService = FakeAudioService()
            fakeForegroundService = FakeTimerForegroundService()
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
                foregroundService = fakeForegroundService
            )
        }

        @Test
        fun `disabling introduction restores pre-introduction duration`() = runTest {
            // Given - User has 1 minute selected
            val initialSettings = MeditationSettings(durationMinutes = 1)
            fakeSettingsRepository.updateSettings(initialSettings)
            val viewModel = createViewModel()
            advanceUntilIdle()
            assertEquals(1, viewModel.uiState.value.selectedMinutes)

            // When - Enable introduction (clamps to 3 min)
            viewModel.updateSettings(initialSettings.copy(introductionId = "breath", durationMinutes = 3))
            advanceUntilIdle()
            assertEquals(3, viewModel.uiState.value.selectedMinutes)

            // When - Disable introduction
            viewModel.updateSettings(viewModel.uiState.value.settings.copy(introductionId = null))
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
            viewModel.updateSettings(initialSettings.copy(introductionId = "breath", durationMinutes = 10))
            advanceUntilIdle()
            assertEquals(10, viewModel.uiState.value.selectedMinutes)

            // When - Disable introduction
            viewModel.updateSettings(viewModel.uiState.value.settings.copy(introductionId = null))
            advanceUntilIdle()

            // Then - Duration should stay at 10
            assertEquals(10, viewModel.uiState.value.selectedMinutes, "Should stay at 10 when no clamping occurred")
        }
    }

    // ============================================================
    // MARK: - ViewModel Audio Preview Tests
    // ============================================================

    @Nested
    inner class ViewModelAudioPreview {
        private val testDispatcher = StandardTestDispatcher()
        private lateinit var fakeSettingsRepository: FakeSettingsRepository
        private lateinit var fakeTimerRepository: FakeTimerRepository
        private lateinit var fakeAudioService: FakeAudioService
        private lateinit var fakeForegroundService: FakeTimerForegroundService
        private lateinit var mockApplication: Application

        @BeforeEach
        fun setUp() {
            Dispatchers.setMain(testDispatcher)
            fakeSettingsRepository = FakeSettingsRepository()
            fakeTimerRepository = FakeTimerRepository()
            fakeAudioService = FakeAudioService()
            fakeForegroundService = FakeTimerForegroundService()
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
                foregroundService = fakeForegroundService
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

    // ============================================================
    // MARK: - ViewModel Foreground Service Tests
    // ============================================================

    @Nested
    inner class ViewModelForegroundService {
        private val testDispatcher = StandardTestDispatcher()
        private lateinit var fakeSettingsRepository: FakeSettingsRepository
        private lateinit var fakeTimerRepository: FakeTimerRepository
        private lateinit var fakeAudioService: FakeAudioService
        private lateinit var fakeForegroundService: FakeTimerForegroundService
        private lateinit var mockApplication: Application

        @BeforeEach
        fun setUp() {
            Dispatchers.setMain(testDispatcher)
            fakeSettingsRepository = FakeSettingsRepository()
            fakeTimerRepository = FakeTimerRepository()
            fakeAudioService = FakeAudioService()
            fakeForegroundService = FakeTimerForegroundService()
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
                foregroundService = fakeForegroundService
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
}

// ============================================================
// MARK: - Fake AudioServiceProtocol
// ============================================================

/**
 * Fake implementation of AudioServiceProtocol for testing.
 * Tracks method calls for verification.
 */
class FakeAudioService : AudioServiceProtocol {
    var lastGongPreviewSoundId: String? = null
    var lastGongPreviewVolume: Float? = null
    var gongPreviewStopped = false
    var lastBackgroundPreviewSoundId: String? = null
    var lastBackgroundPreviewVolume: Float? = null
    var backgroundPreviewStopped = false
    var lastIntervalGongSoundId: String? = null
    var lastIntervalGongVolume: Float? = null

    override val gongCompletionFlow: SharedFlow<Unit> = MutableSharedFlow()
    override val introductionCompletionFlow: SharedFlow<Unit> = MutableSharedFlow()

    override fun playGongPreview(soundId: String, volume: Float) {
        lastGongPreviewSoundId = soundId
        lastGongPreviewVolume = volume
    }

    override fun playIntervalGong(soundId: String, volume: Float) {
        lastIntervalGongSoundId = soundId
        lastIntervalGongVolume = volume
    }

    override fun stopGongPreview() {
        gongPreviewStopped = true
    }

    override fun playBackgroundPreview(soundId: String, volume: Float) {
        lastBackgroundPreviewSoundId = soundId
        lastBackgroundPreviewVolume = volume
    }

    override fun stopBackgroundPreview() {
        backgroundPreviewStopped = true
    }
}

// ============================================================
// MARK: - Fake TimerForegroundServiceProtocol
// ============================================================

/**
 * Fake implementation of TimerForegroundServiceProtocol for testing.
 * Tracks method calls for verification.
 */
class FakeTimerForegroundService : TimerForegroundServiceProtocol {
    var serviceStarted = false
    var serviceStopped = false
    var lastStartSoundId: String? = null
    var lastStartSoundVolume: Float? = null
    var lastStartGongSoundId: String? = null
    var lastStartGongVolume: Float? = null
    var lastGongSoundId: String? = null
    var lastGongVolume: Float? = null
    var lastIntervalGongSoundId: String? = null
    var lastIntervalGongVolume: Float? = null
    var lastIntroductionId: String? = null
    var introductionStopped = false
    var lastBackgroundAudioSoundId: String? = null
    var lastBackgroundAudioVolume: Float? = null
    var audioPaused = false
    var audioResumed = false

    override fun startService(soundId: String, soundVolume: Float, gongSoundId: String, gongVolume: Float) {
        serviceStarted = true
        lastStartSoundId = soundId
        lastStartSoundVolume = soundVolume
        lastStartGongSoundId = gongSoundId
        lastStartGongVolume = gongVolume
    }

    override fun stopService() {
        serviceStopped = true
    }

    override fun playGong(gongSoundId: String, gongVolume: Float) {
        lastGongSoundId = gongSoundId
        lastGongVolume = gongVolume
    }

    override fun playIntervalGong(gongSoundId: String, gongVolume: Float) {
        lastIntervalGongSoundId = gongSoundId
        lastIntervalGongVolume = gongVolume
    }

    override fun playIntroduction(introductionId: String) {
        lastIntroductionId = introductionId
    }

    override fun stopIntroduction() {
        introductionStopped = true
    }

    override fun updateBackgroundAudio(soundId: String, soundVolume: Float) {
        lastBackgroundAudioSoundId = soundId
        lastBackgroundAudioVolume = soundVolume
    }

    override fun pauseAudio() {
        audioPaused = true
    }

    override fun resumeAudio() {
        audioResumed = true
    }
}

// ============================================================
// MARK: - Fake SettingsRepository
// ============================================================

/**
 * Fake implementation of SettingsRepository for testing.
 * Tracks hasSeenSettingsHint state for verification.
 */
class FakeSettingsRepository : SettingsRepository {
    private val _settings = MutableStateFlow(MeditationSettings.Default)
    var hasSeenHint = false

    override val settingsFlow: Flow<MeditationSettings> = _settings

    override suspend fun updateSettings(settings: MeditationSettings) {
        _settings.value = settings
    }

    override suspend fun getSettings(): MeditationSettings = _settings.first()

    override suspend fun getHasSeenSettingsHint(): Boolean = hasSeenHint

    override suspend fun setHasSeenSettingsHint(seen: Boolean) {
        hasSeenHint = seen
    }
}

// ============================================================
// MARK: - Fake TimerRepository
// ============================================================

/**
 * Fake implementation of TimerRepository for testing.
 */
class FakeTimerRepository : TimerRepository {
    private val _timer = MutableStateFlow<MeditationTimer?>(null)

    override val timerFlow: Flow<MeditationTimer> =
        _timer.filterNotNull()

    override suspend fun start(durationMinutes: Int, preparationTimeSeconds: Int, introductionDurationSeconds: Int) {
        // no-op for tests
    }

    override suspend fun reset() {
        // no-op for tests
    }

    override suspend fun setDuration(durationMinutes: Int) {
        // no-op for tests
    }

    override fun tick(): MeditationTimer? = null

    override fun markIntervalGongPlayed() {
        // no-op for tests
    }

    override fun startIntroduction() {
        // no-op for tests
    }

    override fun endIntroduction() {
        // no-op for tests
    }
}
