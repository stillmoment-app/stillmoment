package com.stillmoment.domain.services

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for PlaybackState data class.
 */
class PlaybackStateTest {

    // MARK: - Initial State Tests

    @Nested
    inner class InitialState {

        @Test
        fun `default state has correct values`() {
            val state = PlaybackState()

            assertFalse(state.isPlaying)
            assertEquals(0L, state.currentPosition)
            assertEquals(0L, state.duration)
            assertNull(state.error)
        }
    }

    // MARK: - Progress Tests

    @Nested
    inner class ProgressTests {

        @Test
        fun `progress is zero when duration is zero`() {
            val state = PlaybackState(
                currentPosition = 0L,
                duration = 0L
            )

            assertEquals(0f, state.progress)
        }

        @Test
        fun `progress is zero at start`() {
            val state = PlaybackState(
                currentPosition = 0L,
                duration = 300_000L
            )

            assertEquals(0f, state.progress)
        }

        @Test
        fun `progress is one at completion`() {
            val state = PlaybackState(
                currentPosition = 300_000L,
                duration = 300_000L
            )

            assertEquals(1f, state.progress)
        }

        @Test
        fun `progress is half at halfway`() {
            val state = PlaybackState(
                currentPosition = 150_000L,
                duration = 300_000L
            )

            assertEquals(0.5f, state.progress)
        }

        @Test
        fun `progress is quarter at 25 percent`() {
            val state = PlaybackState(
                currentPosition = 75_000L,
                duration = 300_000L
            )

            assertEquals(0.25f, state.progress)
        }

        @Test
        fun `progress handles arbitrary position`() {
            val state = PlaybackState(
                currentPosition = 123_456L,
                duration = 500_000L
            )

            assertEquals(123_456f / 500_000f, state.progress, 0.0001f)
        }
    }

    // MARK: - State Copy Tests

    @Nested
    inner class StateCopyTests {

        @Test
        fun `copy preserves unchanged values`() {
            val original = PlaybackState(
                isPlaying = true,
                currentPosition = 60_000L,
                duration = 300_000L,
                error = null
            )

            val updated = original.copy(currentPosition = 120_000L)

            assertTrue(updated.isPlaying)
            assertEquals(120_000L, updated.currentPosition)
            assertEquals(300_000L, updated.duration)
            assertNull(updated.error)
        }

        @Test
        fun `copy with error sets error`() {
            val original = PlaybackState()
            val withError = original.copy(error = "Test error")

            assertEquals("Test error", withError.error)
        }
    }

    // MARK: - Playback State Transitions

    @Nested
    inner class PlaybackTransitions {

        @Test
        fun `transition from stopped to playing`() {
            val stopped = PlaybackState(isPlaying = false)
            val playing = stopped.copy(isPlaying = true)

            assertFalse(stopped.isPlaying)
            assertTrue(playing.isPlaying)
        }

        @Test
        fun `transition from playing to paused`() {
            val playing = PlaybackState(
                isPlaying = true,
                currentPosition = 60_000L,
                duration = 300_000L
            )
            val paused = playing.copy(isPlaying = false)

            assertTrue(playing.isPlaying)
            assertFalse(paused.isPlaying)
            assertEquals(60_000L, paused.currentPosition) // Position preserved
        }

        @Test
        fun `transition to error state`() {
            val playing = PlaybackState(isPlaying = true)
            val error = playing.copy(
                isPlaying = false,
                error = "Playback failed"
            )

            assertFalse(error.isPlaying)
            assertNotNull(error.error)
        }
    }

    // MARK: - Edge Cases

    @Nested
    inner class EdgeCases {

        @Test
        fun `progress with very small duration`() {
            val state = PlaybackState(
                currentPosition = 1L,
                duration = 1L
            )

            assertEquals(1f, state.progress)
        }

        @Test
        fun `progress with very large values`() {
            val state = PlaybackState(
                currentPosition = 36_000_000L, // 10 hours
                duration = 72_000_000L         // 20 hours
            )

            assertEquals(0.5f, state.progress)
        }
    }
}
