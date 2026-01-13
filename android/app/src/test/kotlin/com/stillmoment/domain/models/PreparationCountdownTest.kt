package com.stillmoment.domain.models

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for PreparationCountdown domain model.
 *
 * Following the same pattern as iOS PreparationCountdown:
 * - Immutable Value Object
 * - tick() returns new instance
 * - progress and isFinished computed properties
 */
class PreparationCountdownTest {

    // MARK: - Initialization

    @Test
    fun `new countdown has remainingSeconds equal to totalSeconds`() {
        val countdown = PreparationCountdown(totalSeconds = 15)

        assertEquals(15, countdown.totalSeconds)
        assertEquals(15, countdown.remainingSeconds)
    }

    @Test
    fun `countdown can be created with explicit remainingSeconds`() {
        val countdown = PreparationCountdown(totalSeconds = 15, remainingSeconds = 10)

        assertEquals(15, countdown.totalSeconds)
        assertEquals(10, countdown.remainingSeconds)
    }

    // MARK: - isFinished

    @Test
    fun `isFinished returns false when remainingSeconds is positive`() {
        val countdown = PreparationCountdown(totalSeconds = 15, remainingSeconds = 1)

        assertFalse(countdown.isFinished)
    }

    @Test
    fun `isFinished returns true when remainingSeconds is zero`() {
        val countdown = PreparationCountdown(totalSeconds = 15, remainingSeconds = 0)

        assertTrue(countdown.isFinished)
    }

    @Test
    fun `isFinished returns true when remainingSeconds is negative`() {
        val countdown = PreparationCountdown(totalSeconds = 15, remainingSeconds = -1)

        assertTrue(countdown.isFinished)
    }

    // MARK: - progress

    @Test
    fun `progress is 0 at start`() {
        val countdown = PreparationCountdown(totalSeconds = 15)

        assertEquals(0.0, countdown.progress, 0.001)
    }

    @Test
    fun `progress is 1 when finished`() {
        val countdown = PreparationCountdown(totalSeconds = 15, remainingSeconds = 0)

        assertEquals(1.0, countdown.progress, 0.001)
    }

    @Test
    fun `progress is 0_5 at halfway`() {
        val countdown = PreparationCountdown(totalSeconds = 10, remainingSeconds = 5)

        assertEquals(0.5, countdown.progress, 0.001)
    }

    @Test
    fun `progress is 0 when totalSeconds is 0`() {
        val countdown = PreparationCountdown(totalSeconds = 0, remainingSeconds = 0)

        assertEquals(0.0, countdown.progress, 0.001)
    }

    // MARK: - tick

    @Test
    fun `tick returns new instance with remainingSeconds decremented`() {
        val countdown = PreparationCountdown(totalSeconds = 15, remainingSeconds = 10)
        val ticked = countdown.tick()

        assertEquals(9, ticked.remainingSeconds)
        assertEquals(15, ticked.totalSeconds)
    }

    @Test
    fun `tick does not go below 0`() {
        val countdown = PreparationCountdown(totalSeconds = 15, remainingSeconds = 0)
        val ticked = countdown.tick()

        assertEquals(0, ticked.remainingSeconds)
    }

    @Test
    fun `original countdown is unchanged after tick`() {
        val original = PreparationCountdown(totalSeconds = 15, remainingSeconds = 10)
        original.tick()

        assertEquals(10, original.remainingSeconds)
    }

    // MARK: - Full Countdown Simulation

    @Test
    fun `countdown completes after correct number of ticks`() {
        var countdown = PreparationCountdown(totalSeconds = 3)

        assertFalse(countdown.isFinished)
        assertEquals(0.0, countdown.progress, 0.001)

        countdown = countdown.tick() // 2 remaining
        assertFalse(countdown.isFinished)

        countdown = countdown.tick() // 1 remaining
        assertFalse(countdown.isFinished)

        countdown = countdown.tick() // 0 remaining
        assertTrue(countdown.isFinished)
        assertEquals(1.0, countdown.progress, 0.001)
    }
}
