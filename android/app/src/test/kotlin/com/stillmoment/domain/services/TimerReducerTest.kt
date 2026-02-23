package com.stillmoment.domain.services

import com.stillmoment.domain.models.Introduction
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

        @Test
        fun `clamps duration to introduction minimum when introduction active`() {
            // Given — breath introduction requires minimum 3 minutes
            Introduction.languageOverride = "de"
            try {
                val state = TimerDisplayState.Initial
                val settings = defaultSettings.copy(introductionId = "breath")

                // When — select 1 minute (below minimum of 3)
                val (newState, _) =
                    TimerReducer.reduce(
                        state,
                        TimerAction.SelectDuration(1),
                        settings
                    )

                // Then — clamped to 3
                assertEquals(3, newState.selectedMinutes)
            } finally {
                Introduction.languageOverride = null
            }
        }

        @Test
        fun `preserves valid duration with introduction active`() {
            // Given
            Introduction.languageOverride = "de"
            try {
                val state = TimerDisplayState.Initial
                val settings = defaultSettings.copy(introductionId = "breath")

                // When — select 10 minutes (above minimum of 3)
                val (newState, _) =
                    TimerReducer.reduce(
                        state,
                        TimerAction.SelectDuration(10),
                        settings
                    )

                // Then — preserved
                assertEquals(10, newState.selectedMinutes)
            } finally {
                Introduction.languageOverride = null
            }
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
            assertEquals(1, newState.currentAffirmationIndex) // Rotated from 0

            // Verify effects — foreground service always starts with "silent" (background audio starts later)
            assertTrue(effects.any { it is TimerEffect.StartForegroundService && it.soundId == "silent" })
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

            // Then — foreground service always starts with "silent", volume is still passed
            val serviceEffect = effects.filterIsInstance<TimerEffect.StartForegroundService>().first()
            assertEquals("silent", serviceEffect.soundId)
            assertEquals(customVolume, serviceEffect.soundVolume)
        }

        @Test
        fun `skips preparation and goes directly to start gong when disabled`() {
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

            // Then - Should go directly to StartGong (gong plays immediately), not Preparation
            assertEquals(TimerState.StartGong, newState.timerState)
            assertEquals(0, newState.remainingPreparationSeconds)
        }

        @Test
        fun `does not play start gong directly when preparation disabled`() {
            // Given - Preparation disabled: gong arrives via PreparationCompleted event
            // from start(), not directly from StartPressed. This prevents double-gong.
            val state = TimerDisplayState.Initial.copy(selectedMinutes = 10)
            val settings = defaultSettings.copy(preparationTimeEnabled = false)

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartPressed,
                    settings
                )

            // Then - No PlayStartGong here; gong plays via PreparationFinished (see PreparationFinished tests)
            assertFalse(effects.any { it is TimerEffect.PlayStartGong })
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
                    progress = 0.5f
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
        fun `does not stop introduction when resetting from StartGong`() {
            // Given — still in StartGong, introduction not yet started
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.StartGong)

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResetPressed,
                    defaultSettings
                )

            // Then — no StopIntroduction since we never entered Introduction
            assertFalse(effects.any { it is TimerEffect.StopIntroduction })
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
        }

        @Test
        fun `stops introduction when resetting during introduction`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Introduction)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.ResetPressed,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Idle, newState.timerState)
            assertTrue(effects.any { it is TimerEffect.StopIntroduction })
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
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
        fun `transitions to start gong and plays start gong`() {
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
            assertEquals(TimerState.StartGong, newState.timerState)
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

    // MARK: - StartGongFinished Tests

    @Nested
    inner class StartGongFinished {
        @Test
        fun `transitions to running without introduction`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.StartGong)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartGongFinished,
                    defaultSettings
                )

            // Then — no introduction configured, go directly to Running
            assertEquals(TimerState.Running, newState.timerState)
            assertTrue(effects.any { it is TimerEffect.StartBackgroundAudio })
        }

        @Test
        fun `transitions to introduction when configured`() {
            // Given
            Introduction.languageOverride = "de"
            try {
                val state = TimerDisplayState.Initial.copy(timerState = TimerState.StartGong)
                val settings = defaultSettings.copy(introductionId = "breath")

                // When
                val (newState, effects) =
                    TimerReducer.reduce(
                        state,
                        TimerAction.StartGongFinished,
                        settings
                    )

                // Then
                assertEquals(TimerState.Introduction, newState.timerState)
                assertTrue(effects.any { it is TimerEffect.StartIntroductionPhase })
                assertTrue(effects.any { it is TimerEffect.PlayIntroduction })
                val introEffect = effects.filterIsInstance<TimerEffect.PlayIntroduction>().first()
                assertEquals("breath", introEffect.introductionId)
            } finally {
                Introduction.languageOverride = null
            }
        }

        @Test
        fun `does nothing when not in StartGong state`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartGongFinished,
                    defaultSettings
                )

            // Then
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `starts background audio when no introduction`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.StartGong)
            val settings = defaultSettings.copy(
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.5f
            )

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartGongFinished,
                    settings
                )

            // Then
            val audioEffect = effects.filterIsInstance<TimerEffect.StartBackgroundAudio>().first()
            assertEquals("forest", audioEffect.soundId)
            assertEquals(0.5f, audioEffect.soundVolume)
        }
    }

    // MARK: - IntroductionFinished Tests

    @Nested
    inner class IntroductionFinished {
        @Test
        fun `transitions to running and starts background audio`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Introduction)
            val settings = defaultSettings.copy(
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.3f
            )

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.IntroductionFinished,
                    settings
                )

            // Then
            assertEquals(TimerState.Running, newState.timerState)
            assertTrue(effects.any { it is TimerEffect.StopIntroduction })
            assertTrue(effects.any { it is TimerEffect.EndIntroductionPhase })
            assertTrue(effects.any { it is TimerEffect.StartBackgroundAudio })
        }

        @Test
        fun `does nothing when not in Introduction state`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.IntroductionFinished,
                    defaultSettings
                )

            // Then
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - TimerCompleted Tests

    @Nested
    inner class TimerCompleted {
        @Test
        fun `transitions to endGong and plays completion sound`() {
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

            // Then — enters endGong phase, NOT completed (gong must finish first)
            assertEquals(TimerState.EndGong, newState.timerState)
            assertEquals(1.0f, newState.progress)
            assertTrue(effects.any { it is TimerEffect.PlayCompletionSound })
            // Foreground service stays active during endGong
            assertFalse(effects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `stops introduction when timer expires during introduction`() {
            // Given — timer is still in Introduction phase when it reaches zero
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Introduction)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.TimerCompleted,
                    defaultSettings
                )

            // Then — enters endGong, stops introduction, plays completion sound
            assertEquals(TimerState.EndGong, newState.timerState)
            assertTrue(effects.any { it is TimerEffect.StopIntroduction })
            assertTrue(effects.any { it is TimerEffect.PlayCompletionSound })
            // Foreground service stays active during endGong
            assertFalse(effects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `does not stop introduction when completing from Running`() {
            // Given — timer completes normally from Running (introduction already finished)
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.TimerCompleted,
                    defaultSettings
                )

            // Then — no StopIntroduction since we were in Running, not Introduction
            assertFalse(effects.any { it is TimerEffect.StopIntroduction })
            assertTrue(effects.any { it is TimerEffect.PlayCompletionSound })
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

    // MARK: - EndGongFinished Tests

    @Nested
    inner class EndGongFinished {
        @Test
        fun `transitions from endGong to completed and stops foreground service`() {
            // Given
            val state = TimerDisplayState.Initial.copy(
                timerState = TimerState.EndGong,
                progress = 1.0f
            )

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.EndGongFinished,
                    defaultSettings
                )

            // Then
            assertEquals(TimerState.Completed, newState.timerState)
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `does nothing when not in endGong state`() {
            // Given — in Running, not EndGong
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Running)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.EndGongFinished,
                    defaultSettings
                )

            // Then — no-op
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when already completed`() {
            // Given
            val state = TimerDisplayState.Initial.copy(timerState = TimerState.Completed)

            // When
            val (newState, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.EndGongFinished,
                    defaultSettings
                )

            // Then — no-op
            assertEquals(state, newState)
            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - Reset from EndGong Tests

    @Nested
    inner class ResetFromEndGong {
        @Test
        fun `reset from endGong returns to idle`() {
            // Given
            val state = TimerDisplayState.Initial.copy(
                timerState = TimerState.EndGong,
                progress = 1.0f
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
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
        }
    }

    // MARK: - IntervalGongTriggered Tests

    @Nested
    inner class IntervalGongTriggered {
        @Test
        fun `plays interval gong when enabled`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    timerState = TimerState.Running
                )
            val settings = defaultSettings.copy(intervalGongsEnabled = true)

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.IntervalGongTriggered,
                    settings
                )

            // Then
            assertTrue(effects.any { it is TimerEffect.PlayIntervalGong })
            val intervalEffect = effects.filterIsInstance<TimerEffect.PlayIntervalGong>().first()
            assertEquals(settings.intervalGongVolume, intervalEffect.gongVolume)
        }

        @Test
        fun `passes intervalSoundId to PlayIntervalGong effect`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    timerState = TimerState.Running
                )
            val settings = defaultSettings.copy(
                intervalGongsEnabled = true,
                intervalSoundId = "soft-interval"
            )

            // When
            val (_, effects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.IntervalGongTriggered,
                    settings
                )

            // Then
            val intervalEffect = effects.filterIsInstance<TimerEffect.PlayIntervalGong>().first()
            assertEquals("soft-interval", intervalEffect.gongSoundId)
        }

        @Test
        fun `does nothing when interval gongs disabled`() {
            // Given
            val state =
                TimerDisplayState.Initial.copy(
                    timerState = TimerState.Running
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
    }

    // MARK: - Integration Tests

    @Nested
    @Suppress("LongMethod") // Integration tests trace complete state machine flows
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

            // Then - Should transition to Preparation and have start effects
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

            // When - Preparation finished → StartGong
            val (startGongState, startGongEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PreparationFinished,
                    settings
                )
            state = startGongState
            assertEquals(TimerState.StartGong, state.timerState)
            assertTrue(startGongEffects.any { it is TimerEffect.PlayStartGong })

            // When - Start gong finished → Running (no introduction)
            val (runningState, runningEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartGongFinished,
                    settings
                )
            state = runningState
            assertEquals(TimerState.Running, state.timerState)
            assertTrue(runningEffects.any { it is TimerEffect.StartBackgroundAudio })

            // When - Timer completed → EndGong (gong plays)
            val (endGongState, endGongEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.TimerCompleted,
                    settings
                )
            state = endGongState

            // Then — endGong phase, not completed yet
            assertEquals(TimerState.EndGong, state.timerState)
            assertTrue(endGongEffects.any { it is TimerEffect.PlayCompletionSound })
            assertFalse(endGongEffects.contains(TimerEffect.StopForegroundService))

            // When - End gong finished → Completed
            val (completedState, completedEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.EndGongFinished,
                    settings
                )
            state = completedState

            // Then
            assertEquals(TimerState.Completed, state.timerState)
            assertTrue(completedEffects.contains(TimerEffect.StopForegroundService))

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
        fun `full cycle without preparation time skips directly to start gong`() {
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

            // Then - Should go directly to StartGong, no PlayStartGong yet
            assertEquals(TimerState.StartGong, state.timerState)
            assertEquals(0, state.remainingPreparationSeconds)
            assertFalse(startEffects.any { it is TimerEffect.PlayStartGong })
            assertTrue(startEffects.any { it is TimerEffect.StartTimer })

            // When - PreparationCompleted event from start() → PreparationFinished → plays gong
            val (afterPrepState, afterPrepEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.PreparationFinished,
                    settings
                )
            state = afterPrepState
            assertEquals(TimerState.StartGong, state.timerState)
            assertTrue(afterPrepEffects.any { it is TimerEffect.PlayStartGong })

            // When - Start gong finished → Running
            val (runningState, _) =
                TimerReducer.reduce(
                    state,
                    TimerAction.StartGongFinished,
                    settings
                )
            state = runningState
            assertEquals(TimerState.Running, state.timerState)

            // When - Timer completed → EndGong
            val (endGongState, endGongEffects) =
                TimerReducer.reduce(
                    state,
                    TimerAction.TimerCompleted,
                    settings
                )

            // Then — endGong, not completed
            assertEquals(TimerState.EndGong, endGongState.timerState)
            assertTrue(endGongEffects.any { it is TimerEffect.PlayCompletionSound })

            // When - End gong finished → Completed
            val (completedState, completedEffects) =
                TimerReducer.reduce(
                    endGongState,
                    TimerAction.EndGongFinished,
                    settings
                )

            // Then
            assertEquals(TimerState.Completed, completedState.timerState)
            assertTrue(completedEffects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `full cycle with introduction`() {
            Introduction.languageOverride = "de"
            try {
                // Given - Start with introduction configured
                var state = TimerDisplayState.Initial.copy(selectedMinutes = 3)
                val settings = defaultSettings.copy(introductionId = "breath")

                // When - Start
                val (startState, _) =
                    TimerReducer.reduce(
                        state,
                        TimerAction.StartPressed,
                        settings
                    )
                state = startState
                assertEquals(TimerState.Preparation, state.timerState)

                // When - Preparation finished → StartGong
                val (startGongState, _) =
                    TimerReducer.reduce(
                        state,
                        TimerAction.PreparationFinished,
                        settings
                    )
                state = startGongState
                assertEquals(TimerState.StartGong, state.timerState)

                // When - Start gong finished → Introduction (because introduction is configured)
                val (introState, introEffects) =
                    TimerReducer.reduce(
                        state,
                        TimerAction.StartGongFinished,
                        settings
                    )
                state = introState
                assertEquals(TimerState.Introduction, state.timerState)
                assertTrue(introEffects.any { it is TimerEffect.StartIntroductionPhase })
                assertTrue(introEffects.any { it is TimerEffect.PlayIntroduction })

                // When - Introduction finished → Running
                val (runningState, runningEffects) =
                    TimerReducer.reduce(
                        state,
                        TimerAction.IntroductionFinished,
                        settings
                    )
                state = runningState
                assertEquals(TimerState.Running, state.timerState)
                assertTrue(runningEffects.any { it is TimerEffect.StopIntroduction })
                assertTrue(runningEffects.any { it is TimerEffect.EndIntroductionPhase })
                assertTrue(runningEffects.any { it is TimerEffect.StartBackgroundAudio })

                // When - Timer completed → EndGong
                val (endGongState, endGongEffects) =
                    TimerReducer.reduce(
                        state,
                        TimerAction.TimerCompleted,
                        settings
                    )
                assertEquals(TimerState.EndGong, endGongState.timerState)
                assertTrue(endGongEffects.any { it is TimerEffect.PlayCompletionSound })

                // When - End gong finished → Completed
                val (completedState, completedEffects) =
                    TimerReducer.reduce(
                        endGongState,
                        TimerAction.EndGongFinished,
                        settings
                    )
                assertEquals(TimerState.Completed, completedState.timerState)
                assertTrue(completedEffects.contains(TimerEffect.StopForegroundService))
            } finally {
                Introduction.languageOverride = null
            }
        }
    }
}
