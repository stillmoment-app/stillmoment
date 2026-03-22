package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

/**
 * Unit tests for MeditationTimer domain model.
 */
class MeditationTimerTest {
    // MARK: - Creation Tests

    @Test
    fun `create timer with valid duration succeeds`() {
        // Given
        val duration = 10

        // When
        val timer = MeditationTimer.create(duration)

        // Then
        assertEquals(10, timer.durationMinutes)
        assertEquals(600, timer.remainingSeconds)
        assertEquals(TimerState.Idle, timer.state)
        assertEquals(0, timer.remainingPreparationSeconds)
        assertEquals(15, timer.preparationTimeSeconds)
        assertNull(timer.lastIntervalGongAt)
    }

    @Test
    fun `create timer with minimum duration (1 minute) succeeds`() {
        val timer = MeditationTimer.create(1)
        assertEquals(1, timer.durationMinutes)
        assertEquals(60, timer.remainingSeconds)
    }

    @Test
    fun `create timer with maximum duration (60 minutes) succeeds`() {
        val timer = MeditationTimer.create(60)
        assertEquals(60, timer.durationMinutes)
        assertEquals(3600, timer.remainingSeconds)
    }

    @Test
    fun `create timer with zero duration throws exception`() {
        assertThrows<IllegalArgumentException> {
            MeditationTimer.create(0)
        }
    }

    @Test
    fun `create timer with negative duration throws exception`() {
        assertThrows<IllegalArgumentException> {
            MeditationTimer.create(-5)
        }
    }

    @Test
    fun `create timer with duration over 60 throws exception`() {
        assertThrows<IllegalArgumentException> {
            MeditationTimer.create(61)
        }
    }

    @Test
    fun `create timer with custom countdown duration`() {
        val timer = MeditationTimer.create(10, preparationTimeSeconds = 5)
        assertEquals(5, timer.preparationTimeSeconds)
    }

    @Test
    fun `create timer with zero countdown duration (skip countdown)`() {
        val timer = MeditationTimer.create(10, preparationTimeSeconds = 0)
        assertEquals(0, timer.preparationTimeSeconds)
    }

    // MARK: - Computed Properties Tests

    @Test
    fun `totalSeconds returns duration in seconds`() {
        val timer = MeditationTimer.create(5)
        assertEquals(300, timer.totalSeconds)
    }

    @Test
    fun `progress is 0 at start`() {
        val timer = MeditationTimer.create(10)
        assertEquals(0.0f, timer.progress, 0.001f)
    }

    @Test
    fun `progress is 0_5 at halfway`() {
        val timer = MeditationTimer.create(10).copy(remainingSeconds = 300)
        assertEquals(0.5f, timer.progress, 0.001f)
    }

    @Test
    fun `progress is 1 when completed`() {
        val timer = MeditationTimer.create(10).copy(remainingSeconds = 0)
        assertEquals(1.0f, timer.progress, 0.001f)
    }

    @Test
    fun `isCompleted is false when remainingSeconds greater than 0`() {
        val timer = MeditationTimer.create(10)
        assertFalse(timer.isCompleted)
    }

    @Test
    fun `isCompleted is true when remainingSeconds is 0`() {
        val timer = MeditationTimer.create(10).copy(remainingSeconds = 0)
        assertTrue(timer.isCompleted)
    }

    // MARK: - Tick Tests

    @Test
    fun `tick during countdown decrements countdown seconds`() {
        // Given
        val timer = MeditationTimer.create(10).startPreparation()
        assertEquals(15, timer.remainingPreparationSeconds)

        // When
        val (ticked, _) = timer.tick()

        // Then
        assertEquals(14, ticked.remainingPreparationSeconds)
        assertEquals(TimerState.Preparation, ticked.state)
        assertEquals(600, ticked.remainingSeconds) // Timer hasn't started
    }

    @Test
    fun `tick transitions from countdown to start gong when countdown reaches 0`() {
        // Given
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Preparation, remainingPreparationSeconds = 1)

        // When
        val (ticked, _) = timer.tick()

        // Then
        assertEquals(0, ticked.remainingPreparationSeconds)
        assertEquals(TimerState.StartGong, ticked.state)
    }

    @Test
    fun `tick during running decrements remaining seconds`() {
        // Given
        val timer = MeditationTimer.create(10).copy(state = TimerState.Running)

        // When
        val (ticked, _) = timer.tick()

        // Then
        assertEquals(599, ticked.remainingSeconds)
        assertEquals(TimerState.Running, ticked.state)
    }

    @Test
    fun `tick transitions to endGong when remaining seconds reach 0`() {
        // Given
        val timer =
            MeditationTimer.create(1)
                .copy(state = TimerState.Running, remainingSeconds = 1)

        // When
        val (ticked, _) = timer.tick()

        // Then
        assertEquals(0, ticked.remainingSeconds)
        assertEquals(TimerState.EndGong, ticked.state)
    }

    @Test
    fun `tick does not go below 0 remaining seconds`() {
        // Given
        val timer =
            MeditationTimer.create(1)
                .copy(state = TimerState.Running, remainingSeconds = 0)

        // When
        val (ticked, _) = timer.tick()

        // Then
        assertEquals(0, ticked.remainingSeconds)
    }

    // MARK: - State Change Tests

    @Test
    fun `withState changes state`() {
        val timer = MeditationTimer.create(10)
        val running = timer.withState(TimerState.Running)
        assertEquals(TimerState.Running, running.state)
    }

    @Test
    fun `startPreparation sets countdown state and seconds`() {
        // Given
        val timer = MeditationTimer.create(10)

        // When
        val counting = timer.startPreparation()

        // Then
        assertEquals(TimerState.Preparation, counting.state)
        assertEquals(15, counting.remainingPreparationSeconds)
        assertNull(counting.lastIntervalGongAt)
    }

    @Test
    fun `reset returns timer to initial state`() {
        // Given
        val timer =
            MeditationTimer.create(10)
                .copy(
                    state = TimerState.Running,
                    remainingSeconds = 100,
                    remainingPreparationSeconds = 5,
                    lastIntervalGongAt = 300
                )

        // When
        val resetTimer = timer.reset()

        // Then
        assertEquals(TimerState.Idle, resetTimer.state)
        assertEquals(600, resetTimer.remainingSeconds)
        assertEquals(0, resetTimer.remainingPreparationSeconds)
        assertNull(resetTimer.lastIntervalGongAt)
        assertEquals(10, resetTimer.durationMinutes) // Preserved
    }

    // MARK: - Interval Gong Tests (General)

    @Test
    fun `shouldPlayIntervalGong returns false when not running`() {
        val timer = MeditationTimer.create(10).copy(state = TimerState.Idle)
        assertFalse(timer.shouldPlayIntervalGong(5))
    }

    @Test
    fun `shouldPlayIntervalGong returns false with zero interval`() {
        val timer = MeditationTimer.create(10).copy(state = TimerState.Running)
        assertFalse(timer.shouldPlayIntervalGong(0))
    }

    @Test
    fun `shouldPlayIntervalGong returns false when interval exceeds total duration`() {
        // Given: 5 min timer, 10 min interval -> no gong possible
        val timer = MeditationTimer.create(5).copy(state = TimerState.Running, remainingSeconds = 200)
        assertFalse(timer.shouldPlayIntervalGong(10))
    }

    @Test
    fun `shouldPlayIntervalGong returns false at 0 remaining seconds`() {
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Running, remainingSeconds = 0, lastIntervalGongAt = 300)
        assertFalse(timer.shouldPlayIntervalGong(5))
    }

    @Test
    fun `markIntervalGongPlayed records remaining seconds`() {
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Running, remainingSeconds = 300)
        val marked = timer.markIntervalGongPlayed()
        assertEquals(300, marked.lastIntervalGongAt)
    }

    @Test
    fun `shouldPlayIntervalGong returns false within 5 second end protection zone`() {
        // Given: 10 min timer, 4 seconds remaining -> inside 5s end protection
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 4)
        assertFalse(timer.shouldPlayIntervalGong(1, mode = IntervalMode.REPEATING))
    }

    // MARK: - REPEATING Mode

    @Test
    fun `repeating triggers at first interval`() {
        // Given: 10 min timer, 5 min elapsed (300s remaining)
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300)
        assertTrue(timer.shouldPlayIntervalGong(5, mode = IntervalMode.REPEATING))
    }

    @Test
    fun `repeating does not trigger before first interval`() {
        // Given: 10 min timer, 2 min elapsed (480s remaining)
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 480)
        assertFalse(timer.shouldPlayIntervalGong(5, mode = IntervalMode.REPEATING))
    }

    @Test
    fun `repeating respects lastIntervalGongAt`() {
        // Given: Already played at 300s remaining, still at 300s
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300, lastIntervalGongAt = 300)
        assertFalse(timer.shouldPlayIntervalGong(5, mode = IntervalMode.REPEATING))
    }

    @Test
    fun `repeating triggers on next interval after last gong`() {
        // Given: 15 min timer, 5 min interval, last gong at 600s remaining (5 min elapsed)
        // Now at 300s remaining (10 min elapsed) - should trigger again
        val timer = MeditationTimer.create(15)
            .copy(state = TimerState.Running, remainingSeconds = 300, lastIntervalGongAt = 600)
        assertTrue(timer.shouldPlayIntervalGong(5, mode = IntervalMode.REPEATING))
    }

    @Test
    fun `repeating with 1 minute interval on 3 minute timer`() {
        // Given: 3 min timer, 1 min interval, 1 min elapsed (120s remaining)
        val timer = MeditationTimer.create(3)
            .copy(state = TimerState.Running, remainingSeconds = 120)
        assertTrue(timer.shouldPlayIntervalGong(1, mode = IntervalMode.REPEATING))
    }

    // MARK: - BEFORE_END Mode

    @Test
    fun `before end triggers once at correct time`() {
        // Given: 10 min timer, 3 min interval (before end) -> plays at 3 min remaining = 180s
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 180)
        assertTrue(timer.shouldPlayIntervalGong(3, mode = IntervalMode.BEFORE_END))
    }

    @Test
    fun `before end does not trigger too early`() {
        // Given: 10 min timer, 3 min interval (before end) -> too early at 5 min remaining
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300)
        assertFalse(timer.shouldPlayIntervalGong(3, mode = IntervalMode.BEFORE_END))
    }

    @Test
    fun `before end does not trigger again after played`() {
        // Given: Already played at 180s
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 180, lastIntervalGongAt = 180)
        assertFalse(timer.shouldPlayIntervalGong(3, mode = IntervalMode.BEFORE_END))
    }

    @Test
    fun `before end does not trigger in end protection zone`() {
        // Given: 10 min timer, interval = 0 -> inside protection
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 3)
        assertFalse(timer.shouldPlayIntervalGong(0, mode = IntervalMode.BEFORE_END))
    }

    // MARK: - AFTER_START Mode

    @Test
    fun `after start triggers at interval from start`() {
        // Given: 10 min timer, 3 min interval (after start) -> plays at 3 min elapsed = 420s remaining
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 420)
        assertTrue(timer.shouldPlayIntervalGong(3, mode = IntervalMode.AFTER_START))
    }

    @Test
    fun `after start does not trigger before interval`() {
        // Given: 10 min timer, 3 min interval -> too early at 1 min elapsed
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 540)
        assertFalse(timer.shouldPlayIntervalGong(3, mode = IntervalMode.AFTER_START))
    }

    @Test
    fun `after start does not trigger again after played`() {
        // Given: Already played
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 420, lastIntervalGongAt = 420)
        assertFalse(timer.shouldPlayIntervalGong(3, mode = IntervalMode.AFTER_START))
    }

    @Test
    fun `after start triggers even late`() {
        // Given: 10 min timer, 3 min interval, now at 5 min elapsed -> should still trigger
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300)
        assertTrue(timer.shouldPlayIntervalGong(3, mode = IntervalMode.AFTER_START))
    }

    // MARK: - Edge Case Tests

    @Test
    fun `multiple ticks countdown correctly`() {
        // Given: 10 min timer with 3 sec countdown
        var timer = MeditationTimer.create(10, preparationTimeSeconds = 3).startPreparation()
        assertEquals(TimerState.Preparation, timer.state)
        assertEquals(3, timer.remainingPreparationSeconds)

        // When: Tick 3 times
        timer = timer.tick().first // 2
        timer = timer.tick().first // 1
        timer = timer.tick().first // 0 -> StartGong

        // Then: Should be in StartGong (waiting for gong to finish)
        assertEquals(TimerState.StartGong, timer.state)
        assertEquals(0, timer.remainingPreparationSeconds)
        assertEquals(600, timer.remainingSeconds)
    }

    @Test
    fun `full timer lifecycle ends in endGong phase`() {
        // Given: 1 min timer, no preparation
        var timer =
            MeditationTimer.create(1, preparationTimeSeconds = 0)
                .copy(state = TimerState.Running)

        // When: Tick 60 times (1 minute)
        repeat(60) {
            timer = timer.tick().first
        }

        // Then: Should be in EndGong (gong must finish before Completed)
        assertEquals(TimerState.EndGong, timer.state)
        assertEquals(0, timer.remainingSeconds)
        assertEquals(1.0f, timer.progress, 0.001f)
        assertTrue(timer.isCompleted)
    }

    @Test
    fun `tick preserves state when idle and does not decrement`() {
        // Given
        val timer = MeditationTimer.create(10)
        assertEquals(TimerState.Idle, timer.state)

        // When
        val (ticked, _) = timer.tick()

        // Then: Idle returns same instance (no decrement)
        assertEquals(TimerState.Idle, ticked.state)
        assertEquals(600, ticked.remainingSeconds)
    }

    @Test
    fun `tick preserves completed state with zero remaining`() {
        // Given
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Completed, remainingSeconds = 0)

        // When
        val (ticked, _) = timer.tick()

        // Then: Completed state preserved, remaining stays at 0 (maxOf prevents negative)
        assertEquals(TimerState.Completed, ticked.state)
        assertEquals(0, ticked.remainingSeconds)
    }

    @Test
    fun `repeating full simulation 5min timer 2min interval`() {
        // 5 min timer, 2 min interval, repeating — now via tick(intervalSettings)
        var timer = MeditationTimer.create(5)
            .copy(state = TimerState.Running)
        val intervalSettings = IntervalSettings(intervalMinutes = 2, mode = IntervalMode.REPEATING)
        val gongTimes = mutableListOf<Int>()

        // Simulate 295 ticks (leave 5s for end protection)
        repeat(295) {
            val (ticked, events) = timer.tick(intervalSettings)
            timer = ticked
            if (events.contains(TimerEvent.IntervalGongDue)) {
                gongTimes.add(timer.totalSeconds - timer.remainingSeconds)
            }
        }

        assertEquals(listOf(120, 240), gongTimes, "Expected gongs at elapsed 2min and 4min")
    }

    @Test
    fun `shouldPlayIntervalGong default is REPEATING mode`() {
        // Calling with only intervalMinutes uses default mode=REPEATING
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300)
        // Default parameter: mode=REPEATING → repeating-from-start mode
        assertTrue(timer.shouldPlayIntervalGong(5))
    }

    // MARK: - StartGong State Tests

    @Test
    fun `tick during StartGong decrements remaining seconds`() {
        val timer = MeditationTimer.create(10).copy(state = TimerState.StartGong)
        val (ticked, _) = timer.tick()
        assertEquals(599, ticked.remainingSeconds)
        assertEquals(TimerState.StartGong, ticked.state)
    }

    @Test
    fun `tick during StartGong transitions to endGong at zero`() {
        val timer = MeditationTimer.create(1)
            .copy(state = TimerState.StartGong, remainingSeconds = 1)
        val (ticked, _) = timer.tick()
        assertEquals(0, ticked.remainingSeconds)
        assertEquals(TimerState.EndGong, ticked.state)
    }

    // MARK: - Attunement Tests

    @Test
    fun `create timer with attunementDurationSeconds`() {
        val timer = MeditationTimer.create(10, attunementDurationSeconds = 95)
        assertEquals(95, timer.attunementDurationSeconds)
        assertNull(timer.silentPhaseStartRemaining)
    }

    @Test
    fun `startAttunement transitions to Attunement state`() {
        val timer = MeditationTimer.create(10).copy(state = TimerState.StartGong)
        val intro = timer.startAttunement()
        assertEquals(TimerState.Attunement, intro.state)
    }

    @Test
    fun `tick during Attunement decrements remaining seconds`() {
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Attunement, remainingSeconds = 500)
        val (ticked, _) = timer.tick()
        assertEquals(499, ticked.remainingSeconds)
        assertEquals(TimerState.Attunement, ticked.state)
    }

    @Test
    fun `tick during Attunement transitions to endGong at zero`() {
        val timer = MeditationTimer.create(1)
            .copy(state = TimerState.Attunement, remainingSeconds = 1)
        val (ticked, _) = timer.tick()
        assertEquals(0, ticked.remainingSeconds)
        assertEquals(TimerState.EndGong, ticked.state)
    }

    @Test
    fun `endAttunement transitions to Running and records silentPhaseStartRemaining`() {
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Attunement, remainingSeconds = 505)
        val running = timer.endAttunement()
        assertEquals(TimerState.Running, running.state)
        assertEquals(505, running.silentPhaseStartRemaining)
    }

    @Test
    fun `reset clears silentPhaseStartRemaining`() {
        val timer = MeditationTimer.create(10)
            .copy(
                state = TimerState.Running,
                remainingSeconds = 400,
                silentPhaseStartRemaining = 505
            )
        val resetTimer = timer.reset()
        assertNull(resetTimer.silentPhaseStartRemaining)
    }

    // MARK: - Interval Gong with Attunement (effectiveStartRemaining)

    @Test
    fun `repeating interval uses effectiveStartRemaining after attunement`() {
        // Given: 10 min timer, attunement ended at 505s remaining
        // 5 min interval → first gong at 505 - 300 = 205s remaining
        val timer = MeditationTimer.create(10)
            .copy(
                state = TimerState.Running,
                remainingSeconds = 205,
                silentPhaseStartRemaining = 505
            )
        assertTrue(timer.shouldPlayIntervalGong(5, mode = IntervalMode.REPEATING))
    }

    @Test
    fun `repeating interval does not trigger early with attunement`() {
        // Given: 10 min timer, attunement ended at 505s remaining
        // 5 min interval → first gong at 205s, currently at 400s (not yet)
        val timer = MeditationTimer.create(10)
            .copy(
                state = TimerState.Running,
                remainingSeconds = 400,
                silentPhaseStartRemaining = 505
            )
        assertFalse(timer.shouldPlayIntervalGong(5, mode = IntervalMode.REPEATING))
    }

    @Test
    fun `after start interval uses effectiveStartRemaining after attunement`() {
        // Given: 10 min timer, attunement ended at 505s remaining
        // 3 min after start → at 505 - 180 = 325s remaining
        val timer = MeditationTimer.create(10)
            .copy(
                state = TimerState.Running,
                remainingSeconds = 325,
                silentPhaseStartRemaining = 505
            )
        assertTrue(timer.shouldPlayIntervalGong(3, mode = IntervalMode.AFTER_START))
    }

    // MARK: - Computed Properties (Display)

    @Nested
    inner class ComputedProperties {
        @Test
        fun `isPreparation is true when state is Preparation`() {
            val timer = MeditationTimer.create(10)
                .startPreparation()
            assertTrue(timer.isPreparation)
        }

        @Test
        fun `isPreparation is false when state is Running`() {
            val timer = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            assertFalse(timer.isPreparation)
        }

        @Test
        fun `isActive is true when state is Running`() {
            val timer = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            assertTrue(timer.isActive)
        }

        @Test
        fun `isActive is true when state is Preparation`() {
            val timer = MeditationTimer.create(10)
                .startPreparation()
            assertTrue(timer.isActive)
        }

        @Test
        fun `isActive is true when state is EndGong`() {
            val timer = MeditationTimer.create(10)
                .copy(state = TimerState.EndGong, remainingSeconds = 0)
            assertTrue(timer.isActive)
        }

        @Test
        fun `isActive is false when state is Idle`() {
            val timer = MeditationTimer.create(10)
            assertFalse(timer.isActive)
        }

        @Test
        fun `isActive is false when state is Completed`() {
            val timer = MeditationTimer.create(10)
                .copy(state = TimerState.Completed, remainingSeconds = 0)
            assertFalse(timer.isActive)
        }

        @Test
        fun `isRunning is true only when state is Running`() {
            val running = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            assertTrue(running.isRunning)

            val idle = MeditationTimer.create(10)
            assertFalse(idle.isRunning)

            val preparation = MeditationTimer.create(10).startPreparation()
            assertFalse(preparation.isRunning)
        }

        @Test
        fun `canReset is false when Idle, true for all other states`() {
            val idle = MeditationTimer.create(10)
            assertFalse(idle.canReset)

            val running = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            assertTrue(running.canReset)

            val completed = MeditationTimer.create(10)
                .copy(state = TimerState.Completed, remainingSeconds = 0)
            assertTrue(completed.canReset)

            val preparation = MeditationTimer.create(10).startPreparation()
            assertTrue(preparation.canReset)
        }

        @Test
        fun `canStart is true only when Idle`() {
            val idle = MeditationTimer.create(10)
            assertTrue(idle.canStart)

            val running = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            assertFalse(running.canStart)

            val completed = MeditationTimer.create(10)
                .copy(state = TimerState.Completed, remainingSeconds = 0)
            assertFalse(completed.canStart)
        }

        @Test
        fun `formattedTime shows preparation seconds when in preparation`() {
            val timer = MeditationTimer.create(10)
                .startPreparation()
            assertEquals("15", timer.formattedTime)
        }

        @Test
        fun `formattedTime shows MM-SS format when running`() {
            val timer = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            assertEquals("10:00", timer.formattedTime)
        }

        @Test
        fun `formattedTime shows 00-00 for a completed timer`() {
            val timer = MeditationTimer.create(10)
                .copy(state = TimerState.Completed, remainingSeconds = 0)
            assertEquals("00:00", timer.formattedTime)
        }
    }
}
