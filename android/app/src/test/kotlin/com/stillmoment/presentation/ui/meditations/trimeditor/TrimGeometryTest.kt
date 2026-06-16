package com.stillmoment.presentation.ui.meditations.trimeditor

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [TrimGeometry] — the pure time↔x mapping of the trim editor (shared-107/108).
 */
class TrimGeometryTest {
    private val tolerance = 0.01f

    @Nested
    inner class TimeToX {
        @Test
        fun `maps window start to zero`() {
            assertEquals(0f, TrimGeometry.x(0L, 0L..100_000L, 200f), tolerance)
        }

        @Test
        fun `maps window end to full width`() {
            assertEquals(200f, TrimGeometry.x(100_000L, 0L..100_000L, 200f), tolerance)
        }

        @Test
        fun `maps midpoint to half width`() {
            assertEquals(100f, TrimGeometry.x(50_000L, 0L..100_000L, 200f), tolerance)
        }

        @Test
        fun `clamps a time before the window to zero`() {
            assertEquals(0f, TrimGeometry.x(-10_000L, 0L..100_000L, 200f), tolerance)
        }

        @Test
        fun `clamps a time after the window to full width`() {
            assertEquals(200f, TrimGeometry.x(200_000L, 0L..100_000L, 200f), tolerance)
        }

        @Test
        fun `maps relative to a non-zero window`() {
            // Window 40s..60s, time 50s → middle.
            assertEquals(100f, TrimGeometry.x(50_000L, 40_000L..60_000L, 200f), tolerance)
        }

        @Test
        fun `returns zero for an empty window`() {
            assertEquals(0f, TrimGeometry.x(50_000L, 0L..0L, 200f), tolerance)
        }
    }

    @Nested
    inner class UnclampedX {
        @Test
        fun `does not clamp a time before the window`() {
            // Window 40s..60s, time 30s → -100px (outside the track, off-window).
            assertEquals(-100f, TrimGeometry.unclampedX(30_000L, 40_000L..60_000L, 200f), tolerance)
        }

        @Test
        fun `does not clamp a time after the window`() {
            assertEquals(300f, TrimGeometry.unclampedX(70_000L, 40_000L..60_000L, 200f), tolerance)
        }
    }

    @Nested
    inner class XToTime {
        @Test
        fun `maps zero to window start`() {
            assertEquals(0L, TrimGeometry.time(0f, 0L..100_000L, 200f))
        }

        @Test
        fun `maps full width to window end`() {
            assertEquals(100_000L, TrimGeometry.time(200f, 0L..100_000L, 200f))
        }

        @Test
        fun `maps half width to midpoint`() {
            assertEquals(50_000L, TrimGeometry.time(100f, 0L..100_000L, 200f))
        }

        @Test
        fun `clamps an x past the right edge`() {
            assertEquals(100_000L, TrimGeometry.time(500f, 0L..100_000L, 200f))
        }

        @Test
        fun `is the inverse of x within a window`() {
            val window = 40_000L..60_000L
            val x = TrimGeometry.x(52_000L, window, 200f)
            assertEquals(52_000L, TrimGeometry.time(x, window, 200f))
        }
    }

    @Nested
    inner class IsTimeInWindow {
        @Test
        fun `time inside the window counts`() {
            assertTrue(TrimGeometry.isTimeInWindow(50_000L, 40_000L..60_000L))
        }

        @Test
        fun `time at the edge within tolerance counts`() {
            assertTrue(TrimGeometry.isTimeInWindow(39_800L, 40_000L..60_000L))
        }

        @Test
        fun `time well before the window does not count`() {
            assertFalse(TrimGeometry.isTimeInWindow(30_000L, 40_000L..60_000L))
        }

        @Test
        fun `time well after the window does not count`() {
            assertFalse(TrimGeometry.isTimeInWindow(70_000L, 40_000L..60_000L))
        }
    }
}
