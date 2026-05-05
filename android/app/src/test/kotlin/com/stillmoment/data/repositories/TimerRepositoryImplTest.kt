package com.stillmoment.data.repositories

import com.stillmoment.domain.models.TimerEvent
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
    fun `start with zero preparation time goes directly to start gong`() = runTest {
        // When
        sut.start(durationMinutes = 10, preparationTimeSeconds = 0)

        // Then - Should be in StartGong state immediately (gong plays, then Running)
        val timer = sut.timerFlow.first()
        assertEquals(TimerState.StartGong, timer.state)
        assertEquals(0, timer.remainingPreparationSeconds)
    }

    @Test
    fun `start without preparation emits preparationCompleted`() = runTest {
        // Given — user starts timer without preparation time

        // When
        val events = sut.start(durationMinutes = 10, preparationTimeSeconds = 0)

        // Then — preparation is immediately complete, so start gong flow can begin
        assertEquals(listOf(TimerEvent.PreparationCompleted), events)
    }

    @Test
    fun `start with preparation does not emit preparationCompleted`() = runTest {
        // Given — user starts timer with preparation time

        // When
        val events = sut.start(durationMinutes = 10, preparationTimeSeconds = 15)

        // Then — preparation not yet complete, event comes later via tick()
        assertEquals(emptyList<TimerEvent>(), events)
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
        val (timer, events) = result!!
        assertEquals(14, timer.remainingPreparationSeconds)
        assertEquals(TimerState.Preparation, timer.state)
        assertEquals(emptyList<TimerEvent>(), events)
    }

    @Test
    fun `tick transitions to start gong after countdown completes`() = runTest {
        // Given
        sut.start(durationMinutes = 10)

        // When - tick through countdown (15→1), then final tick (1→0)
        repeat(14) { sut.tick() }
        val result = sut.tick() // 15th tick: 1→0 transitions to StartGong

        // Then — preparation → StartGong (gong plays, then Running via event)
        val (timer, events) = result!!
        assertEquals(TimerState.StartGong, timer.state)
        assertEquals(0, timer.remainingPreparationSeconds)
        assertEquals(listOf(TimerEvent.PreparationCompleted), events)
    }

    @Test
    fun `tick decrements remaining seconds during running phase`() = runTest {
        // Given
        sut.start(durationMinutes = 1) // 60 seconds
        repeat(15) { sut.tick() } // Complete countdown (15 ticks: 15→0)

        // When - first tick in Running phase (now in StartGong state)
        val result = sut.tick()

        // Then
        val (timer, _) = result!!
        assertEquals(59, timer.remainingSeconds)
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

    // MARK: - StartRunning Tests

    @Test
    fun `startRunning transitions from StartGong to Running`() = runTest {
        // Given — timer in StartGong state (preparation disabled)
        sut.start(durationMinutes = 10, preparationTimeSeconds = 0)
        assertEquals(TimerState.StartGong, sut.currentTimer?.state)

        // When
        sut.startRunning()

        // Then
        val timer = sut.timerFlow.first()
        assertEquals(TimerState.Running, timer.state)
    }

    @Test
    fun `completeTimer transitions to Completed`() = runTest {
        // Given
        sut.start(durationMinutes = 10, preparationTimeSeconds = 0)
        sut.startRunning()

        // When
        sut.completeTimer()

        // Then
        val timer = sut.timerFlow.first()
        assertEquals(TimerState.Completed, timer.state)
    }
}
