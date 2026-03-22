package com.stillmoment.domain.services

import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.ResolvedAttunement
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerState
import com.stillmoment.testutil.MockAttunementResolver
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for TimerReducer.
 *
 * Tests verify that the reducer is a pure effect mapper:
 * - Same inputs always produce same outputs
 * - No side effects (all I/O represented as TimerEffect)
 * - No state mutations (returns only List<TimerEffect>)
 * - Uses MockAttunementResolver for attunement resolution
 */
class TimerReducerTest {
    private val defaultSettings = MeditationSettings.Default
    private val emptyResolver = MockAttunementResolver()
    private val breathResolver = MockAttunementResolver(
        resolveResult = mapOf(
            "breath" to ResolvedAttunement(
                id = "breath",
                displayName = "Breathing Exercise",
                durationSeconds = 95
            )
        )
    )

    // MARK: - StartPressed Tests

    @Nested
    inner class StartPressed {
        @Test
        fun `returns start effects when valid duration`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 15,
                settings = defaultSettings.copy(backgroundSoundId = "forest"),
                attunementResolver = emptyResolver
            )

            // Verify effects - foreground service always starts with "silent"
            assertTrue(effects.any { it is TimerEffect.StartForegroundService && it.soundId == "silent" })
            assertTrue(effects.any { it is TimerEffect.StartTimer })
            assertTrue(effects.any { it is TimerEffect.SaveSettings })
        }

        @Test
        fun `returns empty effects when selectedMinutes is zero`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 0,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.isEmpty())
        }

        @Test
        fun `passes gongSoundId to StartForegroundService effect`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 10,
                settings = defaultSettings.copy(gongSoundId = "deep-zen"),
                attunementResolver = emptyResolver
            )

            val serviceEffect = effects.filterIsInstance<TimerEffect.StartForegroundService>().first()
            assertEquals("deep-zen", serviceEffect.gongSoundId)
        }

        @Test
        fun `passes backgroundSoundVolume to StartForegroundService effect`() {
            val customVolume = 0.5f
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 10,
                settings = defaultSettings.copy(
                    backgroundSoundId = "forest",
                    backgroundSoundVolume = customVolume
                ),
                attunementResolver = emptyResolver
            )

            // Foreground service always starts with "silent", volume is still passed
            val serviceEffect = effects.filterIsInstance<TimerEffect.StartForegroundService>().first()
            assertEquals("silent", serviceEffect.soundId)
            assertEquals(customVolume, serviceEffect.soundVolume)
        }

        @Test
        fun `passes preparation time from settings`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            val startTimer = effects.filterIsInstance<TimerEffect.StartTimer>().first()
            assertEquals(defaultSettings.preparationTimeSeconds, startTimer.preparationTimeSeconds)
        }

        @Test
        fun `passes zero preparation time when disabled`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 10,
                settings = defaultSettings.copy(preparationTimeEnabled = false),
                attunementResolver = emptyResolver
            )

            val startTimer = effects.filterIsInstance<TimerEffect.StartTimer>().first()
            assertEquals(0, startTimer.preparationTimeSeconds)
        }

        @Test
        fun `does not play start gong directly`() {
            // Start gong is played via PreparationFinished, not directly from StartPressed
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 10,
                settings = defaultSettings.copy(preparationTimeEnabled = false),
                attunementResolver = emptyResolver
            )

            assertFalse(effects.any { it is TimerEffect.PlayStartGong })
        }

        @Test
        fun `saves updated settings with selected duration`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 20,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            val saveEffect = effects.filterIsInstance<TimerEffect.SaveSettings>().first()
            assertEquals(20, saveEffect.settings.durationMinutes)
        }
    }

    // MARK: - ResetPressed Tests

    @Nested
    inner class ResetPressed {
        @Test
        fun `returns reset effects when not idle`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.ResetPressed,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
        }

        @Test
        fun `returns empty effects when idle`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.ResetPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.isEmpty())
        }

        @Test
        fun `can reset from completed state`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.ResetPressed,
                timerState = TimerState.Completed,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertFalse(effects.isEmpty())
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
        }

        @Test
        fun `does not stop attunement when resetting from StartGong`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.ResetPressed,
                timerState = TimerState.StartGong,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            // No StopAttunement since we never entered Attunement
            assertFalse(effects.any { it is TimerEffect.StopAttunement })
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
        }

        @Test
        fun `stops attunement when resetting during attunement`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.ResetPressed,
                timerState = TimerState.Attunement,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.any { it is TimerEffect.StopAttunement })
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
        }
    }

    // MARK: - PreparationFinished Tests

    @Nested
    inner class PreparationFinished {
        @Test
        fun `plays start gong`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.PreparationFinished,
                timerState = TimerState.Preparation,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertEquals(1, effects.size)
            assertTrue(effects[0] is TimerEffect.PlayStartGong)
        }

        @Test
        fun `passes gongSoundId to PlayStartGong effect`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.PreparationFinished,
                timerState = TimerState.Preparation,
                selectedMinutes = 10,
                settings = defaultSettings.copy(gongSoundId = "clear-strike"),
                attunementResolver = emptyResolver
            )

            val gongEffect = effects.filterIsInstance<TimerEffect.PlayStartGong>().first()
            assertEquals("clear-strike", gongEffect.gongSoundId)
        }
    }

    // MARK: - StartGongFinished Tests

    @Nested
    inner class StartGongFinished {
        @Test
        fun `transitions to running without attunement`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            // No attunement configured -> TransitionToRunning + StartBackgroundAudio
            assertTrue(effects.any { it is TimerEffect.TransitionToRunning })
            assertTrue(effects.any { it is TimerEffect.StartBackgroundAudio })
        }

        @Test
        fun `transitions to attunement when configured`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 10,
                settings = defaultSettings.copy(attunementId = "breath", attunementEnabled = true),
                attunementResolver = breathResolver
            )

            assertTrue(effects.any { it is TimerEffect.StartAttunementPhase })
            assertTrue(effects.any { it is TimerEffect.PlayAttunement })
            val introEffect = effects.filterIsInstance<TimerEffect.PlayAttunement>().first()
            assertEquals("breath", introEffect.attunementId)
            // No TransitionToRunning when attunement is configured
            assertFalse(effects.any { it is TimerEffect.TransitionToRunning })
        }

        @Test
        fun `transitions to running when attunementEnabled is false despite valid attunementId`() {
            // Given - settings with valid attunementId but attunementEnabled = false
            val settings = defaultSettings.copy(
                attunementEnabled = false,
                attunementId = "breath"
            )

            // When - StartGong finished
            val effects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 5,
                settings = settings,
                attunementResolver = breathResolver
            )

            // Then - should transition to running (no attunement phase)
            assertTrue(effects.any { it is TimerEffect.TransitionToRunning })
            assertTrue(effects.any { it is TimerEffect.StartBackgroundAudio })
            assertFalse(effects.any { it is TimerEffect.StartAttunementPhase })
            assertFalse(effects.any { it is TimerEffect.PlayAttunement })
        }

        @Test
        fun `does nothing when not in StartGong state`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.isEmpty())
        }

        @Test
        fun `starts background audio when no attunement`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 10,
                settings = defaultSettings.copy(
                    backgroundSoundId = "forest",
                    backgroundSoundVolume = 0.5f
                ),
                attunementResolver = emptyResolver
            )

            val audioEffect = effects.filterIsInstance<TimerEffect.StartBackgroundAudio>().first()
            assertEquals("forest", audioEffect.soundId)
            assertEquals(0.5f, audioEffect.soundVolume)
        }
    }

    // MARK: - AttunementFinished Tests

    @Nested
    inner class AttunementFinished {
        @Test
        fun `stops attunement and starts background audio`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.AttunementFinished,
                timerState = TimerState.Attunement,
                selectedMinutes = 10,
                settings = defaultSettings.copy(
                    backgroundSoundId = "forest",
                    backgroundSoundVolume = 0.3f
                ),
                attunementResolver = emptyResolver
            )

            assertTrue(effects.any { it is TimerEffect.StopAttunement })
            assertTrue(effects.any { it is TimerEffect.EndAttunementPhase })
            assertTrue(effects.any { it is TimerEffect.StartBackgroundAudio })
        }

        @Test
        fun `does nothing when not in Attunement state`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.AttunementFinished,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - TimerCompleted Tests

    @Nested
    inner class TimerCompleted {
        @Test
        fun `plays completion sound`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.TimerCompleted,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.any { it is TimerEffect.PlayCompletionSound })
            // Foreground service stays active during endGong
            assertFalse(effects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `stops attunement when timer expires during attunement`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.TimerCompleted,
                timerState = TimerState.Attunement,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.any { it is TimerEffect.StopAttunement })
            assertTrue(effects.any { it is TimerEffect.PlayCompletionSound })
            // Foreground service stays active during endGong
            assertFalse(effects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `does not stop attunement when completing from Running`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.TimerCompleted,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            // No StopAttunement since we were in Running, not Attunement
            assertFalse(effects.any { it is TimerEffect.StopAttunement })
            assertTrue(effects.any { it is TimerEffect.PlayCompletionSound })
        }

        @Test
        fun `passes gongSoundId to PlayCompletionSound effect`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.TimerCompleted,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings.copy(gongSoundId = "deep-resonance"),
                attunementResolver = emptyResolver
            )

            val completionEffect = effects.filterIsInstance<TimerEffect.PlayCompletionSound>().first()
            assertEquals("deep-resonance", completionEffect.gongSoundId)
        }
    }

    // MARK: - EndGongFinished Tests

    @Nested
    inner class EndGongFinished {
        @Test
        fun `transitions to completed and stops foreground service`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.EndGongFinished,
                timerState = TimerState.EndGong,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.any { it is TimerEffect.TransitionToCompleted })
            assertTrue(effects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `does nothing when not in endGong state`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.EndGongFinished,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does nothing when already completed`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.EndGongFinished,
                timerState = TimerState.Completed,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.isEmpty())
        }

        @Test
        fun `does not produce reset timer on completion`() {
            // android-068: completion must not auto-navigate — ResetTimer is the event
            // that would cause timer=null -> Idle -> LaunchedEffect navigates back
            val effects = TimerReducer.reduce(
                action = TimerAction.EndGongFinished,
                timerState = TimerState.EndGong,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertFalse(effects.contains(TimerEffect.ResetTimer))
            assertTrue(effects.any { it is TimerEffect.TransitionToCompleted })
        }
    }

    // MARK: - Reset from EndGong Tests

    @Nested
    inner class ResetFromEndGong {
        @Test
        fun `reset from endGong returns reset effects`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.ResetPressed,
                timerState = TimerState.EndGong,
                selectedMinutes = 10,
                settings = defaultSettings,
                attunementResolver = emptyResolver
            )

            assertTrue(effects.contains(TimerEffect.StopForegroundService))
            assertTrue(effects.contains(TimerEffect.ResetTimer))
        }
    }

    // MARK: - IntervalGongTriggered Tests

    @Nested
    inner class IntervalGongTriggered {
        @Test
        fun `plays interval gong when enabled`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.IntervalGongTriggered,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings.copy(intervalGongsEnabled = true),
                attunementResolver = emptyResolver
            )

            assertTrue(effects.any { it is TimerEffect.PlayIntervalGong })
            val intervalEffect = effects.filterIsInstance<TimerEffect.PlayIntervalGong>().first()
            assertEquals(defaultSettings.intervalGongVolume, intervalEffect.gongVolume)
        }

        @Test
        fun `passes intervalSoundId to PlayIntervalGong effect`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.IntervalGongTriggered,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings.copy(
                    intervalGongsEnabled = true,
                    intervalSoundId = "soft-interval"
                ),
                attunementResolver = emptyResolver
            )

            val intervalEffect = effects.filterIsInstance<TimerEffect.PlayIntervalGong>().first()
            assertEquals("soft-interval", intervalEffect.gongSoundId)
        }

        @Test
        fun `does nothing when interval gongs disabled`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.IntervalGongTriggered,
                timerState = TimerState.Running,
                selectedMinutes = 10,
                settings = defaultSettings.copy(intervalGongsEnabled = false),
                attunementResolver = emptyResolver
            )

            assertTrue(effects.isEmpty())
        }
    }

    // MARK: - Custom Attunement Tests

    @Nested
    inner class CustomAttunement {
        private val customResolver = MockAttunementResolver(
            resolveResult = mapOf(
                "custom-uuid-123" to ResolvedAttunement(
                    id = "custom-uuid-123",
                    displayName = "Custom Meditation",
                    durationSeconds = 120
                )
            )
        )

        @Test
        fun `startPressed with custom attunement includes correct attunement duration`() {
            val settings = defaultSettings.copy(
                attunementEnabled = true,
                attunementId = "custom-uuid-123",
                customAttunementDurationSeconds = 120
            )
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 10,
                settings = settings,
                attunementResolver = customResolver
            )
            val startTimer = effects.filterIsInstance<TimerEffect.StartTimer>().first()
            assertEquals(120, startTimer.attunementDurationSeconds)
        }

        @Test
        fun `startGongFinished with custom attunement starts attunement phase`() {
            val settings = defaultSettings.copy(
                attunementEnabled = true,
                attunementId = "custom-uuid-123",
                customAttunementDurationSeconds = 120
            )
            val effects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 10,
                settings = settings,
                attunementResolver = customResolver
            )
            assertTrue(effects.any { it is TimerEffect.StartAttunementPhase })
            assertTrue(effects.any { it is TimerEffect.PlayAttunement })
            val introEffect = effects.filterIsInstance<TimerEffect.PlayAttunement>().first()
            assertEquals("custom-uuid-123", introEffect.attunementId)
        }

        @Test
        fun `startGongFinished with custom attunement does not start background audio`() {
            val settings = defaultSettings.copy(
                attunementEnabled = true,
                attunementId = "custom-uuid-123",
                customAttunementDurationSeconds = 120
            )
            val effects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 10,
                settings = settings,
                attunementResolver = customResolver
            )
            assertFalse(effects.any { it is TimerEffect.TransitionToRunning })
            assertFalse(effects.any { it is TimerEffect.StartBackgroundAudio })
        }
    }

    // MARK: - Integration Tests

    @Nested
    inner class Integration {
        @Test
        fun `full meditation cycle produces correct effects`() {
            val settings = defaultSettings

            // Start
            val startEffects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(startEffects.any { it is TimerEffect.StartTimer })
            assertTrue(startEffects.any { it is TimerEffect.StartForegroundService })

            // Preparation finished -> StartGong
            val prepEffects = TimerReducer.reduce(
                action = TimerAction.PreparationFinished,
                timerState = TimerState.Preparation,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(prepEffects.any { it is TimerEffect.PlayStartGong })

            // Start gong finished -> Running (no attunement)
            val gongEffects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(gongEffects.any { it is TimerEffect.TransitionToRunning })
            assertTrue(gongEffects.any { it is TimerEffect.StartBackgroundAudio })

            // Timer completed -> EndGong
            val completedEffects = TimerReducer.reduce(
                action = TimerAction.TimerCompleted,
                timerState = TimerState.Running,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(completedEffects.any { it is TimerEffect.PlayCompletionSound })
            assertFalse(completedEffects.contains(TimerEffect.StopForegroundService))

            // End gong finished -> Completed
            val endEffects = TimerReducer.reduce(
                action = TimerAction.EndGongFinished,
                timerState = TimerState.EndGong,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(endEffects.any { it is TimerEffect.TransitionToCompleted })
            assertTrue(endEffects.contains(TimerEffect.StopForegroundService))

            // Reset
            val resetEffects = TimerReducer.reduce(
                action = TimerAction.ResetPressed,
                timerState = TimerState.Completed,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(resetEffects.contains(TimerEffect.ResetTimer))
        }

        @Test
        fun `full cycle without preparation time`() {
            val settings = defaultSettings.copy(preparationTimeEnabled = false)

            // Start -> preparation time is 0
            val startEffects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(startEffects.any { it is TimerEffect.StartTimer })
            val startTimer = startEffects.filterIsInstance<TimerEffect.StartTimer>().first()
            assertEquals(0, startTimer.preparationTimeSeconds)
            assertFalse(startEffects.any { it is TimerEffect.PlayStartGong })

            // PreparationCompleted event from start() -> plays gong
            val prepEffects = TimerReducer.reduce(
                action = TimerAction.PreparationFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(prepEffects.any { it is TimerEffect.PlayStartGong })

            // Start gong finished -> Running
            val gongEffects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(gongEffects.any { it is TimerEffect.TransitionToRunning })

            // Timer completed -> EndGong
            val completedEffects = TimerReducer.reduce(
                action = TimerAction.TimerCompleted,
                timerState = TimerState.Running,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(completedEffects.any { it is TimerEffect.PlayCompletionSound })

            // End gong finished -> Completed
            val endEffects = TimerReducer.reduce(
                action = TimerAction.EndGongFinished,
                timerState = TimerState.EndGong,
                selectedMinutes = 1,
                settings = settings,
                attunementResolver = emptyResolver
            )
            assertTrue(endEffects.any { it is TimerEffect.TransitionToCompleted })
            assertTrue(endEffects.contains(TimerEffect.StopForegroundService))
        }

        @Test
        fun `full cycle with attunement`() {
            val settings = defaultSettings.copy(attunementId = "breath", attunementEnabled = true)

            // Start
            val startEffects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 3,
                settings = settings,
                attunementResolver = breathResolver
            )
            assertTrue(startEffects.any { it is TimerEffect.StartTimer })

            // Preparation finished -> StartGong
            val prepEffects = TimerReducer.reduce(
                action = TimerAction.PreparationFinished,
                timerState = TimerState.Preparation,
                selectedMinutes = 3,
                settings = settings,
                attunementResolver = breathResolver
            )
            assertTrue(prepEffects.any { it is TimerEffect.PlayStartGong })

            // Start gong finished -> Attunement (because attunement is configured)
            val gongEffects = TimerReducer.reduce(
                action = TimerAction.StartGongFinished,
                timerState = TimerState.StartGong,
                selectedMinutes = 3,
                settings = settings,
                attunementResolver = breathResolver
            )
            assertTrue(gongEffects.any { it is TimerEffect.StartAttunementPhase })
            assertTrue(gongEffects.any { it is TimerEffect.PlayAttunement })

            // Attunement finished -> Running
            val introEffects = TimerReducer.reduce(
                action = TimerAction.AttunementFinished,
                timerState = TimerState.Attunement,
                selectedMinutes = 3,
                settings = settings,
                attunementResolver = breathResolver
            )
            assertTrue(introEffects.any { it is TimerEffect.StopAttunement })
            assertTrue(introEffects.any { it is TimerEffect.EndAttunementPhase })
            assertTrue(introEffects.any { it is TimerEffect.StartBackgroundAudio })

            // Timer completed -> EndGong
            val completedEffects = TimerReducer.reduce(
                action = TimerAction.TimerCompleted,
                timerState = TimerState.Running,
                selectedMinutes = 3,
                settings = settings,
                attunementResolver = breathResolver
            )
            assertTrue(completedEffects.any { it is TimerEffect.PlayCompletionSound })

            // End gong finished -> Completed
            val endEffects = TimerReducer.reduce(
                action = TimerAction.EndGongFinished,
                timerState = TimerState.EndGong,
                selectedMinutes = 3,
                settings = settings,
                attunementResolver = breathResolver
            )
            assertTrue(endEffects.any { it is TimerEffect.TransitionToCompleted })
            assertTrue(endEffects.contains(TimerEffect.StopForegroundService))
        }
    }
}
