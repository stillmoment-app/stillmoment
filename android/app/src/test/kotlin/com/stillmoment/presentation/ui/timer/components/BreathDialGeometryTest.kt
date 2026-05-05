package com.stillmoment.presentation.ui.timer.components

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Pure-function tests for the BreathDial picker (shared-086 / shared-089).
 *
 * 1:1 Pendant zu BreathDialGeometryTests.swift — gleiche Werte, gleiche
 * Edge-Cases (12-Uhr-Snap, Wraparound, Clamping, Bogen-Skala 1..60).
 */
class BreathDialGeometryTest {

    private val centerX = 100f
    private val centerY = 100f
    private val ringRadius = 92f

    @Nested
    inner class ValueFromPoint {

        @Test
        fun `three o'clock maps to 15 minutes`() {
            val value = BreathDialGeometry.valueFromPoint(
                pointX = centerX + ringRadius,
                pointY = centerY,
                centerX = centerX,
                centerY = centerY
            )
            assertEquals(15, value)
        }

        @Test
        fun `six o'clock maps to 30 minutes`() {
            val value = BreathDialGeometry.valueFromPoint(
                pointX = centerX,
                pointY = centerY + ringRadius,
                centerX = centerX,
                centerY = centerY
            )
            assertEquals(30, value)
        }

        @Test
        fun `nine o'clock maps to 45 minutes`() {
            val value = BreathDialGeometry.valueFromPoint(
                pointX = centerX - ringRadius,
                pointY = centerY,
                centerX = centerX,
                centerY = centerY
            )
            assertEquals(45, value)
        }

        @Test
        fun `eleven o'clock maps to 55 minutes`() {
            val angleFromTop = -30.0 * PI / 180.0
            val value = BreathDialGeometry.valueFromPoint(
                pointX = centerX + (sin(angleFromTop) * ringRadius).toFloat(),
                pointY = centerY - (cos(angleFromTop) * ringRadius).toFloat(),
                centerX = centerX,
                centerY = centerY
            )
            assertEquals(55, value)
        }

        @Test
        fun `one o'clock maps to 5 minutes`() {
            val angleFromTop = 30.0 * PI / 180.0
            val value = BreathDialGeometry.valueFromPoint(
                pointX = centerX + (sin(angleFromTop) * ringRadius).toFloat(),
                pointY = centerY - (cos(angleFromTop) * ringRadius).toFloat(),
                centerX = centerX,
                centerY = centerY
            )
            assertEquals(5, value)
        }

        @Test
        fun `twelve o'clock snaps to one`() {
            val value = BreathDialGeometry.valueFromPoint(
                pointX = centerX,
                pointY = centerY - ringRadius,
                centerX = centerX,
                centerY = centerY
            )
            assertEquals(1, value)
        }

        @Test
        fun `value right before twelve reaches sixty`() {
            val angleFromTop = -1.0 * PI / 180.0
            val value = BreathDialGeometry.valueFromPoint(
                pointX = centerX + (sin(angleFromTop) * ringRadius).toFloat(),
                pointY = centerY - (cos(angleFromTop) * ringRadius).toFloat(),
                centerX = centerX,
                centerY = centerY
            )
            assertEquals(60, value)
        }
    }

    @Nested
    inner class ClampValue {

        @Test
        fun `clamps high values to sixty`() {
            assertEquals(60, BreathDialGeometry.clampValue(75))
        }

        @Test
        fun `clamps low values to one`() {
            assertEquals(1, BreathDialGeometry.clampValue(-3))
        }

        @Test
        fun `lets valid values through`() {
            assertEquals(18, BreathDialGeometry.clampValue(18))
        }
    }

    @Nested
    inner class ArcProgress {

        @Test
        fun `value thirty fills half the arc`() {
            assertEquals(0.5, BreathDialGeometry.arcProgress(30), 0.0001)
        }

        @Test
        fun `value one is one sixtieth`() {
            assertEquals(1.0 / 60.0, BreathDialGeometry.arcProgress(1), 0.0001)
        }

        @Test
        fun `value sixty fills the full arc`() {
            assertEquals(1.0, BreathDialGeometry.arcProgress(60), 0.0001)
        }
    }

    @Nested
    inner class DropletPosition {

        @Test
        fun `value zero positions droplet at twelve o'clock`() {
            val (x, y) = BreathDialGeometry.dropletPosition(
                value = 0,
                centerX = centerX,
                centerY = centerY,
                radius = ringRadius
            )
            assertEquals(centerX, x, 0.001f)
            assertEquals(centerY - ringRadius, y, 0.001f)
        }

        @Test
        fun `value fifteen positions droplet at three o'clock`() {
            val (x, y) = BreathDialGeometry.dropletPosition(
                value = 15,
                centerX = centerX,
                centerY = centerY,
                radius = ringRadius
            )
            assertEquals(centerX + ringRadius, x, 0.001f)
            assertEquals(centerY, y, 0.001f)
        }

        @Test
        fun `value thirty positions droplet at six o'clock`() {
            val (x, y) = BreathDialGeometry.dropletPosition(
                value = 30,
                centerX = centerX,
                centerY = centerY,
                radius = ringRadius
            )
            assertEquals(centerX, x, 0.001f)
            assertEquals(centerY + ringRadius, y, 0.001f)
        }
    }
}
