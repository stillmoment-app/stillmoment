package com.stillmoment.presentation.ui.timer.components

import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * Pure helpers for the BreathDial picker (shared-086 / shared-089).
 *
 * No Compose imports — the functions are pure math and unit-testable via
 * plain JUnit. Mirrors iOS BreathDialGeometry so both platforms behave
 * identically (12-o'clock snap, clamp to [1, 60], arc skala 1..60).
 */
object BreathDialGeometry {
    const val MAX_MINUTES: Int = 60
    const val MIN_MINUTES: Int = 1

    /**
     * Maps a touch point (in the same coordinate system as [centerX]/[centerY])
     * to a minute value.
     *
     * - 12 o'clock corresponds to 0 (snapped to [MIN_MINUTES] = 1).
     * - 3 o'clock = 15, 6 o'clock = 30, 9 o'clock = 45.
     * - The arc grows clockwise.
     * - Result is clamped to `[MIN_MINUTES, MAX_MINUTES]`.
     */
    fun valueFromPoint(pointX: Float, pointY: Float, centerX: Float, centerY: Float): Int {
        val dx = pointX - centerX
        val dy = pointY - centerY
        val degrees = atan2(dy.toDouble(), dx.toDouble()) * 180.0 / PI
        var normalized = (degrees + 90.0) % 360.0
        if (normalized < 0.0) {
            normalized += 360.0
        }
        val raw = (normalized / 360.0 * MAX_MINUTES.toDouble()).roundToInt()
        val value = if (raw == 0) MIN_MINUTES else raw
        return clampValue(value)
    }

    /** Clamps a raw minute value to `[MIN_MINUTES, MAX_MINUTES]`. */
    fun clampValue(value: Int): Int = value.coerceIn(MIN_MINUTES, MAX_MINUTES)

    /** Fraction (0..1) for the active arc. */
    fun arcProgress(value: Int): Double = value.toDouble() / MAX_MINUTES.toDouble()

    /**
     * Position of the drag droplet on the ring's middle radius for [value] minutes.
     * 0 corresponds to 12 o'clock, growing clockwise.
     *
     * Returns a [Pair] of (x, y) so this stays Compose-free. Composables convert
     * the pair to `Offset` at the call site.
     */
    fun dropletPosition(value: Int, centerX: Float, centerY: Float, radius: Float): Pair<Float, Float> {
        val progress = value.toDouble() / MAX_MINUTES.toDouble()
        val angleRad = progress * 2.0 * PI - PI / 2.0
        val x = centerX + (cos(angleRad) * radius).toFloat()
        val y = centerY + (sin(angleRad) * radius).toFloat()
        return x to y
    }
}
