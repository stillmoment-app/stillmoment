package com.stillmoment.presentation.ui.common

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Structural tests for the Doppel-Lotus-Mandala used on the Danke-Screen
 * (shared-097).
 *
 * Verifiziert wird die Geometrie — Petal-Anzahl pro Ring, 22.5°-Offset
 * zwischen Outer- und Inner-Ring, 45°-Spacing innerhalb der Ringe, Opacities,
 * Bezier-Werte der beiden Petal-Shapes — nicht das Rendering. 1:1 Pendant zu
 * iOS' `DankeLotusMandalaTests.swift`.
 */
class LotusMandalaGeometryTest {

    @Nested
    inner class PetalCounts {

        @Test
        fun `outer ring has eight petals`() {
            assertEquals(8, LotusMandalaGeometry.outerPetalAngles.size)
        }

        @Test
        fun `inner ring has eight petals`() {
            assertEquals(8, LotusMandalaGeometry.innerPetalAngles.size)
        }
    }

    @Nested
    inner class AngleLayout {

        @Test
        fun `outer petals start at zero degrees`() {
            assertEquals(0.0f, LotusMandalaGeometry.outerPetalAngles.first(), 0.001f)
        }

        @Test
        fun `inner petals start at 22 point 5 degrees`() {
            assertEquals(22.5f, LotusMandalaGeometry.innerPetalAngles.first(), 0.001f)
        }

        @Test
        fun `adjacent outer angles differ by 45 degrees`() {
            val angles = LotusMandalaGeometry.outerPetalAngles
            for (index in 1 until angles.size) {
                assertEquals(45.0f, angles[index] - angles[index - 1], 0.001f)
            }
        }

        @Test
        fun `adjacent inner angles differ by 45 degrees`() {
            val angles = LotusMandalaGeometry.innerPetalAngles
            for (index in 1 until angles.size) {
                assertEquals(45.0f, angles[index] - angles[index - 1], 0.001f)
            }
        }
    }

    @Nested
    inner class Opacities {

        @Test
        fun `inner petal opacity is six tenths`() {
            // Spec: Inner-Petals haben opacity 0.6 (Handoff README)
            assertEquals(0.6f, LotusMandalaGeometry.innerPetalOpacity, 0.001f)
        }

        @Test
        fun `center ring opacity is half`() {
            // Spec: Outline-Ring opacity 0.5 (Handoff README)
            assertEquals(0.5f, LotusMandalaGeometry.centerRingOpacity, 0.001f)
        }
    }

    @Nested
    inner class PetalShapes {

        @Test
        fun `outer petal shape matches handoff values`() {
            // Bezier-Werte aus dem Handoff/iOS uebernommen — beide Plattformen
            // zeigen identisches Mandala.
            assertEquals(
                LotusPetalShape(
                    tipY = -72f,
                    bellyX = 10f,
                    bellyHigh = -54f,
                    bellyLow = -32f,
                    baseY = -22f
                ),
                LotusPetalShape.OUTER
            )
        }

        @Test
        fun `inner petal shape matches handoff values`() {
            assertEquals(
                LotusPetalShape(
                    tipY = -42f,
                    bellyX = 7f,
                    bellyHigh = -32f,
                    bellyLow = -18f,
                    baseY = -10f
                ),
                LotusPetalShape.INNER
            )
        }
    }
}
