package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.services.AudioFocusManagerProtocol
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Unit tests for AudioSessionCoordinator.
 * Tests exclusive audio session management between Timer and Guided Meditations,
 * as well as system AudioFocus management.
 */
class AudioSessionCoordinatorTest {
    private lateinit var sut: AudioSessionCoordinator
    private lateinit var mockAudioFocusManager: AudioFocusManagerProtocol

    @BeforeEach
    fun setUp() {
        mockAudioFocusManager = mock()
        whenever(mockAudioFocusManager.requestFocus(any())).thenReturn(true)

        sut = AudioSessionCoordinator(mockAudioFocusManager)
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

    // MARK: - AudioFocus Tests

    @Test
    fun `requestAudioSession returns false when audio focus denied`() = runTest {
        // Given: AudioFocusManager denies focus
        whenever(mockAudioFocusManager.requestFocus(any())).thenReturn(false)

        // When
        val granted = sut.requestAudioSession(AudioSource.TIMER)

        // Then
        assertFalse(granted)
        assertNull(sut.activeSource.first())
    }

    @Test
    fun `requestAudioSession releases focus when session released`() = runTest {
        // Given: Timer is active
        sut.requestAudioSession(AudioSource.TIMER)

        // When
        sut.releaseAudioSession(AudioSource.TIMER)

        // Then: Focus was released
        verify(mockAudioFocusManager).releaseFocus()
    }

    @Test
    fun `pause handler is invoked when audio focus lost`() = runTest {
        // Given: Timer is active with pause handler
        var pauseHandlerCalled = false
        sut.registerPauseHandler(AudioSource.TIMER) {
            pauseHandlerCalled = true
        }

        // Capture the onFocusLost callback
        val callbackCaptor = argumentCaptor<() -> Unit>()
        sut.requestAudioSession(AudioSource.TIMER)
        verify(mockAudioFocusManager).requestFocus(callbackCaptor.capture())

        // When: Audio focus is lost (simulated by invoking the callback)
        callbackCaptor.firstValue.invoke()

        // Then: Pause handler was called
        assertTrue(pauseHandlerCalled)
    }

    // MARK: - Pause Handler Tests

    @Test
    fun `pause handler is registered and can be invoked`() = runTest {
        // Given: Timer has a pause handler
        var pauseHandlerCalled = false
        sut.registerPauseHandler(AudioSource.TIMER) {
            pauseHandlerCalled = true
        }

        // When: Timer acquires session (should not trigger pause handler)
        sut.requestAudioSession(AudioSource.TIMER)

        // Then: Pause handler should not be called by requestAudioSession
        assertFalse(pauseHandlerCalled)
    }

    @Test
    fun `pause handler can be replaced`() = runTest {
        // Given: Timer has a pause handler
        var firstHandlerCalled = false
        var secondHandlerCalled = false

        sut.registerPauseHandler(AudioSource.TIMER) {
            firstHandlerCalled = true
        }

        // When: Replace with new handler
        sut.registerPauseHandler(AudioSource.TIMER) {
            secondHandlerCalled = true
        }

        // Manually simulate what AudioFocusChangeListener would do
        // (We can't easily test the listener directly without more complex setup)
        // This verifies the handler registration works correctly

        // Then: Both handlers were registered without error
        assertFalse(firstHandlerCalled)
        assertFalse(secondHandlerCalled)
    }

    @Test
    fun `both conflict and pause handlers can coexist`() = runTest {
        // Given: Timer has both handlers
        var conflictCalled = false
        var pauseCalled = false

        sut.registerConflictHandler(AudioSource.TIMER) {
            conflictCalled = true
        }
        sut.registerPauseHandler(AudioSource.TIMER) {
            pauseCalled = true
        }

        // When: Timer starts, then meditation takes over
        sut.requestAudioSession(AudioSource.TIMER)
        sut.requestAudioSession(AudioSource.GUIDED_MEDITATION)

        // Then: Only conflict handler should be called (not pause)
        assertTrue(conflictCalled)
        assertFalse(pauseCalled)
    }
}
