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
        assertEquals(0, timer.countdownSeconds)
        assertEquals(15, timer.countdownDuration)
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
        val timer = MeditationTimer.create(10, countdownDuration = 5)
        assertEquals(5, timer.countdownDuration)
    }

    @Test
    fun `create timer with zero countdown duration (skip countdown)`() {
        val timer = MeditationTimer.create(10, countdownDuration = 0)
        assertEquals(0, timer.countdownDuration)
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
        val timer = MeditationTimer.create(10).startCountdown()
        assertEquals(15, timer.countdownSeconds)

        // When
        val ticked = timer.tick()

        // Then
        assertEquals(14, ticked.countdownSeconds)
        assertEquals(TimerState.Countdown, ticked.state)
        assertEquals(600, ticked.remainingSeconds) // Timer hasn't started
    }

    @Test
    fun `tick transitions from countdown to running when countdown reaches 0`() {
        // Given
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Countdown, countdownSeconds = 1)

        // When
        val ticked = timer.tick()

        // Then
        assertEquals(0, ticked.countdownSeconds)
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
        val paused = timer.withState(TimerState.Paused)
        assertEquals(TimerState.Paused, paused.state)
    }

    @Test
    fun `startCountdown sets countdown state and seconds`() {
        // Given
        val timer = MeditationTimer.create(10)

        // When
        val counting = timer.startCountdown()

        // Then
        assertEquals(TimerState.Countdown, counting.state)
        assertEquals(15, counting.countdownSeconds)
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
                    countdownSeconds = 5,
                    lastIntervalGongAt = 300,
                )

        // When
        val resetTimer = timer.reset()

        // Then
        assertEquals(TimerState.Idle, resetTimer.state)
        assertEquals(600, resetTimer.remainingSeconds)
        assertEquals(0, resetTimer.countdownSeconds)
        assertNull(resetTimer.lastIntervalGongAt)
        assertEquals(10, resetTimer.durationMinutes) // Preserved
    }

    // MARK: - Interval Gong Tests

    @Test
    fun `shouldPlayIntervalGong returns false when not running`() {
        val timer = MeditationTimer.create(10).copy(state = TimerState.Paused)
        assertFalse(timer.shouldPlayIntervalGong(5))
    }

    @Test
    fun `shouldPlayIntervalGong returns false with zero interval`() {
        val timer = MeditationTimer.create(10).copy(state = TimerState.Running)
        assertFalse(timer.shouldPlayIntervalGong(0))
    }

    @Test
    fun `shouldPlayIntervalGong returns true after first interval passed`() {
        // Given: 10 min timer, 5 min elapsed (5 min remaining = 300s)
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Running, remainingSeconds = 300)

        // When/Then: 5 minute interval should trigger
        assertTrue(timer.shouldPlayIntervalGong(5))
    }

    @Test
    fun `shouldPlayIntervalGong returns false before first interval`() {
        // Given: 10 min timer, 2 min elapsed (8 min remaining = 480s)
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Running, remainingSeconds = 480)

        // When/Then: 5 minute interval should NOT trigger (only 2 min passed)
        assertFalse(timer.shouldPlayIntervalGong(5))
    }

    @Test
    fun `markIntervalGongPlayed records remaining seconds`() {
        // Given
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Running, remainingSeconds = 300)

        // When
        val marked = timer.markIntervalGongPlayed()

        // Then
        assertEquals(300, marked.lastIntervalGongAt)
    }

    @Test
    fun `shouldPlayIntervalGong returns false at 0 remaining seconds`() {
        // Given: Timer completed
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Running, remainingSeconds = 0, lastIntervalGongAt = 300)

        // When/Then
        assertFalse(timer.shouldPlayIntervalGong(5))
    }

    // MARK: - Edge Case Tests

    @Test
    fun `multiple ticks countdown correctly`() {
        // Given: 10 min timer with 3 sec countdown
        var timer = MeditationTimer.create(10, countdownDuration = 3).startCountdown()
        assertEquals(TimerState.Countdown, timer.state)
        assertEquals(3, timer.countdownSeconds)

        // When: Tick 3 times
        timer = timer.tick() // 2
        timer = timer.tick() // 1
        timer = timer.tick() // 0 -> Running

        // Then: Should be running
        assertEquals(TimerState.Running, timer.state)
        assertEquals(0, timer.countdownSeconds)
        assertEquals(600, timer.remainingSeconds)
    }

    @Test
    fun `full timer lifecycle simulation`() {
        // Given: 1 min timer with no countdown
        var timer =
            MeditationTimer.create(1, countdownDuration = 0)
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
    fun `tick preserves state when paused but decrements remaining`() {
        // Given
        val timer =
            MeditationTimer.create(10)
                .copy(state = TimerState.Paused, remainingSeconds = 300)

        // When
        val ticked = timer.tick()

        // Then: State preserved, remaining decremented
        // Note: ViewModel only calls tick() during Countdown/Running states
        assertEquals(TimerState.Paused, ticked.state)
        assertEquals(299, ticked.remainingSeconds)
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
    fun `shouldPlayIntervalGong respects lastIntervalGongAt`() {
        // Given: 10 min timer, interval already played at 300s
        val timer =
            MeditationTimer.create(10)
                .copy(
                    state = TimerState.Running,
                    remainingSeconds = 300,
                    lastIntervalGongAt = 300,
                )

        // When/Then: Should NOT play again at same remaining seconds
        assertFalse(timer.shouldPlayIntervalGong(5))
    }

    @Test
    fun `shouldPlayIntervalGong triggers on next interval`() {
        // Given: 10 min timer, first gong played at 300s (5 min elapsed)
        // Now at 0s remaining (timer would complete, but testing interval logic)
        val timer =
            MeditationTimer.create(10)
                .copy(
                    state = TimerState.Running,
                    remainingSeconds = 1, // Almost done, but still running
                    lastIntervalGongAt = 300,
                )

        // When/Then: Should NOT play (we're at 9:59 elapsed, already played at 5:00)
        // Note: With 5 min intervals on 10 min timer, only one gong at 5 min mark
        assertFalse(timer.shouldPlayIntervalGong(5))
    }
}
