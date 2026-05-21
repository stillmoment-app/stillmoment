package com.stillmoment.presentation.ui.meditations.components

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Pure-function tests fuer die Perlen-Position auf dem Player-Restzeit-Bogen
 * (shared-096).
 *
 * 1:1 Pendant zu iOS' Perlen-Geometrie in `PlayerRingView`. Start bei 12 Uhr,
 * im Uhrzeigersinn wachsend: 0 % → 12 Uhr (oben), 25 % → 3 Uhr, 50 % → 6 Uhr,
 * 75 % → 9 Uhr. Progress wird auf 0..1 geklammert.
 */
class PlayerRingGeometryTest {

    private val outerSize: Float = 280f
    private val stroke: Float = 1.5f

    // radius = (outerSize - stroke) / 2 — die Perle sitzt auf der Mitte des
    // Bogen-Strokes.
    private val expectedRadius: Float = (outerSize - stroke) / 2f

    @Nested
    inner class BeadOffset {

        @Test
        fun `progress zero puts bead at twelve o clock`() {
            // Given: Sitzung gerade gestartet
            // When
            val offset = PlayerRingGeometry.beadOffset(
                progress = 0f,
                outerSize = outerSize,
                stroke = stroke,
            )

            // Then: dx = 0, dy = -radius (12 Uhr, oben)
            assertEquals(0f, offset.x, 0.0001f)
            assertEquals(-expectedRadius, offset.y, 0.0001f)
        }

        @Test
        fun `progress quarter puts bead at three o clock`() {
            // Given: 25 % der Sitzung herum
            // When
            val offset = PlayerRingGeometry.beadOffset(
                progress = 0.25f,
                outerSize = outerSize,
                stroke = stroke,
            )

            // Then: dx = +radius, dy = 0 (3 Uhr, rechts)
            assertEquals(expectedRadius, offset.x, 0.0001f)
            assertEquals(0f, offset.y, 0.0001f)
        }

        @Test
        fun `progress half puts bead at six o clock`() {
            // Given: Halbzeit
            // When
            val offset = PlayerRingGeometry.beadOffset(
                progress = 0.5f,
                outerSize = outerSize,
                stroke = stroke,
            )

            // Then: dx = 0, dy = +radius (6 Uhr, unten)
            assertEquals(0f, offset.x, 0.0001f)
            assertEquals(expectedRadius, offset.y, 0.0001f)
        }

        @Test
        fun `progress three quarters puts bead at nine o clock`() {
            // Given: 75 % der Sitzung herum
            // When
            val offset = PlayerRingGeometry.beadOffset(
                progress = 0.75f,
                outerSize = outerSize,
                stroke = stroke,
            )

            // Then: dx = -radius, dy = 0 (9 Uhr, links)
            assertEquals(-expectedRadius, offset.x, 0.0001f)
            assertEquals(0f, offset.y, 0.0001f)
        }

        @Test
        fun `progress below zero is clamped to zero`() {
            // Given: ungueltiger negativer Progress (Defensiv-Check)
            // When
            val offset = PlayerRingGeometry.beadOffset(
                progress = -0.5f,
                outerSize = outerSize,
                stroke = stroke,
            )

            // Then: wie Progress 0
            assertEquals(0f, offset.x, 0.0001f)
            assertEquals(-expectedRadius, offset.y, 0.0001f)
        }

        @Test
        fun `progress above one is clamped to one`() {
            // Given: ungueltiger Progress > 1 (z.B. nach Drift)
            // When
            val offset = PlayerRingGeometry.beadOffset(
                progress = 1.5f,
                outerSize = outerSize,
                stroke = stroke,
            )

            // Then: wie Progress 1 — Perle wieder bei 12 Uhr (Vollumlauf)
            assertEquals(0f, offset.x, 0.0001f)
            assertEquals(-expectedRadius, offset.y, 0.0001f)
        }
    }
}
