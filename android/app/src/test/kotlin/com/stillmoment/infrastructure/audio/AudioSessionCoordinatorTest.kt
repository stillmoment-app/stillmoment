package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.AudioSource
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

/**
 * Unit tests for AudioSessionCoordinator.
 * Tests exclusive audio session management between Timer and Guided Meditations.
 */
class AudioSessionCoordinatorTest {
    private lateinit var sut: AudioSessionCoordinator

    @BeforeEach
    fun setUp() {
        sut = AudioSessionCoordinator()
    }

    // MARK: - Initial State Tests

    @Test
    fun `initial activeSource is null`() = runTest {
        // Given/When: Fresh coordinator
        val activeSource = sut.activeSource.first()

        // Then
        assertNull(activeSource)
    }

    // MARK: - Request Audio Session Tests

    @Test
    fun `requestAudioSession grants access when no active source`() = runTest {
        // Given: No active source

        // When
        val granted = sut.requestAudioSession(AudioSource.TIMER)

        // Then
        assertTrue(granted)
        assertEquals(AudioSource.TIMER, sut.activeSource.first())
    }

    @Test
    fun `requestAudioSession returns true when same source requests again`() = runTest {
        // Given: Timer already active
        sut.requestAudioSession(AudioSource.TIMER)

        // When: Timer requests again
        val granted = sut.requestAudioSession(AudioSource.TIMER)

        // Then
        assertTrue(granted)
        assertEquals(AudioSource.TIMER, sut.activeSource.first())
    }

    @Test
    fun `requestAudioSession grants access to new source replacing current`() = runTest {
        // Given: Timer is active
        sut.requestAudioSession(AudioSource.TIMER)

        // When: Guided meditation requests
        val granted = sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then
        assertTrue(granted)
        assertEquals(AudioSource.GUIDED_MEDITATION, sut.activeSource.first())
    }

    // MARK: - Conflict Handler Tests

    @Test
    fun `conflict handler is invoked when another source requests session`() = runTest {
        // Given: Timer is active with conflict handler
        var conflictHandlerCalled = false
        sut.registerConflictHandler(AudioSource.TIMER) {
            conflictHandlerCalled = true
        }
        sut.requestAudioSession(AudioSource.TIMER)

        // When: Guided meditation requests
        sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then
        assertTrue(conflictHandlerCalled)
    }

    @Test
    fun `conflict handler is not invoked when same source requests`() = runTest {
        // Given: Timer is active with conflict handler
        var conflictHandlerCalled = false
        sut.registerConflictHandler(AudioSource.TIMER) {
            conflictHandlerCalled = true
        }
        sut.requestAudioSession(AudioSource.TIMER)

        // When: Timer requests again
        sut.requestAudioSession(AudioSource.TIMER)

        // Then
        assertFalse(conflictHandlerCalled)
    }

    @Test
    fun `conflict handler is not invoked when no handler registered`() = runTest {
        // Given: Timer is active without conflict handler
        sut.requestAudioSession(AudioSource.TIMER)

        // When: Guided meditation requests (no handler for timer)
        val granted = sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then: Should still grant access
        assertTrue(granted)
        assertEquals(AudioSource.GUIDED_MEDITATION, sut.activeSource.first())
    }

    @Test
    fun `multiple conflict handlers can be registered`() = runTest {
        // Given: Both sources have conflict handlers
        var timerConflictCalled = false
        var meditationConflictCalled = false

        sut.registerConflictHandler(AudioSource.TIMER) {
            timerConflictCalled = true
        }
        sut.registerConflictHandler(AudioSource.GUIDED_MEDITATION) {
            meditationConflictCalled = true
        }

        // When: Timer requests, then meditation requests
        sut.requestAudioSession(AudioSource.TIMER)
        sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then: Only timer's handler should be called
        assertTrue(timerConflictCalled)
        assertFalse(meditationConflictCalled)
    }

    @Test
    fun `conflict handler can be replaced`() = runTest {
        // Given: Timer has a conflict handler
        var firstHandlerCalled = false
        var secondHandlerCalled = false

        sut.registerConflictHandler(AudioSource.TIMER) {
            firstHandlerCalled = true
        }

        // When: Replace with new handler
        sut.registerConflictHandler(AudioSource.TIMER) {
            secondHandlerCalled = true
        }

        sut.requestAudioSession(AudioSource.TIMER)
        sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then: Only second handler should be called
        assertFalse(firstHandlerCalled)
        assertTrue(secondHandlerCalled)
    }

    // MARK: - Release Audio Session Tests

    @Test
    fun `releaseAudioSession clears active source`() = runTest {
        // Given: Timer is active
        sut.requestAudioSession(AudioSource.TIMER)
        assertEquals(AudioSource.TIMER, sut.activeSource.first())

        // When
        sut.releaseAudioSession(AudioSource.TIMER)

        // Then
        assertNull(sut.activeSource.first())
    }

    @Test
    fun `releaseAudioSession does nothing when different source tries to release`() = runTest {
        // Given: Timer is active
        sut.requestAudioSession(AudioSource.TIMER)

        // When: Guided meditation tries to release (but timer is active)
        sut.releaseAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then: Timer should still be active
        assertEquals(AudioSource.TIMER, sut.activeSource.first())
    }

    @Test
    fun `releaseAudioSession does nothing when no active source`() = runTest {
        // Given: No active source

        // When
        sut.releaseAudioSession(AudioSource.TIMER)

        // Then
        assertNull(sut.activeSource.first())
    }

    // MARK: - Integration Scenario Tests

    @Test
    fun `full scenario - timer to meditation handoff`() = runTest {
        // Given: Timer conflict handler that tracks stop
        var timerStopped = false
        sut.registerConflictHandler(AudioSource.TIMER) {
            timerStopped = true
        }

        // When: Timer starts
        sut.requestAudioSession(AudioSource.TIMER)
        assertEquals(AudioSource.TIMER, sut.activeSource.first())

        // When: Meditation requests
        sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then: Timer was notified and meditation is active
        assertTrue(timerStopped)
        assertEquals(AudioSource.GUIDED_MEDITATION, sut.activeSource.first())
    }

    @Test
    fun `full scenario - meditation to timer handoff`() = runTest {
        // Given: Meditation conflict handler
        var meditationStopped = false
        sut.registerConflictHandler(AudioSource.GUIDED_MEDITATION) {
            meditationStopped = true
        }

        // When: Meditation starts
        sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // When: Timer requests
        sut.requestAudioSession(AudioSource.TIMER)

        // Then: Meditation was notified and timer is active
        assertTrue(meditationStopped)
        assertEquals(AudioSource.TIMER, sut.activeSource.first())
    }

    @Test
    fun `full scenario - release and re-acquire`() = runTest {
        // Given: Timer is active
        sut.requestAudioSession(AudioSource.TIMER)

        // When: Timer releases
        sut.releaseAudioSession(AudioSource.TIMER)
        assertNull(sut.activeSource.first())

        // When: Meditation acquires
        sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then
        assertEquals(AudioSource.GUIDED_MEDITATION, sut.activeSource.first())
    }
}
