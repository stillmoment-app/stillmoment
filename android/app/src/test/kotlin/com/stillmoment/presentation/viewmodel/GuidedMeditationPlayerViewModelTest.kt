package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.GuidedMeditation
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for PlayerUiState.
 * Tests the pure data class logic without ViewModel dependencies.
 */
class GuidedMeditationPlayerViewModelTest {
    // MARK: - Initial State Tests

    @Nested
    inner class InitialState {
        @Test
        fun `initial state has correct default values`() {
            val state = PlayerUiState()

            assertNull(state.meditation)
            assertFalse(state.isPlaying)
            assertEquals(0L, state.currentPosition)
            assertEquals(0L, state.duration)
            assertEquals(0f, state.progress)
            assertNull(state.error)
            assertFalse(state.isCompleted)
        }
    }

    // MARK: - formattedPosition Tests

    @Nested
    inner class FormattedPositionTests {
        @Test
        fun `formats zero position correctly`() {
            val state = PlayerUiState(currentPosition = 0L)

            assertEquals("0:00", state.formattedPosition)
        }

        @Test
        fun `formats position under one minute correctly`() {
            val state = PlayerUiState(currentPosition = 45_000L) // 45 seconds

            assertEquals("0:45", state.formattedPosition)
        }

        @Test
        fun `formats position with leading zeros for seconds`() {
            val state = PlayerUiState(currentPosition = 65_000L) // 1:05

            assertEquals("1:05", state.formattedPosition)
        }

        @Test
        fun `formats position under one hour correctly`() {
            val state = PlayerUiState(currentPosition = 630_000L) // 10:30

            assertEquals("10:30", state.formattedPosition)
        }

        @Test
        fun `formats position over one hour correctly`() {
            val state = PlayerUiState(currentPosition = 5_130_000L) // 1:25:30

            assertEquals("1:25:30", state.formattedPosition)
        }

        @Test
        fun `formats negative position as zero`() {
            val state = PlayerUiState(currentPosition = -1000L)

            assertEquals("0:00", state.formattedPosition)
        }
    }

    // MARK: - formattedDuration Tests

    @Nested
    inner class FormattedDurationTests {
        @Test
        fun `formats duration correctly`() {
            val state = PlayerUiState(duration = 1_800_000L) // 30 minutes

            assertEquals("30:00", state.formattedDuration)
        }

        @Test
        fun `formats hour-long duration correctly`() {
            val state = PlayerUiState(duration = 3_661_000L) // 1:01:01

            assertEquals("1:01:01", state.formattedDuration)
        }
    }

    // MARK: - formattedRemaining Tests

    @Nested
    inner class FormattedRemainingTests {
        @Test
        fun `calculates remaining time correctly`() {
            val state =
                PlayerUiState(
                    currentPosition = 60_000L, // 1 minute
                    duration = 300_000L, // 5 minutes
                )

            assertEquals("4:00", state.formattedRemaining)
        }

        @Test
        fun `remaining time is zero at completion`() {
            val state =
                PlayerUiState(
                    currentPosition = 300_000L,
                    duration = 300_000L,
                )

            assertEquals("0:00", state.formattedRemaining)
        }

        @Test
        fun `handles negative remaining gracefully`() {
            val state =
                PlayerUiState(
                    currentPosition = 400_000L, // Over duration
                    duration = 300_000L,
                )

            // Should show 0:00, not negative
            assertEquals("0:00", state.formattedRemaining)
        }
    }

    // MARK: - Progress Tests

    @Nested
    inner class ProgressTests {
        @Test
        fun `progress is zero at start`() {
            val state =
                PlayerUiState(
                    currentPosition = 0L,
                    duration = 300_000L,
                )

            assertEquals(0f, state.progress)
        }

        @Test
        fun `progress is one at completion`() {
            val state =
                PlayerUiState(
                    currentPosition = 300_000L,
                    duration = 300_000L,
                    progress = 1f,
                )

            assertEquals(1f, state.progress)
        }

        @Test
        fun `progress is half at halfway`() {
            val state =
                PlayerUiState(
                    currentPosition = 150_000L,
                    duration = 300_000L,
                    progress = 0.5f,
                )

            assertEquals(0.5f, state.progress)
        }
    }

    // MARK: - State Copy Tests

    @Nested
    inner class StateCopyTests {
        @Test
        fun `copy preserves unchanged values`() {
            val meditation = createTestMeditation()
            val original =
                PlayerUiState(
                    meditation = meditation,
                    isPlaying = true,
                    currentPosition = 60_000L,
                    duration = 300_000L,
                    progress = 0.2f,
                )

            val updated = original.copy(currentPosition = 120_000L)

            assertEquals(original.meditation, updated.meditation)
            assertEquals(original.isPlaying, updated.isPlaying)
            assertEquals(120_000L, updated.currentPosition)
            assertEquals(original.duration, updated.duration)
            assertEquals(original.progress, updated.progress)
        }

        @Test
        fun `copy with new playing state updates isPlaying`() {
            val playing = PlayerUiState(isPlaying = true)
            assertTrue(playing.isPlaying)

            val paused = playing.copy(isPlaying = false)
            assertFalse(paused.isPlaying)
        }
    }

    // MARK: - Meditation Loading Tests

    @Nested
    inner class MeditationLoadingTests {
        @Test
        fun `loaded meditation state has correct values`() {
            val meditation =
                createTestMeditation(
                    name = "Test Meditation",
                    duration = 600_000L,
                )

            val state =
                PlayerUiState(
                    meditation = meditation,
                    duration = meditation.duration,
                    currentPosition = 0L,
                    progress = 0f,
                    isPlaying = false,
                )

            assertNotNull(state.meditation)
            assertEquals("Test Meditation", state.meditation?.name)
            assertEquals(600_000L, state.duration)
            assertFalse(state.isPlaying)
        }
    }

    // MARK: - Playback State Tests

    @Nested
    inner class PlaybackStateTests {
        @Test
        fun `playing state`() {
            val state =
                PlayerUiState(
                    isPlaying = true,
                    currentPosition = 30_000L,
                    duration = 300_000L,
                    progress = 0.1f,
                )

            assertTrue(state.isPlaying)
            assertFalse(state.isCompleted)
        }

        @Test
        fun `paused state`() {
            val state =
                PlayerUiState(
                    isPlaying = false,
                    currentPosition = 150_000L,
                    duration = 300_000L,
                    progress = 0.5f,
                )

            assertFalse(state.isPlaying)
            assertFalse(state.isCompleted)
        }

        @Test
        fun `completed state`() {
            val state =
                PlayerUiState(
                    isPlaying = false,
                    isCompleted = true,
                    currentPosition = 300_000L,
                    duration = 300_000L,
                    progress = 1f,
                )

            assertFalse(state.isPlaying)
            assertTrue(state.isCompleted)
            assertEquals(1f, state.progress)
        }
    }

    // MARK: - Error State Tests

    @Nested
    inner class ErrorStateTests {
        @Test
        fun `error state can be set`() {
            val state = PlayerUiState(error = "Playback error")

            assertNotNull(state.error)
            assertEquals("Playback error", state.error)
        }

        @Test
        fun `error state can be cleared`() {
            val withError = PlayerUiState(error = "Error")
            val cleared = withError.copy(error = null)

            assertNull(cleared.error)
        }
    }

    // MARK: - Edge Case Tests

    @Nested
    inner class EdgeCaseTests {
        @Test
        fun `handles zero duration gracefully`() {
            val state =
                PlayerUiState(
                    currentPosition = 0L,
                    duration = 0L,
                    progress = 0f,
                )

            assertEquals("0:00", state.formattedDuration)
            assertEquals("0:00", state.formattedPosition)
            assertEquals("0:00", state.formattedRemaining)
        }

        @Test
        fun `handles very long duration`() {
            val state =
                PlayerUiState(
                    currentPosition = 0L,
                    duration = 36_000_000L, // 10 hours
                )

            assertEquals("10:00:00", state.formattedDuration)
            assertEquals("10:00:00", state.formattedRemaining)
        }
    }

    // MARK: - Test Helpers

    private fun createTestMeditation(
        id: String = java.util.UUID.randomUUID().toString(),
        name: String = "Test Meditation",
        teacher: String = "Test Teacher",
        duration: Long = 600_000L,
    ): GuidedMeditation = GuidedMeditation(
        id = id,
        fileUri = "content://test/uri",
        fileName = "test.mp3",
        duration = duration,
        teacher = teacher,
        name = name,
    )
}
