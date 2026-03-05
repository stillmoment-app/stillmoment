package com.stillmoment.presentation.viewmodel

import android.app.Application
import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.IntervalSettings
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerEvent
import com.stillmoment.domain.models.TimerState
import com.stillmoment.domain.services.TimerReducer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Regression tests for TimerViewModel.
 *
 * Tests are at the reducer/domain level because the TimerReducer is the single source of truth
 * for effect ordering. The ViewModel executes effects in the order the reducer returns them.
 *
 * Naming convention: `regression_<ticket-id>_<short description>`
 *
 * Add one test per bug fix. The test should fail on the un-fixed code
 * and pass after the fix. Reference the ticket number so the history
 * stays traceable.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TimerViewModelRegressionTest {
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

    @Suppress("UnusedPrivateMember")
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

    // MARK: - Background Audio Start Order

    @Test
    fun `regression - background audio starts after start gong, not during preparation`() {
        // CRITICAL: Background audio must not start on StartPressed. It starts only when
        // the start gong finishes (StartGongFinished), keeping the preparation phase silent.
        // iOS ref: testBackgroundAudioStartsWhenMeditationBegins()

        val settings = MeditationSettings(
            durationMinutes = 10,
            backgroundSoundId = "forest",
            backgroundSoundVolume = 0.5f
        )

        // When - Start timer (preparation phase)
        val startEffects = TimerReducer.reduce(
            action = TimerAction.StartPressed,
            timerState = TimerState.Idle,
            selectedMinutes = 10,
            settings = settings
        )

        // Then - StartPressed must NOT produce StartBackgroundAudio
        assertFalse(
            startEffects.any { it is TimerEffect.StartBackgroundAudio },
            "Background audio must not start during preparation (StartPressed)"
        )

        // When - Preparation finishes -> play start gong
        val prepEffects = TimerReducer.reduce(
            action = TimerAction.PreparationFinished,
            timerState = TimerState.Preparation,
            selectedMinutes = 10,
            settings = settings
        )

        // Then - PreparationFinished must NOT produce StartBackgroundAudio
        assertFalse(
            prepEffects.any { it is TimerEffect.StartBackgroundAudio },
            "Background audio must not start when start gong begins playing"
        )

        // When - Start gong finishes (no introduction configured)
        val gongEffects = TimerReducer.reduce(
            action = TimerAction.StartGongFinished,
            timerState = TimerState.StartGong,
            selectedMinutes = 10,
            settings = settings
        )

        // Then - StartGongFinished MUST produce StartBackgroundAudio
        assertTrue(
            gongEffects.any { it is TimerEffect.StartBackgroundAudio },
            "Background audio must start when start gong finishes"
        )

        // Verify correct sound ID is passed
        val bgEffect = gongEffects.filterIsInstance<TimerEffect.StartBackgroundAudio>().first()
        assertEquals("forest", bgEffect.soundId)
        assertEquals(0.5f, bgEffect.soundVolume)
    }

    // MARK: - Completion Gong Before Background Audio Stop

    @Test
    fun `regression - completion gong plays before background audio stops`() {
        // CRITICAL: When the timer completes, the completion gong must play BEFORE
        // the foreground service stops. If the service stops first, the audio session
        // is released and the gong cannot play (especially on locked screen).
        // iOS ref: testCompletionGongPlaysBeforeBackgroundAudioStops()

        val settings = MeditationSettings(
            durationMinutes = 10,
            gongSoundId = "singing-bowl",
            gongVolume = 1.0f
        )

        // When - Timer reaches zero (MeditationCompleted event)
        val completionEffects = TimerReducer.reduce(
            action = TimerAction.TimerCompleted,
            timerState = TimerState.Running,
            selectedMinutes = 10,
            settings = settings
        )

        // Then - PlayCompletionSound must be emitted
        assertTrue(
            completionEffects.any { it is TimerEffect.PlayCompletionSound },
            "Completion gong must play when timer completes"
        )

        // Then - StopForegroundService must NOT be in the completion effects
        // (it comes later, from EndGongFinished, after the gong audio finishes)
        assertFalse(
            completionEffects.any { it is TimerEffect.StopForegroundService },
            "Foreground service must not stop in the same action as completion gong — " +
                "it stops only after the gong audio finishes (EndGongFinished)"
        )

        // Verify: EndGongFinished is what eventually stops the service
        val endGongEffects = TimerReducer.reduce(
            action = TimerAction.EndGongFinished,
            timerState = TimerState.EndGong,
            selectedMinutes = 10,
            settings = settings
        )

        assertTrue(
            endGongEffects.any { it is TimerEffect.StopForegroundService },
            "Foreground service must stop after end gong finishes"
        )

        // Verify the ordering within EndGongFinished: TransitionToCompleted comes first
        val completedIndex = endGongEffects.indexOfFirst { it is TimerEffect.TransitionToCompleted }
        val stopIndex = endGongEffects.indexOfFirst { it is TimerEffect.StopForegroundService }
        assertTrue(completedIndex >= 0 && stopIndex >= 0, "Both effects must be present")
        assertTrue(
            completedIndex < stopIndex,
            "TransitionToCompleted must come before StopForegroundService"
        )
    }

    // MARK: - Interval Gong Multiple Times (ios-028)

    @Test
    fun `regression_ios028 - interval gong plays multiple times, not just once`() {
        // CRITICAL: Interval gong must play at EVERY interval, not just the first.
        // Bug (ios-028): tick() did not mark lastIntervalGongAt, so it never detected
        // subsequent intervals. With shared-056, tick() emits TimerEvent.IntervalGongDue
        // and internally updates lastIntervalGongAt.
        // iOS ref: testIntervalGongPlaysMultipleTimes_NotJustOnce()

        // Given - 10-minute timer in Running state, 3-minute intervals (repeating)
        val intervalSettings = IntervalSettings(
            intervalMinutes = 3,
            mode = IntervalMode.REPEATING
        )

        var timer = MeditationTimer(
            durationMinutes = 10,
            remainingSeconds = 600,
            state = TimerState.Running
        )

        var intervalGongCount = 0

        // When - Tick through 7 minutes (420 seconds) of meditation
        // Expect gongs at: 3 min (remaining=420), 6 min (remaining=240)
        repeat(420) {
            val (ticked, events) = timer.tick(intervalSettings)
            timer = ticked
            intervalGongCount += events.count { it is TimerEvent.IntervalGongDue }
        }

        // Then - Must have played 2 interval gongs (at 3 min and 6 min)
        assertEquals(
            2,
            intervalGongCount,
            "Interval gong must play at EVERY interval (3 min and 6 min), not just the first. " +
                "Bug: tick() must mark lastIntervalGongAt and emit IntervalGongDue at each interval."
        )
    }

    // MARK: - Background Audio After Introduction

    @Test
    fun `regression - background audio starts after introduction finishes`() {
        // CRITICAL: When an introduction is configured and finishes playing,
        // background audio must start. Bug: domain timer stayed in .startGong
        // during introduction, so the .introduction guard in
        // reduceIntroductionFinished failed and no StartBackgroundAudio was emitted.
        // iOS ref: testBackgroundAudioStartsAfterIntroductionFinishes()

        // Given - Introduction configured, German locale required for "breath"
        Introduction.languageOverride = "de"
        try {
            val settings = MeditationSettings(
                durationMinutes = 5,
                introductionId = "breath",
                introductionEnabled = true,
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.3f,
            )

            // Verify: StartGongFinished with introduction -> starts introduction, no background audio
            val gongEffects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 5,
                settings = settings
            )

            assertTrue(
                gongEffects.any { it is TimerEffect.PlayIntroduction },
                "Introduction must be played after start gong finishes"
            )
            assertFalse(
                gongEffects.any { it is TimerEffect.StartBackgroundAudio },
                "Background audio must not start yet (introduction is playing)"
            )

            // When - Introduction finishes (timer must be in Introduction state)
            val introEffects = TimerReducer.reduce(
                action = TimerAction.IntroductionFinished,
                timerState = TimerState.Introduction,
                selectedMinutes = 5,
                settings = settings
            )

            // Then - Background audio MUST start after introduction finishes
            assertTrue(
                introEffects.any { it is TimerEffect.StartBackgroundAudio },
                "Background audio must start after introduction finishes. " +
                    "Bug: timer must be in Introduction state (not StartGong) when " +
                    "IntroductionFinished is dispatched."
            )

            // Verify correct sound parameters
            val bgEffect = introEffects.filterIsInstance<TimerEffect.StartBackgroundAudio>().first()
            assertEquals("forest", bgEffect.soundId)
            assertEquals(0.3f, bgEffect.soundVolume)

            // Verify introduction is stopped and phase ends
            assertTrue(
                introEffects.any { it is TimerEffect.StopIntroduction },
                "Introduction audio must be stopped"
            )
            assertTrue(
                introEffects.any { it is TimerEffect.EndIntroductionPhase },
                "Introduction phase must end in timer model"
            )
        } finally {
            Introduction.languageOverride = null
        }
    }
}
