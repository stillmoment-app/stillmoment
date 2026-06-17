package com.stillmoment.presentation.ui.timer.components

import com.stillmoment.domain.models.BackgroundSound
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Pure-Logic-Tests fuer shared-121 — Soundscape-Loop-Wellenform-Huellkurven.
 *
 * 1:1 Pendant zu iOS' ScapeWaveform: Die SWAVE-Werte sind eine geteilte
 * Cross-Platform-Spezifikation (13 Werte, Loop-Muster) und muessen exakt mit der
 * iOS `swaveEnvelopes`-Map uebereinstimmen, damit beide Plattformen dieselbe Form
 * rendern. "Stille" hat keine Huellkurve (flache Linie).
 */
class ScapeWaveformEnvelopeTest {

    @Nested
    inner class EnvelopePerSoundId {

        @Test
        fun `forest has thirteen bars`() {
            assertEquals(13, ScapeWaveformEnvelope.envelope("forest")?.size)
        }

        @Test
        fun `cozy rain has thirteen bars`() {
            assertEquals(13, ScapeWaveformEnvelope.envelope("cozy-rain")?.size)
        }

        @Test
        fun `forest matches fixed cross-platform values`() {
            val expected = listOf(
                0.30f, 0.55f, 0.40f, 0.70f, 0.50f, 0.62f, 0.45f, 0.72f, 0.52f, 0.60f, 0.42f, 0.58f, 0.36f
            )
            assertEquals(expected, ScapeWaveformEnvelope.envelope("forest"))
        }

        @Test
        fun `cozy rain matches fixed cross-platform values`() {
            val expected = listOf(
                0.62f, 0.74f, 0.58f, 0.80f, 0.66f, 0.78f, 0.60f, 0.82f, 0.64f, 0.76f, 0.58f, 0.72f, 0.60f
            )
            assertEquals(expected, ScapeWaveformEnvelope.envelope("cozy-rain"))
        }
    }

    @Nested
    inner class CustomFilesUseDefaultEnvelope {

        @Test
        fun `unknown custom id falls back to the neutral default envelope`() {
            val expected = listOf(
                0.45f, 0.55f, 0.48f, 0.60f, 0.50f, 0.58f, 0.46f, 0.62f, 0.50f, 0.56f, 0.44f, 0.54f, 0.42f
            )
            assertEquals(expected, ScapeWaveformEnvelope.envelope("some-custom-uuid"))
        }

        @Test
        fun `default envelope has thirteen bars`() {
            assertEquals(13, ScapeWaveformEnvelope.envelope("some-custom-uuid")?.size)
        }
    }

    @Nested
    inner class SilenceHasNoWaveform {

        @Test
        fun `silence has no envelope`() {
            assertNull(ScapeWaveformEnvelope.envelope(BackgroundSound.SILENT_ID))
        }
    }

    @Nested
    inner class BarHeightMapping {

        @Test
        fun `silent value maps to floor height of 4dp`() {
            assertEquals(4f, ScapeWaveformEnvelope.barHeight(0f))
        }

        @Test
        fun `full value maps to ceiling height of 20dp`() {
            assertEquals(20f, ScapeWaveformEnvelope.barHeight(1f))
        }

        @Test
        fun `value above one is clamped to the ceiling`() {
            assertEquals(20f, ScapeWaveformEnvelope.barHeight(1.5f))
        }
    }
}
