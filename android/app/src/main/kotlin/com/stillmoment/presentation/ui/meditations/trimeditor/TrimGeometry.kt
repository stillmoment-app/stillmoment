package com.stillmoment.presentation.ui.meditations.trimeditor

import kotlin.math.roundToLong

/**
 * Pure, unit-testable mapping between a time value (ms) and an x-coordinate (px)
 * inside the waveform track (shared-107/108). Both directions clamp into valid bounds
 * so callers never need to guard against out-of-range drags.
 *
 * 1:1 port of iOS `TrimGeometry`. Times are milliseconds (Long), widths/positions are
 * pixels (Float). Windows are [LongRange] (a `ClosedRange<Long>`).
 */
object TrimGeometry {
    /**
     * Tolerance (ms) within which a time still counts as inside the window — grips
     * sitting right at the window edge stay visible (iOS used 0.5 s).
     */
    const val WINDOW_TOLERANCE_MS = 500L

    /** Maps a time relative to a visible window to an x in `[0, width]` (clamped, for rendering). */
    fun x(time: Long, window: ClosedRange<Long>, width: Float): Float {
        val span = window.endInclusive - window.start
        if (span <= 0L || width <= 0f) {
            return 0f
        }
        val fraction = ((time - window.start).toDouble() / span).coerceIn(0.0, 1.0)
        return (fraction * width).toFloat()
    }

    /**
     * Maps a time to an x relative to a visible window WITHOUT clamping — for hit testing:
     * a mark outside the window lands outside the grab radius automatically, so
     * [TrimHitTesting] needs no window awareness.
     */
    fun unclampedX(time: Long, window: ClosedRange<Long>, width: Float): Float {
        val span = window.endInclusive - window.start
        if (span <= 0L || width <= 0f) {
            return 0f
        }
        return ((time - window.start).toDouble() / span * width).toFloat()
    }

    /** Maps an x in `[0, width]` back to a time, clamped into the window. */
    fun time(x: Float, window: ClosedRange<Long>, width: Float): Long {
        val span = window.endInclusive - window.start
        if (span <= 0L || width <= 0f) {
            return window.start
        }
        val fraction = (x / width).coerceIn(0f, 1f)
        return window.start + (fraction.toDouble() * span).roundToLong()
    }

    /**
     * Whether a time lies inside the visible window (± [WINDOW_TOLERANCE_MS]). Marks and
     * the playhead are only rendered while in the window; an off-window mark shows an edge
     * chip instead.
     */
    fun isTimeInWindow(time: Long, window: ClosedRange<Long>): Boolean =
        time >= window.start - WINDOW_TOLERANCE_MS && time <= window.endInclusive + WINDOW_TOLERANCE_MS
}
