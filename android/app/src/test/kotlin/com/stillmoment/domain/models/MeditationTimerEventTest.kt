package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Tests for TimerEvent emission from MeditationTimer.tick().
 *
 * Verifies that tick() correctly emits domain events instead of requiring
 * the ViewModel to detect state transitions via previousState comparison.
 */
class MeditationTimerEventTest {
    @Nested
    inner class PreparationEvents {
        @Test
        fun `preparation countdown reaches zero emits preparationCompleted`() {
            // Given - Timer in preparation with 1 second remaining
            val timer = MeditationTimer.create(10, preparationTimeSeconds = 1)
                .startPreparation()

            // When - Final preparation tick
            val (newTimer, events) = timer.tick()

            // Then - preparationCompleted event emitted, timer transitions to startGong
            assertEquals(listOf(TimerEvent.PreparationCompleted), events)
            assertEquals(TimerState.StartGong, newTimer.state)
        }

        @Test
        fun `preparation countdown still running emits no events`() {
            // Given - Timer in preparation with 5 seconds remaining
            val timer = MeditationTimer.create(10, preparationTimeSeconds = 5)
                .startPreparation()

            // When - One tick (4 seconds remaining)
            val (newTimer, events) = timer.tick()

            // Then - No events, still in preparation
            assertEquals(emptyList<TimerEvent>(), events)
            assertEquals(TimerState.Preparation, newTimer.state)
            assertEquals(4, newTimer.remainingPreparationSeconds)
        }
    }

    @Nested
    inner class MeditationCompletedEvents {
        @Test
        fun `running timer reaches zero emits meditationCompleted`() {
            // Given - Timer running with 1 second remaining
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.Running, remainingSeconds = 1)

            // When - Final tick
            val (newTimer, events) = timer.tick()

            // Then - meditationCompleted event emitted, timer transitions to endGong
            assertEquals(listOf(TimerEvent.MeditationCompleted), events)
            assertEquals(TimerState.EndGong, newTimer.state)
            assertEquals(0, newTimer.remainingSeconds)
        }

        @Test
        fun `running timer still running emits no events`() {
            // Given - Timer running with plenty of time
            val timer = MeditationTimer.create(10)
                .copy(state = TimerState.Running)

            // When
            val (newTimer, events) = timer.tick()

            // Then - No events, still running
            assertEquals(emptyList<TimerEvent>(), events)
            assertEquals(TimerState.Running, newTimer.state)
        }

        @Test
        fun `startGong timer reaches zero emits meditationCompleted`() {
            // Given - Timer in startGong state with 1 second remaining
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.StartGong, remainingSeconds = 1)

            // When - Final tick
            val (newTimer, events) = timer.tick()

            // Then
            assertEquals(listOf(TimerEvent.MeditationCompleted), events)
            assertEquals(TimerState.EndGong, newTimer.state)
        }
    }

    @Nested
    inner class IntervalGongEvents {
        @Test
        fun `interval gong due emits intervalGongDue`() {
            // Given - 10 min timer, 5 min repeating interval, exactly at interval point
            var timer = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            val intervalSettings = IntervalSettings(intervalMinutes = 5, mode = IntervalMode.REPEATING)

            // Tick to just before interval (299 ticks = 299 seconds elapsed)
            repeat(299) {
                val (ticked, _) = timer.tick(intervalSettings)
                timer = ticked
            }

            // When - Tick at 300 seconds elapsed (5 min interval)
            val (newTimer, events) = timer.tick(intervalSettings)

            // Then - intervalGongDue emitted, timer marks gong internally
            assertEquals(listOf(TimerEvent.IntervalGongDue), events)
            assertEquals(TimerState.Running, newTimer.state)
            assertNotNull(newTimer.lastIntervalGongAt)
        }

        @Test
        fun `interval gong not yet due emits no events`() {
            // Given - 10 min timer, 5 min interval, only 4 min elapsed
            var timer = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            val intervalSettings = IntervalSettings(intervalMinutes = 5, mode = IntervalMode.REPEATING)

            repeat(239) {
                val (ticked, _) = timer.tick(intervalSettings)
                timer = ticked
            }

            // When - 240th second (4 min)
            val (_, events) = timer.tick(intervalSettings)

            // Then - No interval gong yet
            assertEquals(emptyList<TimerEvent>(), events)
        }

        @Test
        fun `no interval settings never emits intervalGongDue`() {
            // Given - 10 min timer, exactly at 5 min mark, but no interval settings
            var timer = MeditationTimer.create(10)
                .copy(state = TimerState.Running)

            repeat(300) {
                val (ticked, _) = timer.tick()
                timer = ticked
            }

            // When - At 5 min mark without interval settings
            val (_, events) = timer.tick()

            // Then - No interval gong events
            assertEquals(emptyList<TimerEvent>(), events)
        }
    }

    @Nested
    inner class IntervalModes {
        @Test
        fun `afterStart mode emits once only`() {
            // Given - 20 min timer, 5 min afterStart interval
            var timer = MeditationTimer.create(20)
                .copy(state = TimerState.Running)
            val intervalSettings = IntervalSettings(intervalMinutes = 5, mode = IntervalMode.AFTER_START)

            // Tick to 5 min
            repeat(300) {
                val (ticked, _) = timer.tick(intervalSettings)
                timer = ticked
            }

            // First gong emitted and marked
            assertNotNull(timer.lastIntervalGongAt)

            // Tick to 10 min - no second gong in afterStart mode
            repeat(300) {
                val (ticked, events) = timer.tick(intervalSettings)
                timer = ticked
                assertFalse(events.contains(TimerEvent.IntervalGongDue))
            }
        }

        @Test
        fun `beforeEnd mode emits at correct time`() {
            // Given - 20 min timer, 5 min beforeEnd interval
            var timer = MeditationTimer.create(20)
                .copy(state = TimerState.Running)
            val intervalSettings = IntervalSettings(intervalMinutes = 5, mode = IntervalMode.BEFORE_END)

            // Tick to 15 min elapsed (5 min remaining = 300 seconds)
            repeat(899) {
                val (ticked, _) = timer.tick(intervalSettings)
                timer = ticked
            }

            // When - At exactly 300 seconds remaining
            val (newTimer, events) = timer.tick(intervalSettings)

            // Then
            assertEquals(listOf(TimerEvent.IntervalGongDue), events)
            assertNotNull(newTimer.lastIntervalGongAt)
        }

        @Test
        fun `repeating mode emits multiple interval gongs`() {
            // Given - 10 min timer, 3 min repeating intervals
            var timer = MeditationTimer.create(10)
                .copy(state = TimerState.Running)
            val intervalSettings = IntervalSettings(intervalMinutes = 3, mode = IntervalMode.REPEATING)
            var gongCount = 0

            // When - Tick through entire meditation (stop before 5-second protection zone)
            repeat(594) {
                val (ticked, events) = timer.tick(intervalSettings)
                timer = ticked
                if (events.contains(TimerEvent.IntervalGongDue)) {
                    gongCount++
                }
            }

            // Then - Should have emitted 3 gongs (at 3, 6, 9 minutes)
            assertEquals(3, gongCount)
        }
    }

    @Nested
    inner class FiveSecondProtection {
        @Test
        fun `no interval gong in last five seconds`() {
            // Given - 2 min timer, 1 min interval
            var timer = MeditationTimer.create(2)
                .copy(state = TimerState.Running)
            val intervalSettings = IntervalSettings(intervalMinutes = 1, mode = IntervalMode.REPEATING)

            // Tick first interval at 1 min
            repeat(60) {
                val (ticked, _) = timer.tick(intervalSettings)
                timer = ticked
            }

            // Tick to 5 seconds remaining
            repeat(55) {
                val (ticked, _) = timer.tick(intervalSettings)
                timer = ticked
            }

            assertEquals(5, timer.remainingSeconds)

            // When - Tick at 5 seconds remaining
            val (_, events) = timer.tick(intervalSettings)

            // Then - No interval gong due to 5-second protection
            assertFalse(events.contains(TimerEvent.IntervalGongDue))
        }
    }

    @Nested
    inner class InactiveStates {
        @Test
        fun `idle state emits no events`() {
            val timer = MeditationTimer.create(10)
            val (newTimer, events) = timer.tick()
            assertEquals(emptyList<TimerEvent>(), events)
            assertEquals(timer, newTimer) // No change
        }

        @Test
        fun `endGong state emits no events`() {
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.EndGong, remainingSeconds = 0)
            val (newTimer, events) = timer.tick()
            assertEquals(emptyList<TimerEvent>(), events)
            assertEquals(timer, newTimer)
        }

        @Test
        fun `completed state emits no events`() {
            val timer = MeditationTimer.create(1)
                .copy(state = TimerState.Completed, remainingSeconds = 0)
            val (newTimer, events) = timer.tick()
            assertEquals(emptyList<TimerEvent>(), events)
            assertEquals(timer, newTimer)
        }
    }

    @Nested
    inner class CompleteSessionSequence {
        @Test
        fun `full session emits correct event sequence`() {
            // Given - 1 min timer with 2-second preparation
            var timer = MeditationTimer.create(1, preparationTimeSeconds = 2)
                .startPreparation()
            val allEvents = mutableListOf<TimerEvent>()

            // Preparation phase: tick 2 times
            repeat(2) {
                val (ticked, events) = timer.tick()
                timer = ticked
                allEvents.addAll(events)
            }

            // Should have emitted preparationCompleted
            assertEquals(listOf(TimerEvent.PreparationCompleted), allEvents)
            assertEquals(TimerState.StartGong, timer.state)

            // Simulate: ViewModel dispatches preparationFinished -> reducer -> running
            timer = timer.withState(TimerState.Running)

            // Running phase: tick 60 times
            repeat(60) {
                val (ticked, events) = timer.tick()
                timer = ticked
                allEvents.addAll(events)
            }

            // Then - Full sequence: preparationCompleted, then meditationCompleted
            assertEquals(
                listOf(TimerEvent.PreparationCompleted, TimerEvent.MeditationCompleted),
                allEvents
            )
            assertEquals(TimerState.EndGong, timer.state)
        }
    }
}
