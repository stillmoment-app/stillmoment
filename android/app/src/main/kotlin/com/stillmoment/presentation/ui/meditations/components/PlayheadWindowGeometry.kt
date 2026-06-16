package com.stillmoment.presentation.ui.meditations.components

import kotlin.math.roundToLong

/**
 * Pure, unit-testable mapping for the waveform player's scrolling "Tonkopf" window
 * (shared-109). 1:1 behaviour port of iOS `PlayheadWindowGeometry`, but in range-relative
 * milliseconds (0 = trim start) — the unit the Android player's UI state already uses.
 *
 * Unlike [com.stillmoment.presentation.ui.meditations.trimeditor.TrimGeometry] (a static
 * `[0, duration]` or fixed zoom window), this window *glides*: it stays centered on `now`, so
 * the current position is always at the screen center (the fixed "now"-line). For any
 * screen-x: `ms = now + (x − center) / pxPerSec`. Times left of center are in the past, right
 * in the future. Rendering leaves x/ms unclamped (off-track bars are simply skipped); only the
 * drag result is clamped into the playable bounds.
 */
object PlayheadWindowGeometry {
    /** Horizontal density: how many pixels one second of audio occupies. */
    fun pxPerSec(windowSec: Double, width: Float): Double {
        if (windowSec <= 0.0 || width <= 0f) {
            return 0.0
        }
        return width / windowSec
    }

    /**
     * Maps an absolute (range-relative) time to a screen-x in a window centered on [nowMs].
     * Not clamped — callers skip bars that fall outside `[0, width]`.
     */
    fun xForMs(nowMs: Long, ms: Long, windowSec: Double, width: Float): Float {
        val center = width / 2.0
        val density = pxPerSec(windowSec, width)
        return (center + (ms - nowMs) / 1000.0 * density).toFloat()
    }

    /** Maps a screen-x back to a (range-relative) time in a window centered on [nowMs]. */
    fun msForX(x: Float, nowMs: Long, windowSec: Double, width: Float): Long {
        val center = width / 2.0
        val density = pxPerSec(windowSec, width)
        if (density <= 0.0) {
            return nowMs
        }
        return nowMs + ((x - center) / density * 1000.0).roundToLong()
    }

    /**
     * Maps a drag translation to a new position, anchored at [startNowMs].
     *
     * Dragging the wave LEFT (negative translation) moves the position FORWARD, dragging RIGHT
     * moves it BACKWARD — the band scrolls under a fixed playhead. The result is clamped into
     * [bounds] (the trimmed playable range), so the player never scrubs past the trim edges.
     * [translationPx] is the cumulative drag translation, so it is always applied to the fixed
     * [startNowMs], never to an already-moved position.
     */
    fun draggedNow(startNowMs: Long, translationPx: Float, windowSec: Double, width: Float, bounds: LongRange): Long {
        val density = pxPerSec(windowSec, width)
        if (density <= 0.0) {
            return startNowMs.coerceIn(bounds.first, bounds.last)
        }
        val proposed = startNowMs - (translationPx / density * 1000.0).roundToLong()
        return proposed.coerceIn(bounds.first, bounds.last)
    }
}
