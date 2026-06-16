package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [TrimEditorState] — immutable trim editor selection (shared-107).
 *
 * Mirrors the iOS `TrimEditorState`: start/end clamping with a 25 s minimum range,
 * boundary-tolerant result trim values (null at the file edge), and pure transitions.
 * All values are in milliseconds (Android), where iOS uses seconds.
 */
class TrimEditorStateTest {
    private val tenMinutes = 600_000L

    private fun meditation(duration: Long = tenMinutes, trimStartMs: Long? = null, trimEndMs: Long? = null) =
        GuidedMeditation(
            fileUri = "content://test",
            fileName = "test.mp3",
            duration = duration,
            teacher = "Teacher",
            name = "Name",
            trimStartMs = trimStartMs,
            trimEndMs = trimEndMs
        )

    @Nested
    inner class Initialization {
        @Test
        fun `seeds start and end from the meditation effective bounds`() {
            val state = TrimEditorState.fromMeditation(
                meditation(trimStartMs = 30_000L, trimEndMs = 500_000L)
            )

            assertEquals(30_000L, state.start)
            assertEquals(500_000L, state.end)
            assertEquals(tenMinutes, state.duration)
            assertEquals(TrimPoint.START, state.activePoint)
        }

        @Test
        fun `defaults to the whole file when untrimmed`() {
            val state = TrimEditorState.fromMeditation(meditation())

            assertEquals(0L, state.start)
            assertEquals(tenMinutes, state.end)
        }

        @Test
        fun `keeps the whole file fixed for files shorter than the minimum range`() {
            val state = TrimEditorState.fromMeditation(
                meditation(duration = 10_000L, trimStartMs = 2_000L, trimEndMs = 8_000L)
            )

            assertEquals(0L, state.start)
            assertEquals(10_000L, state.end)
        }
    }

    @Nested
    inner class Moving {
        @Test
        fun `clamps start into zero and end-minus-minimum range`() {
            val state = TrimEditorState.fromMeditation(meditation())

            val moved = state.moving(TrimPoint.START, 700_000L)

            // end is 600_000, minimumRange 25_000 -> start clamped to 575_000.
            assertEquals(575_000L, moved.start)
            assertEquals(TrimPoint.START, moved.activePoint)
        }

        @Test
        fun `clamps start to zero when moved negative`() {
            val state = TrimEditorState.fromMeditation(meditation())

            val moved = state.moving(TrimPoint.START, -5_000L)

            assertEquals(0L, moved.start)
        }

        @Test
        fun `clamps end into start-plus-minimum and duration range`() {
            val state = TrimEditorState.fromMeditation(meditation())
                .moving(TrimPoint.START, 100_000L)

            val moved = state.moving(TrimPoint.END, 110_000L)

            // start is 100_000, minimumRange 25_000 -> end clamped to 125_000.
            assertEquals(125_000L, moved.end)
            assertEquals(TrimPoint.END, moved.activePoint)
        }

        @Test
        fun `clamps end to duration when moved past the file`() {
            val state = TrimEditorState.fromMeditation(meditation())

            val moved = state.moving(TrimPoint.END, 999_999L)

            assertEquals(tenMinutes, moved.end)
        }

        @Test
        fun `is a no-op move for files shorter than the minimum range but still selects`() {
            val state = TrimEditorState.fromMeditation(meditation(duration = 10_000L))

            val moved = state.moving(TrimPoint.END, 1_000L)

            assertEquals(0L, moved.start)
            assertEquals(10_000L, moved.end)
            assertEquals(TrimPoint.END, moved.activePoint)
        }
    }

    @Nested
    inner class Selecting {
        @Test
        fun `changes the active point without moving values`() {
            val state = TrimEditorState.fromMeditation(meditation())

            val selected = state.selecting(TrimPoint.END)

            assertEquals(TrimPoint.END, selected.activePoint)
            assertEquals(state.start, selected.start)
            assertEquals(state.end, selected.end)
        }

        @Test
        fun `active value follows the active point`() {
            val state = TrimEditorState.fromMeditation(
                meditation(trimStartMs = 30_000L, trimEndMs = 500_000L)
            )

            assertEquals(30_000L, state.activeValue)
            assertEquals(500_000L, state.selecting(TrimPoint.END).activeValue)
        }
    }

    @Nested
    inner class Nudging {
        @Test
        fun `nudges the active point through the same clamping as move`() {
            val state = TrimEditorState.fromMeditation(meditation())
                .moving(TrimPoint.START, 100_000L)

            val nudged = state.nudgingActivePoint(1_000L)

            assertEquals(101_000L, nudged.start)
        }

        @Test
        fun `cannot nudge start past the minimum range`() {
            val state = TrimEditorState.fromMeditation(meditation())
                .moving(TrimPoint.START, 575_000L) // already at the limit

            val nudged = state.nudgingActivePoint(5_000L)

            assertEquals(575_000L, nudged.start)
        }
    }

    @Nested
    inner class WholeFile {
        @Test
        fun `resets selection to the full file at the start point`() {
            val state = TrimEditorState.fromMeditation(
                meditation(trimStartMs = 30_000L, trimEndMs = 500_000L)
            )

            val reset = state.usingWholeFile()

            assertEquals(0L, reset.start)
            assertEquals(tenMinutes, reset.end)
            assertEquals(TrimPoint.START, reset.activePoint)
        }
    }

    @Nested
    inner class ResultTrim {
        @Test
        fun `null start and end when the selection sits at the file boundary`() {
            val state = TrimEditorState.fromMeditation(meditation())

            assertNull(state.resultTrimStartMs)
            assertNull(state.resultTrimEndMs)
            assertNull(state.trimResult)
        }

        @Test
        fun `resolves trimmed start and end when moved off the boundary`() {
            val state = TrimEditorState.fromMeditation(meditation())
                .moving(TrimPoint.START, 30_000L)
                .moving(TrimPoint.END, 500_000L)

            assertEquals(30_000L, state.resultTrimStartMs)
            assertEquals(500_000L, state.resultTrimEndMs)
            assertEquals(30_000L to 500_000L, state.trimResult)
        }

        @Test
        fun `treats a point within one second of the edge as the boundary`() {
            val state = TrimEditorState.fromMeditation(meditation())
                .moving(TrimPoint.START, 800L)

            assertNull(state.resultTrimStartMs)
        }
    }
}
