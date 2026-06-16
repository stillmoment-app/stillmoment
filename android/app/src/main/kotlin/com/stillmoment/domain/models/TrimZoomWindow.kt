package com.stillmoment.domain.models

import kotlin.math.roundToLong

/**
 * Pure functions computing the visible time window of the zoomed trim editor (shared-108).
 *
 * The window is UI state (lives in `TrimEditorViewModel`), deliberately kept out of the
 * domain's [TrimEditorState]. The span scales with the file (18 %, at least 120 s),
 * [frame] places a mark ~25 % from its near edge, [pan] recenters. For files no longer
 * than the span every function returns the whole file — there is effectively no zoom.
 *
 * All values are in milliseconds (Android), where iOS uses seconds. Windows are returned
 * as [LongRange] (a `ClosedRange<Long>`).
 */
object TrimZoomWindow {
    private const val MINIMUM_SPAN_MS = 120_000L
    private const val SPAN_FRACTION = 0.18

    /** Fraction of the span between the framed mark and its near window edge. */
    private const val MARK_EDGE_FRACTION = 0.25

    /**
     * Width (ms) of the zoom window for a file of the given duration: 18 % of the file,
     * at least 120 s, never more than the file itself.
     */
    fun zoomSpan(duration: Long): Long {
        val eighteenPercent = (duration * SPAN_FRACTION).roundToLong()
        return minOf(duration, maxOf(MINIMUM_SPAN_MS, eighteenPercent))
    }

    /**
     * Frames a mark in a zoom window, placing it ~25 % from its near edge (start: left
     * edge, end: right edge). Clamped into `[0, duration]`.
     */
    fun frame(around: Long, point: TrimPoint, duration: Long): LongRange {
        val span = zoomSpan(duration)
        if (duration <= span) {
            return 0L..maxOf(duration, 0L)
        }
        return when (point) {
            TrimPoint.START -> {
                val lower = (around - (span * MARK_EDGE_FRACTION).roundToLong())
                    .coerceIn(0L, duration - span)
                lower..(lower + span)
            }
            TrimPoint.END -> {
                val upper = (around + (span * MARK_EDGE_FRACTION).roundToLong())
                    .coerceIn(span, duration)
                (upper - span)..upper
            }
        }
    }

    /**
     * Moves the zoom window so it is centered on [toCenter], keeping its span.
     * Clamped into `[0, duration]`.
     */
    fun pan(toCenter: Long, duration: Long): LongRange {
        val span = zoomSpan(duration)
        if (duration <= span) {
            return 0L..maxOf(duration, 0L)
        }
        val lower = (toCenter - span / 2).coerceIn(0L, duration - span)
        return lower..(lower + span)
    }
}
