package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [TrimZoomWindow] — pure zoom-window math (shared-108).
 *
 * Mirrors iOS: the span is 18 % of the file (at least 120 s), `frame` places a mark
 * ~25 % from its near edge, `pan` recenters. All values in milliseconds (Android).
 */
class TrimZoomWindowTest {
    @Nested
    inner class ZoomSpan {
        @Test
        fun `is eighteen percent of the file for long files`() {
            // 60 min file: 18 % = 648 s = 648_000 ms.
            assertEquals(648_000L, TrimZoomWindow.zoomSpan(3_600_000L))
        }

        @Test
        fun `is at least the minimum span for medium files`() {
            // 10 min file: 18 % = 108 s < 120 s minimum -> 120_000 ms.
            assertEquals(120_000L, TrimZoomWindow.zoomSpan(600_000L))
        }

        @Test
        fun `never exceeds the file duration for short files`() {
            assertEquals(90_000L, TrimZoomWindow.zoomSpan(90_000L))
        }
    }

    @Nested
    inner class Framing {
        @Test
        fun `places a start mark roughly twenty-five percent from the left edge`() {
            val duration = 600_000L // span = 120_000
            val window = TrimZoomWindow.frame(120_000L, TrimPoint.START, duration)

            // lower = mark - span * 0.25 = 120_000 - 30_000 = 90_000.
            assertEquals(90_000L, window.first)
            assertEquals(210_000L, window.last)
        }

        @Test
        fun `places an end mark roughly twenty-five percent from the right edge`() {
            val duration = 600_000L // span = 120_000
            val window = TrimZoomWindow.frame(400_000L, TrimPoint.END, duration)

            // upper = mark + span * 0.25 = 400_000 + 30_000 = 430_000.
            assertEquals(310_000L, window.first)
            assertEquals(430_000L, window.last)
        }

        @Test
        fun `clamps the start window to the file start`() {
            val duration = 600_000L
            val window = TrimZoomWindow.frame(10_000L, TrimPoint.START, duration)

            assertEquals(0L, window.first)
            assertEquals(120_000L, window.last)
        }

        @Test
        fun `clamps the end window to the file end`() {
            val duration = 600_000L
            val window = TrimZoomWindow.frame(595_000L, TrimPoint.END, duration)

            assertEquals(480_000L, window.first)
            assertEquals(600_000L, window.last)
        }

        @Test
        fun `returns the whole file when it is no longer than the span`() {
            val window = TrimZoomWindow.frame(50_000L, TrimPoint.START, 100_000L)

            assertEquals(0L, window.first)
            assertEquals(100_000L, window.last)
        }
    }

    @Nested
    inner class Panning {
        @Test
        fun `centers the window on the given point`() {
            val duration = 600_000L // span = 120_000
            val window = TrimZoomWindow.pan(300_000L, duration)

            assertEquals(240_000L, window.first)
            assertEquals(360_000L, window.last)
        }

        @Test
        fun `clamps the pan window to the file bounds`() {
            val duration = 600_000L
            val window = TrimZoomWindow.pan(0L, duration)

            assertEquals(0L, window.first)
            assertEquals(120_000L, window.last)
        }

        @Test
        fun `returns the whole file when it is no longer than the span`() {
            val window = TrimZoomWindow.pan(50_000L, 100_000L)

            assertEquals(0L, window.first)
            assertEquals(100_000L, window.last)
        }

        @Test
        fun `never produces a negative window for a zero-length file`() {
            val window = TrimZoomWindow.pan(0L, 0L)

            assertTrue(window.first <= window.last)
        }
    }
}
