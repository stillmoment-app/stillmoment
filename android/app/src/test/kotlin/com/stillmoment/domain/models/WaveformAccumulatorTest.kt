package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [WaveformAccumulator] — streaming bucket-peak builder.
 *
 * Mirrors the iOS accumulator: frames are mapped to buckets by their global position,
 * each bucket keeps the peak magnitude, and `finalize()` normalizes against the global
 * maximum (all-silent input yields all zeros).
 */
class WaveformAccumulatorTest {
    @Nested
    inner class Bucketing {
        @Test
        fun `distributes frames evenly across buckets and keeps the peak`() {
            val accumulator = WaveformAccumulator(bucketCount = 2, totalFrameCount = 4)

            accumulator.append(listOf(0.1f, 0.4f, 0.2f, 0.8f))
            val waveform = accumulator.finalize()

            // bucket 0 peak = 0.4, bucket 1 peak = 0.8; normalized against 0.8.
            assertEquals(listOf(0.5f, 1.0f), waveform.samples)
        }

        @Test
        fun `uses the absolute value of negative samples`() {
            val accumulator = WaveformAccumulator(bucketCount = 1, totalFrameCount = 2)

            accumulator.append(listOf(-0.9f, 0.3f))
            val waveform = accumulator.finalize()

            assertEquals(listOf(1.0f), waveform.samples)
        }

        @Test
        fun `accepts samples across multiple append calls`() {
            val accumulator = WaveformAccumulator(bucketCount = 2, totalFrameCount = 4)

            accumulator.append(listOf(0.1f, 0.4f))
            accumulator.append(listOf(0.2f, 0.8f))
            val waveform = accumulator.finalize()

            assertEquals(listOf(0.5f, 1.0f), waveform.samples)
        }
    }

    @Nested
    inner class Normalization {
        @Test
        fun `divides every peak by the global maximum`() {
            val accumulator = WaveformAccumulator(bucketCount = 3, totalFrameCount = 3)

            accumulator.append(listOf(0.25f, 0.5f, 1.0f))
            val waveform = accumulator.finalize()

            assertEquals(listOf(0.25f, 0.5f, 1.0f), waveform.samples)
        }
    }

    @Nested
    inner class EdgeCases {
        @Test
        fun `all-silent input yields all zeros without dividing by zero`() {
            val accumulator = WaveformAccumulator(bucketCount = 3, totalFrameCount = 3)

            accumulator.append(listOf(0.0f, 0.0f, 0.0f))
            val waveform = accumulator.finalize()

            assertEquals(listOf(0.0f, 0.0f, 0.0f), waveform.samples)
        }

        @Test
        fun `zero total frame count produces an all-zero waveform`() {
            val accumulator = WaveformAccumulator(bucketCount = 4, totalFrameCount = 0)

            accumulator.append(listOf(0.9f, 0.9f))
            val waveform = accumulator.finalize()

            assertEquals(4, waveform.samples.size)
            assertTrue(waveform.samples.all { it == 0.0f })
        }

        @Test
        fun `bucket count is clamped to at least one`() {
            val accumulator = WaveformAccumulator(bucketCount = 0, totalFrameCount = 2)

            accumulator.append(listOf(0.5f, 0.5f))
            val waveform = accumulator.finalize()

            assertEquals(1, waveform.samples.size)
        }

        @Test
        fun `long files do not overflow the bucket index`() {
            // A 32-min file at 44.1 kHz has ~84.7M frames. With 2200 buckets,
            // frame * bucketCount overflows a 32-bit Int once the frame index passes
            // ~976k (≈22 s), yielding a negative bucket index and a crash. The bucket
            // math must use 64-bit arithmetic. Append well past the overflow threshold.
            val totalFrames = 84_672_000
            val accumulator = WaveformAccumulator(
                bucketCount = MeditationWaveform.SAMPLE_COUNT,
                totalFrameCount = totalFrames
            )

            // 1.1M samples pushes the frame counter past the Int-overflow point.
            accumulator.append(List(1_100_000) { 0.5f })
            val waveform = accumulator.finalize()

            assertEquals(MeditationWaveform.SAMPLE_COUNT, waveform.samples.size)
            assertTrue(waveform.samples.all { it in 0.0f..1.0f })
        }
    }
}
