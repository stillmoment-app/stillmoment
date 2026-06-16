package com.stillmoment.presentation.ui.meditations.trimeditor

import com.stillmoment.domain.models.TrimPoint
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [TrimHitTesting] — the geometric drag resolution of the trim track (shared-107).
 */
class TrimHitTestingTest {
    private val height = 108f
    private val grabRadius = TrimHitTesting.GRAB_RADIUS_DP // treat dp == px for the test math
    private val tolerance = 0.01f

    private fun geometry(headX: Float = 100f, startX: Float = 40f, endX: Float = 160f) =
        TrimTrackGeometry(waveformHeight = height, headX = headX, startX = startX, endX = endX)

    @Nested
    inner class PlayheadZone {
        @Test
        fun `touch in upper zone near the head grabs the playhead with offset`() {
            val session = TrimHitTesting.beginDrag(
                touchX = 110f,
                touchY = 10f,
                geometry = geometry(headX = 100f),
                activePoint = TrimPoint.START,
                grabRadiusPx = grabRadius
            )
            assertEquals(TrimDragTarget.Playhead, session.target)
            assertEquals(-10f, session.offset, tolerance)
        }

        @Test
        fun `touch in upper zone far from the head grabs the playhead with zero offset`() {
            val session = TrimHitTesting.beginDrag(
                touchX = 10f,
                touchY = 10f,
                geometry = geometry(headX = 100f),
                activePoint = TrimPoint.START,
                grabRadiusPx = grabRadius
            )
            assertEquals(TrimDragTarget.Playhead, session.target)
            assertEquals(0f, session.offset, tolerance)
        }

        @Test
        fun `boundary just above the split is still the playhead`() {
            val justAbove = height * TrimHitTesting.VERTICAL_SPLIT - 1f
            val session = TrimHitTesting.beginDrag(
                touchX = 50f,
                touchY = justAbove,
                geometry = geometry(),
                activePoint = TrimPoint.START,
                grabRadiusPx = grabRadius
            )
            assertEquals(TrimDragTarget.Playhead, session.target)
        }
    }

    @Nested
    inner class MarkZone {
        private val lowerY = height * 0.8f

        @Test
        fun `direct grab on the start mark wins`() {
            val session = TrimHitTesting.beginDrag(
                touchX = 45f,
                touchY = lowerY,
                geometry = geometry(startX = 40f, endX = 160f),
                activePoint = TrimPoint.END,
                grabRadiusPx = grabRadius
            )
            assertEquals(TrimDragTarget.Mark(TrimPoint.START), session.target)
            assertEquals(-5f, session.offset, tolerance)
        }

        @Test
        fun `direct grab on the end mark wins`() {
            val session = TrimHitTesting.beginDrag(
                touchX = 158f,
                touchY = lowerY,
                geometry = geometry(startX = 40f, endX = 160f),
                activePoint = TrimPoint.START,
                grabRadiusPx = grabRadius
            )
            assertEquals(TrimDragTarget.Mark(TrimPoint.END), session.target)
            assertEquals(2f, session.offset, tolerance)
        }

        @Test
        fun `cluster gives the active mark`() {
            // Both marks within grab radius of the touch — active (end) wins.
            val session = TrimHitTesting.beginDrag(
                touchX = 100f,
                touchY = lowerY,
                geometry = geometry(startX = 95f, endX = 105f),
                activePoint = TrimPoint.END,
                grabRadiusPx = grabRadius
            )
            assertEquals(TrimDragTarget.Mark(TrimPoint.END), session.target)
            assertEquals(5f, session.offset, tolerance)
        }

        @Test
        fun `free area moves the active mark with zero offset`() {
            val session = TrimHitTesting.beginDrag(
                touchX = 100f,
                touchY = lowerY,
                geometry = geometry(startX = 10f, endX = 200f),
                activePoint = TrimPoint.START,
                grabRadiusPx = grabRadius
            )
            assertEquals(TrimDragTarget.Mark(TrimPoint.START), session.target)
            assertEquals(0f, session.offset, tolerance)
        }
    }
}
