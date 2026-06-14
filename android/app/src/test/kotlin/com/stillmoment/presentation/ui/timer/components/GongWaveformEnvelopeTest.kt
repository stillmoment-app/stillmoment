package com.stillmoment.presentation.ui.timer.components

import com.stillmoment.domain.models.GongSound
import com.stillmoment.presentation.ui.timer.GongSelectionLogic
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Pure-Logic-Tests fuer shared-115 — Mini-Wellenform-Huellkurven und
 * Sichtbarkeit der Lautstaerke-Karte.
 *
 * 1:1 Pendant zu iOS' GongWaveformTests.swift: Die WAVE-Werte sind eine
 * geteilte Cross-Platform-Spezifikation und muessen exakt mit iOS uebereinstimmen,
 * damit beide Plattformen dieselbe Form rendern.
 */
class GongWaveformEnvelopeTest {

    @Nested
    inner class EnvelopePerSoundId {

        @Test
        fun `temple bell has eleven bars`() {
            assertEquals(11, GongWaveformEnvelope.envelope("temple-bell")?.size)
        }

        @Test
        fun `classic bowl has eleven bars`() {
            assertEquals(11, GongWaveformEnvelope.envelope("classic-bowl")?.size)
        }

        @Test
        fun `deep resonance has eleven bars`() {
            assertEquals(11, GongWaveformEnvelope.envelope("deep-resonance")?.size)
        }

        @Test
        fun `clear strike has eleven bars`() {
            assertEquals(11, GongWaveformEnvelope.envelope("clear-strike")?.size)
        }

        @Test
        fun `temple bell matches fixed cross-platform values`() {
            // Geteilte Spezifikation — muss exakt mit der iOS WAVE-Map uebereinstimmen.
            val expected = listOf(
                0.35f, 0.90f, 1.00f, 0.85f, 0.78f, 0.68f, 0.60f, 0.50f, 0.42f, 0.34f, 0.26f
            )
            val actual = GongWaveformEnvelope.envelope("temple-bell")
            assertEquals(expected, actual)
        }

        @Test
        fun `clear strike matches fixed cross-platform values`() {
            val expected = listOf(
                0.25f, 1.00f, 0.70f, 0.45f, 0.30f, 0.20f, 0.14f, 0.10f, 0.08f, 0.06f, 0.05f
            )
            val actual = GongWaveformEnvelope.envelope("clear-strike")
            assertEquals(expected, actual)
        }

        @Test
        fun `classic bowl matches fixed cross-platform values`() {
            val expected = listOf(
                0.30f, 0.95f, 0.80f, 0.65f, 0.55f, 0.45f, 0.40f, 0.32f, 0.28f, 0.22f, 0.18f
            )
            val actual = GongWaveformEnvelope.envelope("classic-bowl")
            assertEquals(expected, actual)
        }

        @Test
        fun `deep resonance matches fixed cross-platform values`() {
            val expected = listOf(
                0.45f, 0.70f, 0.90f, 1.00f, 0.92f, 0.86f, 0.80f, 0.72f, 0.64f, 0.54f, 0.44f
            )
            val actual = GongWaveformEnvelope.envelope("deep-resonance")
            assertEquals(expected, actual)
        }
    }

    @Nested
    inner class VibrationHasNoWaveform {

        @Test
        fun `vibration has no envelope`() {
            assertNull(GongWaveformEnvelope.envelope(GongSound.VIBRATION_ID))
        }

        @Test
        fun `unknown sound has no envelope`() {
            assertNull(GongWaveformEnvelope.envelope("not-a-real-sound"))
        }
    }

    @Nested
    inner class BarHeightMapping {

        @Test
        fun `silent value maps to floor height of 4dp`() {
            assertEquals(4f, GongWaveformEnvelope.barHeight(0f))
        }

        @Test
        fun `full value maps to ceiling height of 20dp`() {
            assertEquals(20f, GongWaveformEnvelope.barHeight(1f))
        }
    }

    @Nested
    inner class VolumeCardVisibility {

        @Test
        fun `volume card hidden for vibration`() {
            assertFalse(GongSelectionLogic.isVolumeCardVisible(GongSound.VIBRATION_ID))
        }

        @Test
        fun `volume card visible for audible sound`() {
            assertTrue(GongSelectionLogic.isVolumeCardVisible("temple-bell"))
        }
    }
}
