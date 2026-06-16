package com.stillmoment.presentation.ui.meditations.components

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [PlayheadWindowGeometry] — the pure sec/ms ↔ x mapping of the scrolling
 * "Tonkopf" window (shared-109). 1:1 behaviour port of iOS `PlayheadWindowGeometry`, but in
 * range-relative milliseconds (0 = trim start), matching the Android player's UI state.
 */
class PlayheadWindowGeometryTest {
    private val windowSec = 60.0
    private val width = 360f

    @Nested
    inner class PxPerSec {
        @Test
        fun `density is width divided by window seconds`() {
            assertEquals(6.0, PlayheadWindowGeometry.pxPerSec(windowSec, width), 0.0001)
        }

        @Test
        fun `zero window yields zero density`() {
            assertEquals(0.0, PlayheadWindowGeometry.pxPerSec(0.0, width), 0.0001)
        }

        @Test
        fun `zero width yields zero density`() {
            assertEquals(0.0, PlayheadWindowGeometry.pxPerSec(windowSec, 0f), 0.0001)
        }
    }

    @Nested
    inner class XForMs {
        @Test
        fun `now maps to the screen center`() {
            val x = PlayheadWindowGeometry.xForMs(nowMs = 30_000L, ms = 30_000L, windowSec, width)
            assertEquals(180f, x, 0.01f)
        }

        @Test
        fun `future time is right of center`() {
            // 10 s ahead at 6 px/s → +60 px from center.
            val x = PlayheadWindowGeometry.xForMs(nowMs = 30_000L, ms = 40_000L, windowSec, width)
            assertEquals(240f, x, 0.01f)
        }

        @Test
        fun `past time is left of center`() {
            val x = PlayheadWindowGeometry.xForMs(nowMs = 30_000L, ms = 20_000L, windowSec, width)
            assertEquals(120f, x, 0.01f)
        }
    }

    @Nested
    inner class MsForX {
        @Test
        fun `center maps back to now`() {
            val ms = PlayheadWindowGeometry.msForX(180f, nowMs = 30_000L, windowSec, width)
            assertEquals(30_000L, ms)
        }

        @Test
        fun `xForMs and msForX round-trip`() {
            val x = PlayheadWindowGeometry.xForMs(nowMs = 30_000L, ms = 42_000L, windowSec, width)
            val ms = PlayheadWindowGeometry.msForX(x, nowMs = 30_000L, windowSec, width)
            assertEquals(42_000L, ms)
        }
    }

    @Nested
    inner class DraggedNow {
        private val bounds = 0L..120_000L

        @Test
        fun `dragging left moves the position forward`() {
            // -60 px at 6 px/s = -10 s translation → +10 s forward.
            val result = PlayheadWindowGeometry.draggedNow(
                startNowMs = 30_000L,
                translationPx = -60f,
                windowSec = windowSec,
                width = width,
                bounds = bounds
            )
            assertEquals(40_000L, result)
        }

        @Test
        fun `dragging right moves the position backward`() {
            val result = PlayheadWindowGeometry.draggedNow(
                startNowMs = 30_000L,
                translationPx = 60f,
                windowSec = windowSec,
                width = width,
                bounds = bounds
            )
            assertEquals(20_000L, result)
        }

        @Test
        fun `clamps to the upper bound`() {
            val result = PlayheadWindowGeometry.draggedNow(
                startNowMs = 110_000L,
                translationPx = -6000f, // way past the end
                windowSec = windowSec,
                width = width,
                bounds = bounds
            )
            assertEquals(120_000L, result)
        }

        @Test
        fun `clamps to the lower bound`() {
            val result = PlayheadWindowGeometry.draggedNow(
                startNowMs = 10_000L,
                translationPx = 6000f, // way before the start
                windowSec = windowSec,
                width = width,
                bounds = bounds
            )
            assertEquals(0L, result)
        }

        @Test
        fun `zero density returns the clamped start`() {
            val result = PlayheadWindowGeometry.draggedNow(
                startNowMs = 200_000L,
                translationPx = -50f,
                windowSec = 0.0,
                width = width,
                bounds = bounds
            )
            assertTrue(result == 120_000L)
        }
    }
}
