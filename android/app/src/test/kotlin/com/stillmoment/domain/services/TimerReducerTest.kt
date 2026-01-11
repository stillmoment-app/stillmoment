package com.stillmoment.domain.services

import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerState
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for TimerReducer.
 *
 * Tests verify that the reducer is a pure function:
 * - Same inputs always produce same outputs
 * - No side effects (all I/O represented as TimerEffect)
 * - No mocks needed - just state in, state + effects out
 */
class TimerReducerTest {
    private val defaultSettings = MeditationSettings.Default

    // MARK: - SelectDuration Tests

    @Nested
    inner class SelectDuration {
        @Test
        fun `updates selectedMinutes with valid value`() {
            // Given
            val state = TimerDisplayState.Initial

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.SelectDuration(20),
                    defaultSettings
                )

            // Then
            assertEquals(20, newState.selectedMinutes)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `clamps duration to minimum of 1`() {
            // Given
            val state = TimerDisplayState.Initial

            // When
            val (newState, _) =
                TimerReducer.reduce(
                    state,
                    TimerAction.SelectDuration(0),
                    defaultSettings
                )

            // Then
            assertEquals(1, newState.selectedMinutes)
        }

        @Test
        fun `clamps duration to maximum of 60`() {
            // Given
            val state = TimerDisplayState.Initial

            // When
            val (newState, _) =
                TimerReducer.reduce(
                    state,
                    TimerAction.SelectDuration(100),
                    defaultSettings
                )

            // Then
            assertEquals(60, newState.selectedMinutes)
        }
    }

    // MARK: - StartPressed Tests

    @Nested
    inner class StartPressed {
        @Test
        fun `starts timer with correct effects`() {
            // Given
            val state = TimerDisplayState.Initial.copy(selectedMinutes = 15)
            val settings = defaultSettings.copy(backgroundSoundId = "forest")

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )

            // Then - State transitions to Countdown
            assertEquals(TimerState.Preparation, newState.timerState)
            assertEquals(15, newState.remainingPreparationSeconds)
            assertFalse(newState.intervalGongPlayedForCurrentInterval)
            assertEquals(1, newState.currentAffirmationIndex) // Rotated from 0

            // Verify effects
            assertTrue(effects.any { it is TimerEffect.StartForegroundService && it.soundId == "forest" })
            assertTrue(effects.contains(TimerEffect.StartTimer(15)))
            assertTrue(effects.any { it is TimerEffect.SaveSettings })
        }

        @Test
        fun `does nothing when selectedMinutes is zero`() {
            // Given
            val state = TimerDisplayState.Initial.copy(selectedMinutes = 0)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    defaultSettings
                )

            // Then
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `rotates affirmation index`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    selectedMinutes = 10,
                    currentAffirmationIndex = 4
                )

            // When
            val (newState, _) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    defaultSettings
                )

            // Then
            assertEquals(0, newState.currentAffirmationIndex) // 4 + 1 = 5, 5 % 5 = 0
        }

        @Test
        fun `resets intervalGongPlayedForCurrentInterval`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    selectedMinutes = 10,
                    intervalGongPlayedForCurrentInterval = true
                )

            // When
            val (newState, _) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    defaultSettings
                )

            // Then
            assertFalse(newState.intervalGongPlayedForCurrentInterval)
        }

        @Test
        fun `passes gongSoundId to StartForegroundService effect`() {
            // Given
            val state = TimerDisplayState.Initial.copy(selectedMinutes = 10)
            val settings = defaultSettings.copy(gongSoundId = "deep-zen")

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )

            // Then
            val serviceEffect = effects.filterIsInstance<TimerEffect.StartForegroundService>().first()
            assertEquals("deep-zen", serviceEffect.gongSoundId)
        }

        @Test
        fun `passes backgroundSoundVolume to StartForegroundService effect`() {
            // Given
            val state = TimerDisplayState.Initial.copy(selectedMinutes = 10)
            val customVolume = 0.5f
            val settings = defaultSettings.copy(
                backgroundSoundId = "forest",
                backgroundSoundVolume = customVolume
            )

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )

            // Then
            val serviceEffect = effects.filterIsInstance<TimerEffect.StartForegroundService>().first()
            assertEquals("forest", serviceEffect.soundId)
            assertEquals(customVolume, serviceEffect.soundVolume)
        }

        @Test
        fun `passes gongSoundId to PlayStartGong when preparation disabled`() {
            // Given
            val state = TimerDisplayState.Initial.copy(selectedMinutes = 10)
            val settings = defaultSettings.copy(
                preparationTimeEnabled = false,
                gongSoundId = "warm-zen"
            )

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )

            // Then
            val gongEffect = effects.filterIsInstance<TimerEffect.PlayStartGong>().first()
            assertEquals("warm-zen", gongEffect.gongSoundId)
        }

        @Test
        fun `skips preparation and goes directly to running when disabled`() {
            // Given
            val state = TimerDisplayState.Initial.copy(selectedMinutes = 10)
            val settings = defaultSettings.copy(preparationTimeEnabled = false)

            // When
            val (newState, _) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )

            // Then - Should go directly to Running, not Preparation
            assertEquals(TimerState.Running, newState.timerState)
            assertEquals(0, newState.remainingPreparationSeconds)
        }

        @Test
        fun `plays start gong immediately when preparation disabled`() {
            // Given
            val state = TimerDisplayState.Initial.copy(selectedMinutes = 10)
            val settings = defaultSettings.copy(preparationTimeEnabled = false)

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )

            // Then - PlayStartGong should be in effects (immediate, not after PreparationFinished)
            assertTrue(effects.any { it is TimerEffect.PlayStartGong })
        }
    }

    // MARK: - PausePressed Tests

    @Nested
    inner class PausePressed {
        @Test
        fun `transitions to paused and emits effects when running`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PausePressed,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Paused, newState.timerState)
            assertEquals(listOf(TimerEffect.PauseBackgroundAudio, TimerEffect.PauseTimer), effects)
        }

        @Test
        fun `does nothing when not running`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Idle)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PausePressed,
                    defaultSettings
                )

            // Then
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when paused`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Paused)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PausePressed,
                    defaultSettings
                )

            // Then
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when in countdown`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Preparation)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PausePressed,
                    defaultSettings
                )

            // Then - Cannot pause during countdown
            assertEquals(TimerState.Preparation, newState.timerState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when completed`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Completed)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PausePressed,
                    defaultSettings
                )

            // Then - Cannot pause completed timer
            assertEquals(TimerState.Completed, newState.timerState)
            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - ResumePressed Tests

    @Nested
    inner class ResumePressed {
        @Test
        fun `transitions to running and emits effects when paused`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Paused)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResumePressed,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Running, newState.timerState)
            assertEquals(
                listOf(TimerEffect.ResumeBackgroundAudio, TimerEffect.ResumeTimer),
                effects
            )
        }

        @Test
        fun `does nothing when running`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResumePressed,
                    defaultSettings
                )

            // Then - Already running
            assertEquals(TimerState.Running, newState.timerState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when idle`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Idle)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResumePressed,
                    defaultSettings
                )

            // Then - Cannot resume from idle
            assertEquals(TimerState.Idle, newState.timerState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when in countdown`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Preparation)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResumePressed,
                    defaultSettings
                )

            // Then - Cannot resume during countdown
            assertEquals(TimerState.Preparation, newState.timerState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when completed`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Completed)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResumePressed,
                    defaultSettings
                )

            // Then - Cannot resume completed timer
            assertEquals(TimerState.Completed, newState.timerState)
            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - ResetPressed Tests

    @Nested
    inner class ResetPressed {
        @Test
        fun `resets state and emits effects when not idle`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    timerState = TimerState.Running,
                    remainingSeconds = 300,
                    totalSeconds = 600,
                    remainingPreparationSeconds = 0,
                    progress = 0.5f,
                    intervalGongPlayedForCurrentInterval = true
                )

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResetPressed,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Idle, newState.timerState)
            assertEquals(0, newState.remainingSeconds)
            assertEquals(0, newState.totalSeconds)
            assertEquals(0, newState.remainingPreparationSeconds)
            assertEquals(0f, newState.progress)
            assertFalse(newState.intervalGongPlayedForCurrentInterval)

            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
        }

        @Test
        fun `does nothing when idle`() {
            // Given
            val state = TimerDisplayState.Initial

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResetPressed,
                    defaultSettings
                )

            // Then
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `can reset from completed state`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Completed)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResetPressed,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Idle, newState.timerState)
            assertFalse(effects.isEmpty())
        }

        @Test
        fun `can reset from paused state`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Paused)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResetPressed,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Idle, newState.timerState)
            assertFalse(effects.isEmpty())
        }
    }

    // MARK: - Tick Tests

    @Nested
    inner class Tick {
        @Test
        fun `updates state from tick values`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Preparation)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.Tick(
                        remainingSeconds = 540,
                        totalSeconds = 600,
                        remainingPreparationSeconds = 10,
                        progress = 0.1f,
                        state = TimerState.Preparation
                    ),
                    defaultSettings
                )

            // Then
            assertEquals(540, newState.remainingSeconds)
            assertEquals(600, newState.totalSeconds)
            assertEquals(10, newState.remainingPreparationSeconds)
            assertEquals(0.1f, newState.progress)
            assertEquals(TimerState.Preparation, newState.timerState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `tick does not emit effects`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.Tick(
                        remainingSeconds = 100,
                        totalSeconds = 600,
                        remainingPreparationSeconds = 0,
                        progress = 0.83f,
                        state = TimerState.Running
                    ),
                    defaultSettings
                )

            // Then
            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - PreparationFinished Tests

    @Nested
    inner class PreparationFinished {
        @Test
        fun `transitions to running and plays start gong`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Preparation)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PreparationFinished,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Running, newState.timerState)
            assertEquals(1, effects.size)
            assertTrue(effects[0] is TimerEffect.PlayStartGong)
        }

        @Test
        fun `passes gongSoundId to PlayStartGong effect`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Preparation)
            val settings = defaultSettings.copy(gongSoundId = "clear-strike")

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PreparationFinished,
                    settings
                )

            // Then
            val gongEffect = effects.filterIsInstance<TimerEffect.PlayStartGong>().first()
            assertEquals("clear-strike", gongEffect.gongSoundId)
        }
    }

    // MARK: - TimerCompleted Tests

    @Nested
    inner class TimerCompleted {
        @Test
        fun `transitions to completed and plays completion sound`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    timerState = TimerState.Running,
                    progress = 0.99f
                )

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.TimerCompleted,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Completed, newState.timerState)
            assertEquals(1.0f, newState.progress)
            assertTrue(effects.any { it is TimerEffect.PlayCompletionSound })
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `passes gongSoundId to PlayCompletionSound effect`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)
            val settings = defaultSettings.copy(gongSoundId = "deep-resonance")

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.TimerCompleted,
                    settings
                )

            // Then
            val completionEffect = effects.filterIsInstance<TimerEffect.PlayCompletionSound>().first()
            assertEquals("deep-resonance", completionEffect.gongSoundId)
        }
    }

    // MARK: - IntervalGongTriggered Tests

    @Nested
    inner class IntervalGongTriggered {
        @Test
        fun `plays interval gong when enabled and not yet played`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    timerState = TimerState.Running,
                    intervalGongPlayedForCurrentInterval = false
                )
            val settings = defaultSettings.copy(intervalGongsEnabled = true)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.IntervalGongTriggered,
                    settings
                )

            // Then
            assertTrue(newState.intervalGongPlayedForCurrentInterval)
            assertTrue(effects.any { it is TimerEffect.PlayIntervalGong })
            val intervalEffect = effects.filterIsInstance<TimerEffect.PlayIntervalGong>().first()
            assertEquals(settings.intervalGongVolume, intervalEffect.gongVolume)
        }

        @Test
        fun `does nothing when interval gongs disabled`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    timerState = TimerState.Running,
                    intervalGongPlayedForCurrentInterval = false
                )
            val settings = defaultSettings.copy(intervalGongsEnabled = false)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.IntervalGongTriggered,
                    settings
                )

            // Then
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when already played for current interval`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    timerState = TimerState.Running,
                    intervalGongPlayedForCurrentInterval = true
                )
            val settings = defaultSettings.copy(intervalGongsEnabled = true)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.IntervalGongTriggered,
                    settings
                )

            // Then
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - IntervalGongPlayed Tests

    @Nested
    inner class IntervalGongPlayed {
        @Test
        fun `resets intervalGongPlayedForCurrentInterval`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    intervalGongPlayedForCurrentInterval = true
                )

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.IntervalGongPlayed,
                    defaultSettings
                )

            // Then
            assertFalse(newState.intervalGongPlayedForCurrentInterval)
            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - Integration Tests

    @Nested
    inner class Integration {
        @Test
        fun `full meditation cycle produces correct state transitions`() {
            // Given - Start in idle
            var state = TimerDisplayState.Initial.copy(selectedMinutes = 1)
            val settings = defaultSettings

            // When - Start
            val (startState, startEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )
            state = startState

            // Then - Should transition to Countdown and have start effects
            assertEquals(TimerState.Preparation, state.timerState)
            assertEquals(15, state.remainingPreparationSeconds)
            assertTrue(startEffects.any { it is TimerEffect.StartTimer })
            assertTrue(startEffects.any { it is TimerEffect.StartForegroundService })

            // When - Countdown tick
            val (countdownState, _) =
                TimerReducer.reduce(
                    state,
                    TimerAction.Tick(60, 60, 10, 0f, TimerState.Preparation),
                    settings
                )
            state = countdownState
            assertEquals(TimerState.Preparation, state.timerState)

            // When - Countdown finished
            val (runningState, runningEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PreparationFinished,
                    settings
                )
            state = runningState

            // Then
            assertEquals(TimerState.Running, state.timerState)
            assertTrue(runningEffects.any { it is TimerEffect.PlayStartGong })

            // When - Timer completed
            val (completedState, completedEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.TimerCompleted,
                    settings
                )
            state = completedState

            // Then
            assertEquals(TimerState.Completed, state.timerState)
            assertTrue(completedEffects.any { it is TimerEffect.PlayCompletionSound })

            // When - Reset
            val (resetState, resetEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResetPressed,
                    settings
                )

            // Then
            assertEquals(TimerState.Idle, resetState.timerState)
            assertTrue(resetEffects.contains(TimerEffect.ResetTimer))
        }

        @Test
        fun `pause and resume cycle with background audio effects`() {
            // Given
            var state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)
            val settings = defaultSettings

            // When - Pause
            val (pausedState, pauseEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PausePressed,
                    settings
                )

            // Then - State transitions to Paused, both audio pause and timer pause effects
            assertEquals(TimerState.Paused, pausedState.timerState)
            assertTrue(pauseEffects.contains(TimerEffect.PauseBackgroundAudio))
            assertTrue(pauseEffects.contains(TimerEffect.PauseTimer))

            state = pausedState

            // When - Resume
            val (_, resumeEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResumePressed,
                    settings
                )

            // Then - Both audio resume and timer resume effects
            assertTrue(resumeEffects.contains(TimerEffect.ResumeBackgroundAudio))
            assertTrue(resumeEffects.contains(TimerEffect.ResumeTimer))
        }

        @Test
        fun `full cycle without preparation time skips directly to running`() {
            // Given - Start in idle with preparation disabled
            var state = TimerDisplayState.Initial.copy(selectedMinutes = 1)
            val settings = defaultSettings.copy(preparationTimeEnabled = false)

            // When - Start
            val (startState, startEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )
            state = startState

            // Then - Should go directly to Running, not Preparation
            assertEquals(TimerState.Running, state.timerState)
            assertEquals(0, state.remainingPreparationSeconds)
            assertTrue(startEffects.any { it is TimerEffect.PlayStartGong })
            assertTrue(startEffects.any { it is TimerEffect.StartTimer })

            // When - Timer completed (no PreparationFinished needed)
            val (completedState, completedEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.TimerCompleted,
                    settings
                )

            // Then
            assertEquals(TimerState.Completed, completedState.timerState)
            assertTrue(completedEffects.any { it is TimerEffect.PlayCompletionSound })
        }
    }
}
