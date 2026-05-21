package com.stillmoment.presentation.ui.timer.components

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Pure-function tests fuer die Mondphasen-Animation (shared-095).
 *
 * 1:1 Pendant zu MoonPhaseGeometryTests.swift — gleiche Werte, gleiche
 * Edge-Cases (Neumond, Halbmond, Vollmond, Clamp unten, Clamp oben).
 * AK: Bei Halbzeit muss die Schattenkante senkrecht in der Mondmitte
 * stehen — also exakt der Halbmond.
 */
class MoonPhaseGeometryTest {

    private val outerSize: Float = 220f

    @Nested
    inner class ShadowOffset {

        @Test
        fun `neumond at progress zero leaves shadow centered on moon`() {
            // Given: Sitzung gerade gestartet
            // When
            val offset = MoonPhaseGeometry.shadowOffset(progress = 0f, outerSize = outerSize)

            // Then: Schatten deckt Mond exakt — Schatten-Mitte bei x = 0
            assertEquals(0f, offset, 0.0001f)
        }

        @Test
        fun `halbmond at halftime puts shadow edge through moon center`() {
            // Given: Halbzeit einer Sitzung
            // When
            val offset = MoonPhaseGeometry.shadowOffset(progress = 0.5f, outerSize = outerSize)

            // Then: Schatten-Mitte 1 Mondradius links → Schattenkante senkrecht in
            // Mondmitte (AK aus shared-095)
            assertEquals(-outerSize / 2f, offset, 0.0001f)
        }

        @Test
        fun `vollmond at progress one shifts shadow tangentially off the disc`() {
            // Given: Sitzung beendet
            // When
            val offset = MoonPhaseGeometry.shadowOffset(progress = 1f, outerSize = outerSize)

            // Then: Schatten links tangential zum Mond → Mond ist voll sichtbar,
            // kein Restschatten im Clip
            assertEquals(-outerSize, offset, 0.0001f)
        }

        @Test
        fun `progress is clamped below zero`() {
            // Given: ungueltiger negativer Progress (Defensiv-Check)
            // When
            val offset = MoonPhaseGeometry.shadowOffset(progress = -0.5f, outerSize = outerSize)

            // Then: wie Neumond behandelt
            assertEquals(0f, offset, 0.0001f)
        }

        @Test
        fun `progress is clamped above one`() {
            // Given: ungueltiger Progress > 1 (z.B. nach Drift)
            // When
            val offset = MoonPhaseGeometry.shadowOffset(progress = 1.5f, outerSize = outerSize)

            // Then: wie Vollmond behandelt — Schatten bleibt tangential, faehrt
            // nicht weiter raus
            assertEquals(-outerSize, offset, 0.0001f)
        }
    }

    @Nested
    inner class HaloAlpha {

        @Test
        fun `halo alpha at progress zero is near invisible base`() {
            // Given: Neumond
            // When
            val alpha = MoonPhaseGeometry.haloAlpha(progress = 0f)

            // Then: smoothstep(0) = 0, alpha = 0.02
            assertEquals(0.02f, alpha, 0.0001f)
        }

        @Test
        fun `halo alpha at progress one reaches the warm maximum`() {
            // Given: Vollmond
            // When
            val alpha = MoonPhaseGeometry.haloAlpha(progress = 1f)

            // Then: smoothstep(1) = 1, alpha = 0.02 + 0.48 = 0.5
            assertEquals(0.5f, alpha, 0.0001f)
        }

        @Test
        fun `halo alpha at halftime follows smoothstep curve`() {
            // Given: Halbzeit — smoothstep(0.5) = 0.5, alpha = 0.02 + 0.5 * 0.48 = 0.26
            // When
            val alpha = MoonPhaseGeometry.haloAlpha(progress = 0.5f)

            // Then
            assertEquals(0.26f, alpha, 0.0001f)
        }
    }
}
