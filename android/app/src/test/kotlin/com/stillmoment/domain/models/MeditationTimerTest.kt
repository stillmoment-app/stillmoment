package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.*
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
        val ticked = timer.tick()

        // Then
        assertEquals(14, ticked.remainingPreparationSeconds)
        assertEquals(TimerState.Preparation, ticked.state)
        assertEquals(600, ticked.remainingSeconds) // Timer hasn't started
    }

    @Test
    fun `tick transitions from countdown to running when countdown reaches 0`() {
        // Given
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Preparation, remainingPreparationSeconds = 1)

        // When
        val ticked = timer.tick()

        // Then
        assertEquals(0, ticked.remainingPreparationSeconds)
        assertEquals(TimerState.Running, ticked.state)
    }

    @Test
    fun `tick during running decrements remaining seconds`() {
        // Given
        val timer = MeditationTimer.create(10).copy(state = TimerState.Running)

        // When
        val ticked = timer.tick()

        // Then
        assertEquals(599, ticked.remainingSeconds)
        assertEquals(TimerState.Running, ticked.state)
    }

    @Test
    fun `tick transitions to completed when remaining seconds reach 0`() {
        // Given
        val timer =
            MeditationTimer.create(1)
                .copy(state = TimerState.Running, remainingSeconds = 1)

        // When
        val ticked = timer.tick()

        // Then
        assertEquals(0, ticked.remainingSeconds)
        assertEquals(TimerState.Completed, ticked.state)
    }

    @Test
    fun `tick does not go below 0 remaining seconds`() {
        // Given
        val timer =
            MeditationTimer.create(1)
                .copy(state = TimerState.Running, remainingSeconds = 0)

        // When
        val ticked = timer.tick()

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
        assertFalse(timer.shouldPlayIntervalGong(1, repeating = true, fromEnd = false))
    }

    // MARK: - Repeating from Start

    @Test
    fun `repeating from start triggers at first interval`() {
        // Given: 10 min timer, 5 min elapsed (300s remaining)
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300)
        assertTrue(timer.shouldPlayIntervalGong(5, repeating = true, fromEnd = false))
    }

    @Test
    fun `repeating from start does not trigger before first interval`() {
        // Given: 10 min timer, 2 min elapsed (480s remaining)
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 480)
        assertFalse(timer.shouldPlayIntervalGong(5, repeating = true, fromEnd = false))
    }

    @Test
    fun `repeating from start respects lastIntervalGongAt`() {
        // Given: Already played at 300s remaining, still at 300s
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300, lastIntervalGongAt = 300)
        assertFalse(timer.shouldPlayIntervalGong(5, repeating = true, fromEnd = false))
    }

    @Test
    fun `repeating from start triggers on next interval after last gong`() {
        // Given: 15 min timer, 5 min interval, last gong at 600s remaining (5 min elapsed)
        // Now at 300s remaining (10 min elapsed) - should trigger again
        val timer = MeditationTimer.create(15)
            .copy(state = TimerState.Running, remainingSeconds = 300, lastIntervalGongAt = 600)
        assertTrue(timer.shouldPlayIntervalGong(5, repeating = true, fromEnd = false))
    }

    @Test
    fun `repeating from start with 1 minute interval on 3 minute timer`() {
        // Given: 3 min timer, 1 min interval, 1 min elapsed (120s remaining)
        val timer = MeditationTimer.create(3)
            .copy(state = TimerState.Running, remainingSeconds = 120)
        assertTrue(timer.shouldPlayIntervalGong(1, repeating = true, fromEnd = false))
    }

    // MARK: - Repeating from End

    @Test
    fun `repeating from end triggers at correct times for even division`() {
        // Given: 10 min timer, 5 min interval from end
        // Gongs at: 5:00 remaining and 0:00 (but 0 is protected by end gong)
        // So effectively at 5:00 remaining (5 min elapsed)
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300)
        assertTrue(timer.shouldPlayIntervalGong(5, repeating = true, fromEnd = true))
    }

    @Test
    fun `repeating from end triggers at correct times for uneven division`() {
        // Given: 23 min timer, 5 min interval from end
        // From end: 5, 10, 15, 20 min remaining
        // First gong at 3 min elapsed (23-20=3, remainder=3), then every 5 min
        // At elapsed = 3 min -> remaining = 20*60 = 1200s
        val timer = MeditationTimer.create(23)
            .copy(state = TimerState.Running, remainingSeconds = 1200)
        assertTrue(timer.shouldPlayIntervalGong(5, repeating = true, fromEnd = true))
    }

    @Test
    fun `repeating from end does not trigger before first interval`() {
        // Given: 23 min timer, 5 min from end, only 1 min elapsed (22 min remaining = 1320s)
        val timer = MeditationTimer.create(23)
            .copy(state = TimerState.Running, remainingSeconds = 1320)
        assertFalse(timer.shouldPlayIntervalGong(5, repeating = true, fromEnd = true))
    }

    // MARK: - Single Mode

    @Test
    fun `single mode triggers once before end`() {
        // Given: 10 min timer, 3 min interval (single) -> plays at 3 min remaining = 180s
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 180)
        assertTrue(timer.shouldPlayIntervalGong(3, repeating = false, fromEnd = false))
    }

    @Test
    fun `single mode does not trigger too early`() {
        // Given: 10 min timer, 3 min interval (single) -> too early at 5 min remaining
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300)
        assertFalse(timer.shouldPlayIntervalGong(3, repeating = false, fromEnd = false))
    }

    @Test
    fun `single mode does not trigger again after played`() {
        // Given: Already played at 180s
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 180, lastIntervalGongAt = 180)
        assertFalse(timer.shouldPlayIntervalGong(3, repeating = false, fromEnd = false))
    }

    @Test
    fun `single mode does not trigger in end protection zone`() {
        // Given: 10 min timer, interval = 3s -> 3s remaining is inside 5s protection
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 3)
        assertFalse(timer.shouldPlayIntervalGong(0, repeating = false, fromEnd = false))
    }

    // MARK: - Edge Case Tests

    @Test
    fun `multiple ticks countdown correctly`() {
        // Given: 10 min timer with 3 sec countdown
        var timer = MeditationTimer.create(10, preparationTimeSeconds = 3).startPreparation()
        assertEquals(TimerState.Preparation, timer.state)
        assertEquals(3, timer.remainingPreparationSeconds)

        // When: Tick 3 times
        timer = timer.tick() // 2
        timer = timer.tick() // 1
        timer = timer.tick() // 0 -> Running

        // Then: Should be running
        assertEquals(TimerState.Running, timer.state)
        assertEquals(0, timer.remainingPreparationSeconds)
        assertEquals(600, timer.remainingSeconds)
    }

    @Test
    fun `full timer lifecycle simulation`() {
        // Given: 1 min timer with no countdown
        var timer =
            MeditationTimer.create(1, preparationTimeSeconds = 0)
                .copy(state = TimerState.Running)

        // When: Tick 60 times (1 minute)
        repeat(60) {
            timer = timer.tick()
        }

        // Then: Should be completed
        assertEquals(TimerState.Completed, timer.state)
        assertEquals(0, timer.remainingSeconds)
        assertEquals(1.0f, timer.progress, 0.001f)
        assertTrue(timer.isCompleted)
    }

    @Test
    fun `tick preserves state when idle but decrements remaining`() {
        // Given
        val timer = MeditationTimer.create(10)
        assertEquals(TimerState.Idle, timer.state)

        // When
        val ticked = timer.tick()

        // Then: State preserved, but remaining seconds decremented
        // Note: ViewModel only calls tick() during Countdown/Running states
        assertEquals(TimerState.Idle, ticked.state)
        assertEquals(599, ticked.remainingSeconds)
    }

    @Test
    fun `tick preserves completed state with zero remaining`() {
        // Given
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Completed, remainingSeconds = 0)

        // When
        val ticked = timer.tick()

        // Then: Completed state preserved, remaining stays at 0 (maxOf prevents negative)
        assertEquals(TimerState.Completed, ticked.state)
        assertEquals(0, ticked.remainingSeconds)
    }

    @Test
    fun `shouldPlayIntervalGong backward compat default is repeating from start`() {
        // Calling with only intervalMinutes uses default repeating=true, fromEnd=false
        val timer = MeditationTimer.create(10)
            .copy(state = TimerState.Running, remainingSeconds = 300)
        // Default parameters: repeating=true, fromEnd=false → repeating-from-start mode
        assertTrue(timer.shouldPlayIntervalGong(5))
    }
}
