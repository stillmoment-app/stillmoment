package com.stillmoment.domain.models

import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [MeditationWaveform] — downsampling, windowing, serialization.
 *
 * Mirrors the iOS `MeditationWaveform` semantics (shared-107/108): a fixed-length,
 * normalized peak waveform with `downsampled(to)` for overview bars and
 * `windowed(from, to)` for the zoomed editor.
 */
class MeditationWaveformTest {
    @Nested
    inner class Resolution {
        @Test
        fun `sample count matches the cross-platform resolution`() {
            assertEquals(2200, MeditationWaveform.SAMPLE_COUNT)
        }
    }

    @Nested
    inner class Downsampling {
        @Test
        fun `keeps the loudest sample of each bucket so peaks stay visible`() {
            // 4 samples into 2 buckets: each bucket keeps its max.
            val waveform = MeditationWaveform(listOf(0.1f, 0.9f, 0.2f, 0.5f))

            val reduced = waveform.downsampled(to = 2)

            assertEquals(listOf(0.9f, 0.5f), reduced.samples)
        }

        @Test
        fun `returns itself when target is not smaller than current count`() {
            val waveform = MeditationWaveform(listOf(0.1f, 0.2f))

            assertEquals(waveform, waveform.downsampled(to = 2))
            assertEquals(waveform, waveform.downsampled(to = 5))
        }

        @Test
        fun `returns itself for a non-positive target`() {
            val waveform = MeditationWaveform(listOf(0.1f, 0.2f, 0.3f))

            assertEquals(waveform, waveform.downsampled(to = 0))
        }
    }

    @Nested
    inner class Windowing {
        @Test
        fun `cuts out the fractional slice of the samples`() {
            val waveform = MeditationWaveform((0 until 10).map { it / 10f })

            // 0.2..0.5 of 10 samples => indices 2..5 (lower floor, upper ceil).
            val windowed = waveform.windowed(fromFraction = 0.2, toFraction = 0.5)

            assertEquals(listOf(0.2f, 0.3f, 0.4f), windowed.samples)
        }

        @Test
        fun `clamps fractions into the valid range`() {
            val waveform = MeditationWaveform((0 until 4).map { it / 4f })

            val windowed = waveform.windowed(fromFraction = -1.0, toFraction = 2.0)

            assertEquals(waveform.samples, windowed.samples)
        }

        @Test
        fun `returns empty when lower bound is not below upper bound`() {
            val waveform = MeditationWaveform((0 until 4).map { it / 4f })

            // 0.5 of 4 samples = exactly index 2, so floor == ceil -> empty slice.
            val windowed = waveform.windowed(fromFraction = 0.5, toFraction = 0.5)

            assertTrue(windowed.samples.isEmpty())
        }
    }

    @Nested
    inner class Serialization {
        @Test
        fun `round-trips through JSON`() {
            val waveform = MeditationWaveform(listOf(0.0f, 0.5f, 1.0f))

            val json = Json.encodeToString(waveform)
            val restored = Json.decodeFromString<MeditationWaveform>(json)

            assertEquals(waveform, restored)
        }
    }
}
