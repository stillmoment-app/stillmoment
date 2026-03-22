package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Tests for the endGong phase in MeditationTimer domain model.
 *
 * The endGong phase ensures the completion gong plays fully before
 * the meditation session is marked as completed.
 */
class MeditationTimerEndGongTest {

    @Nested
    inner class TickTransitionsToEndGong {
        @Test
        fun `running timer reaching zero transitions to endGong not completed`() {
            // Given: Timer in Running with 1 second left
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.Running, remainingSeconds = 1)

            // When: Timer ticks
            val (ticked, _) = timer.tick()

            // Then: Transitions to EndGong (not Completed)
            assertEquals(0, ticked.remainingSeconds)
            assertEquals(TimerState.EndGong, ticked.state)
        }

        @Test
        fun `startGong timer reaching zero transitions to endGong`() {
            // Given: Timer in StartGong with 1 second left
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.StartGong, remainingSeconds = 1)

            // When: Timer ticks
            val (ticked, _) = timer.tick()

            // Then: Transitions to EndGong
            assertEquals(0, ticked.remainingSeconds)
            assertEquals(TimerState.EndGong, ticked.state)
        }

        @Test
        fun `attunement timer reaching zero transitions to endGong`() {
            // Given: Timer in Attunement with 1 second left
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.Attunement, remainingSeconds = 1)

            // When: Timer ticks
            val (ticked, _) = timer.tick()

            // Then: Transitions to EndGong
            assertEquals(0, ticked.remainingSeconds)
            assertEquals(TimerState.EndGong, ticked.state)
        }
    }

    @Nested
    inner class EndGongPhaseBehavior {
        @Test
        fun `tick in endGong does not change state`() {
            // Given: Timer in EndGong phase
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.EndGong, remainingSeconds = 0)

            // When: Timer ticks (should be no-op)
            val (ticked, _) = timer.tick()

            // Then: State unchanged
            assertEquals(TimerState.EndGong, ticked.state)
            assertEquals(0, ticked.remainingSeconds)
        }

        @Test
        fun `isCompleted is true during endGong`() {
            // Given: Timer in EndGong (remaining = 0)
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.EndGong, remainingSeconds = 0)

            // Then
            assertTrue(timer.isCompleted)
        }

        @Test
        fun `progress is 1 during endGong`() {
            // Given: Timer in EndGong (remaining = 0)
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.EndGong, remainingSeconds = 0)

            // Then
            assertEquals(1.0f, timer.progress, 0.001f)
        }

        @Test
        fun `reset from endGong returns to idle`() {
            // Given: Timer in EndGong
            val timer = MeditationTimer.create(10)
                .copy(state = TimerState.EndGong, remainingSeconds = 0)

            // When
            val resetTimer = timer.reset()

            // Then
            assertEquals(TimerState.Idle, resetTimer.state)
            assertEquals(600, resetTimer.remainingSeconds)
        }
    }

    @Nested
    inner class FullLifecycleWithEndGong {
        @Test
        fun `full timer lifecycle includes endGong phase`() {
            // Given: 1 min timer, no preparation
            var timer = MeditationTimer.create(1, preparationTimeSeconds = 0)
                .copy(state = TimerState.Running)

            // When: Tick 60 times
            repeat(60) {
                val (ticked, _) = timer.tick()
                timer = ticked
            }

            // Then: Should be in EndGong (not Completed)
            assertEquals(TimerState.EndGong, timer.state)
            assertEquals(0, timer.remainingSeconds)
            assertTrue(timer.isCompleted)
        }
    }
}
