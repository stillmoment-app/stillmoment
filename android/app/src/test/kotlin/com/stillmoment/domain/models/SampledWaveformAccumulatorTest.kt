package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [SampledWaveformAccumulator] — the bucket-peak builder behind the
 * Android sampling waveform generator (android-080).
 *
 * Where [WaveformAccumulator] maps frames by their running global index (full decode),
 * this accumulator maps each *sampled* frame to a bucket by its presentation timestamp,
 * since the decimated decode skips most frames. Each bucket keeps the peak magnitude;
 * `finalize()` normalizes against the global maximum (all-silent input yields all zeros).
 */
class SampledWaveformAccumulatorTest {
    @Nested
    inner class Bucketing {
        @Test
        fun `maps timestamps to buckets by fraction of duration and keeps the peak`() {
            val accumulator = SampledWaveformAccumulator(bucketCount = 2, durationUs = 100)

            accumulator.add(timestampUs = 0, peak = 0.1f)
            accumulator.add(timestampUs = 10, peak = 0.4f) // first half -> bucket 0
            accumulator.add(timestampUs = 50, peak = 0.2f)
            accumulator.add(timestampUs = 90, peak = 0.8f) // second half -> bucket 1
            val waveform = accumulator.finalize()

            // bucket 0 peak = 0.4, bucket 1 peak = 0.8; normalized against 0.8.
            assertEquals(listOf(0.5f, 1.0f), waveform.samples)
        }

        @Test
        fun `uses the absolute value of negative peaks`() {
            val accumulator = SampledWaveformAccumulator(bucketCount = 1, durationUs = 100)

            accumulator.add(timestampUs = 0, peak = -0.9f)
            accumulator.add(timestampUs = 50, peak = 0.3f)
            val waveform = accumulator.finalize()

            assertEquals(listOf(1.0f), waveform.samples)
        }

        @Test
        fun `a timestamp at the very end lands in the last bucket`() {
            val accumulator = SampledWaveformAccumulator(bucketCount = 4, durationUs = 100)

            accumulator.add(timestampUs = 100, peak = 0.5f)
            val waveform = accumulator.finalize()

            // Only the last bucket has a peak; it normalizes to 1.0, the rest stay 0.
            assertEquals(listOf(0.0f, 0.0f, 0.0f, 1.0f), waveform.samples)
        }
    }

    @Nested
    inner class Normalization {
        @Test
        fun `divides every peak by the global maximum`() {
            val accumulator = SampledWaveformAccumulator(bucketCount = 3, durationUs = 300)

            accumulator.add(timestampUs = 0, peak = 0.25f)
            accumulator.add(timestampUs = 150, peak = 0.5f)
            accumulator.add(timestampUs = 290, peak = 1.0f)
            val waveform = accumulator.finalize()

            assertEquals(listOf(0.25f, 0.5f, 1.0f), waveform.samples)
        }
    }

    @Nested
    inner class EdgeCases {
        @Test
        fun `all-silent input yields all zeros without dividing by zero`() {
            val accumulator = SampledWaveformAccumulator(bucketCount = 3, durationUs = 300)

            accumulator.add(timestampUs = 0, peak = 0.0f)
            accumulator.add(timestampUs = 150, peak = 0.0f)
            accumulator.add(timestampUs = 290, peak = 0.0f)
            val waveform = accumulator.finalize()

            assertEquals(listOf(0.0f, 0.0f, 0.0f), waveform.samples)
        }

        @Test
        fun `zero duration produces an all-zero waveform`() {
            val accumulator = SampledWaveformAccumulator(bucketCount = 4, durationUs = 0)

            accumulator.add(timestampUs = 0, peak = 0.9f)
            val waveform = accumulator.finalize()

            assertEquals(4, waveform.samples.size)
            assertTrue(waveform.samples.all { it == 0.0f })
        }

        @Test
        fun `bucket count is clamped to at least one`() {
            val accumulator = SampledWaveformAccumulator(bucketCount = 0, durationUs = 100)

            accumulator.add(timestampUs = 50, peak = 0.5f)
            val waveform = accumulator.finalize()

            assertEquals(1, waveform.samples.size)
        }

        @Test
        fun `long files do not overflow the bucket index`() {
            // A 60-min file is 3.6e9 us. With 2200 buckets, timestampUs * bucketCount
            // (~7.9e12) overflows a 32-bit Int — the math must use 64-bit arithmetic.
            val durationUs = 60L * 60L * 1_000_000L
            val accumulator = SampledWaveformAccumulator(
                bucketCount = MeditationWaveform.SAMPLE_COUNT,
                durationUs = durationUs
            )

            accumulator.add(timestampUs = durationUs - 1, peak = 0.5f)
            val waveform = accumulator.finalize()

            assertEquals(MeditationWaveform.SAMPLE_COUNT, waveform.samples.size)
            assertTrue(waveform.samples.all { it in 0.0f..1.0f })
        }
    }

    @Nested
    inner class SampleInterval {
        @Test
        fun `targets roughly four samples per second for a long file`() {
            // 20 min: 2 * 2200 = 4400 target samples over 1.2e9 us -> ~272 ms interval,
            // i.e. ~3.7 samples per second (matches the validated spike's ~4/s).
            val durationUs = 20L * 60L * 1_000_000L

            val intervalUs = SampledWaveformAccumulator.sampleIntervalUs(
                durationUs = durationUs,
                bucketCount = MeditationWaveform.SAMPLE_COUNT
            )

            assertEquals(durationUs / (2L * MeditationWaveform.SAMPLE_COUNT), intervalUs)
            val samplesPerSecond = 1_000_000.0 / intervalUs
            assertTrue(samplesPerSecond in 3.0..5.0, "expected ~4/s, was $samplesPerSecond")
        }

        @Test
        fun `shrinks below the MP3 frame spacing for short files so every frame is decoded`() {
            // A 1-min file: interval falls to ~14 ms, below one ~26 ms MP3 frame, so the
            // decimation loop ends up feeding every frame (a full decode).
            val durationUs = 1L * 60L * 1_000_000L

            val intervalUs = SampledWaveformAccumulator.sampleIntervalUs(
                durationUs = durationUs,
                bucketCount = MeditationWaveform.SAMPLE_COUNT
            )

            val mp3FrameSpacingUs = 26_000L
            assertTrue(intervalUs <= mp3FrameSpacingUs, "expected <= one frame, was $intervalUs")
        }

        @Test
        fun `never returns a non-positive interval`() {
            assertEquals(1L, SampledWaveformAccumulator.sampleIntervalUs(durationUs = 0, bucketCount = 2200))
        }
    }
}
