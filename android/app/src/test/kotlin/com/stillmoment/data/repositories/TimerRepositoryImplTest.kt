package com.stillmoment.data.repositories

import com.stillmoment.domain.models.TimerState
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

/**
 * Unit tests for TimerRepositoryImpl.
 * Tests timer state management and flow emissions.
 */
class TimerRepositoryImplTest {
    private lateinit var sut: TimerRepositoryImpl

    @BeforeEach
    fun setUp() {
        sut = TimerRepositoryImpl()
    }

    // MARK: - Start Tests

    @Test
    fun `start creates timer with countdown state`() = runTest {
        // When
        sut.start(durationMinutes = 10)

        // Then
        val timer = sut.timerFlow.first()
        assertEquals(TimerState.Preparation, timer.state)
        assertEquals(10, timer.durationMinutes)
        assertEquals(15, timer.remainingPreparationSeconds)
    }

    @Test
    fun `start sets currentTimer`() = runTest {
        // Given
        assertNull(sut.currentTimer)

        // When
        sut.start(durationMinutes = 5)

        // Then
        assertNotNull(sut.currentTimer)
        assertEquals(5, sut.currentTimer?.durationMinutes)
    }

    @Test
    fun `start with zero preparation time goes directly to running`() = runTest {
        // When
        sut.start(durationMinutes = 10, preparationTimeSeconds = 0)

        // Then - Should be in Running state immediately, not Preparation
        val timer = sut.timerFlow.first()
        assertEquals(TimerState.Running, timer.state)
        assertEquals(0, timer.remainingPreparationSeconds)
    }

    // MARK: - Pause Tests

    @Test
    fun `pause changes state to paused`() = runTest {
        // Given
        sut.start(durationMinutes = 10)
        // Simulate countdown completion
        repeat(16) { sut.tick() }

        // When
        sut.pause()

        // Then
        val timer = sut.timerFlow.first()
        assertEquals(TimerState.Paused, timer.state)
    }

    // MARK: - Resume Tests

    @Test
    fun `resume changes state to running`() = runTest {
        // Given
        sut.start(durationMinutes = 10)
        repeat(16) { sut.tick() } // Complete countdown
        sut.pause()

        // When
        sut.resume()

        // Then
        val timer = sut.timerFlow.first()
        assertEquals(TimerState.Running, timer.state)
    }

    // MARK: - Reset Tests

    @Test
    fun `reset clears current timer`() = runTest {
        // Given
        sut.start(durationMinutes = 10)
        assertNotNull(sut.currentTimer)

        // When
        sut.reset()

        // Then
        assertNull(sut.currentTimer)
    }

    // MARK: - SetDuration Tests

    @Test
    fun `setDuration creates idle timer when no timer exists`() = runTest {
        // When
        sut.setDuration(durationMinutes = 20)

        // Then
        val timer = sut.timerFlow.first()
        assertEquals(20, timer.durationMinutes)
        assertEquals(TimerState.Idle, timer.state)
    }

    @Test
    fun `setDuration updates timer when idle`() = runTest {
        // Given
        sut.setDuration(durationMinutes = 10)

        // When
        sut.setDuration(durationMinutes = 30)

        // Then
        val timer = sut.timerFlow.first()
        assertEquals(30, timer.durationMinutes)
    }

    @Test
    fun `setDuration does nothing when timer is running`() = runTest {
        // Given
        sut.start(durationMinutes = 10)
        repeat(16) { sut.tick() } // Complete countdown to enter Running state

        // When
        sut.setDuration(durationMinutes = 30)

        // Then
        val timer = sut.timerFlow.first()
        assertEquals(10, timer.durationMinutes) // Unchanged
    }

    // MARK: - Tick Tests

    @Test
    fun `tick decrements countdown during countdown phase`() = runTest {
        // Given
        sut.start(durationMinutes = 10)

        // When
        val result = sut.tick()

        // Then
        assertEquals(14, result?.remainingPreparationSeconds)
        assertEquals(TimerState.Preparation, result?.state)
    }

    @Test
    fun `tick transitions to running after countdown completes`() = runTest {
        // Given
        sut.start(durationMinutes = 10)

        // When - tick through entire countdown
        repeat(15) { sut.tick() }
        val result = sut.tick() // 16th tick

        // Then
        assertEquals(TimerState.Running, result?.state)
        assertEquals(0, result?.remainingPreparationSeconds)
    }

    @Test
    fun `tick decrements remaining seconds during running phase`() = runTest {
        // Given
        sut.start(durationMinutes = 1) // 60 seconds
        repeat(15) { sut.tick() } // Complete countdown (15 ticks: 15→0)

        // When - first tick in Running phase
        val result = sut.tick()

        // Then
        assertEquals(59, result?.remainingSeconds)
    }

    @Test
    fun `tick returns null when no timer exists`() = runTest {
        // When
        val result = sut.tick()

        // Then
        assertNull(result)
    }

    @Test
    fun `tick updates flow value`() = runTest {
        // Given
        sut.start(durationMinutes = 10)
        val initialCountdown = sut.timerFlow.first().remainingPreparationSeconds

        // When
        sut.tick()

        // Then
        val updatedCountdown = sut.timerFlow.first().remainingPreparationSeconds
        assertEquals(initialCountdown - 1, updatedCountdown)
    }
}
