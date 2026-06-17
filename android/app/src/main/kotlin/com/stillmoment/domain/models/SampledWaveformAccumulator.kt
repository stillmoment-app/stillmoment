package com.stillmoment.domain.models

import kotlin.math.abs

/**
 * Builds a [MeditationWaveform] from a *sampled* subset of decoded frames (android-080).
 *
 * The Android sampling generator decodes only ~4 frames per second of audio (input-side
 * decimation), so frames no longer arrive contiguously — [WaveformAccumulator]'s
 * by-global-index bucketing would not work. Instead, each sampled frame is placed into a
 * bucket by its presentation timestamp relative to the total duration. Each bucket keeps
 * the peak (maximum absolute amplitude); [finalize] normalizes all peaks against the
 * global maximum.
 *
 * Pure domain model — no Android framework dependencies, fully unit-testable with
 * synthetic (timestamp, peak) pairs. The actual MediaCodec decode that produces those
 * pairs is device-only and not unit-tested (like the exact reader).
 *
 * @param bucketCount Number of buckets (waveform bars) to produce. Clamped to at least 1.
 * @param durationUs Total audio duration in microseconds. Used to map each timestamp to
 *   its bucket. A value of `0` (or less) produces an all-zero waveform.
 */
class SampledWaveformAccumulator(
    bucketCount: Int,
    durationUs: Long
) {
    private val bucketCount: Int = maxOf(1, bucketCount)
    private val durationUs: Long = maxOf(0L, durationUs)
    private val peaks: FloatArray = FloatArray(this.bucketCount)

    /**
     * Records the [peak] of a frame at presentation time [timestampUs]. The peak is mapped
     * to the bucket covering that fraction of the duration; the larger of the existing and
     * new magnitude is kept. A no-op when [durationUs] is `0`.
     */
    fun add(timestampUs: Long, peak: Float) {
        if (durationUs <= 0L) {
            return
        }
        val clamped = timestampUs.coerceIn(0L, durationUs)
        // 64-bit arithmetic: a long file's timestampUs * bucketCount overflows a 32-bit Int.
        val bucket = (clamped * bucketCount / durationUs).toInt().coerceIn(0, bucketCount - 1)
        val magnitude = abs(peak)
        if (magnitude > peaks[bucket]) {
            peaks[bucket] = magnitude
        }
    }

    /**
     * Produces the normalized waveform. Peaks are divided by the global maximum so the
     * loudest bar becomes `1.0`. An all-silent input (global max `0`) yields all zeros.
     */
    fun finalize(): MeditationWaveform {
        val globalMax = peaks.maxOrNull() ?: 0f
        if (globalMax <= 0f) {
            return MeditationWaveform(List(bucketCount) { 0f })
        }
        return MeditationWaveform(peaks.map { it / globalMax })
    }

    companion object {
        /**
         * Microseconds between consecutive sample slots for an adaptive decode rate.
         *
         * Targets roughly two decoded frames per bucket so bars stay filled across the
         * whole length range. For a long file this works out to ~4 samples per second
         * (the validated spike rate); for a short file the interval shrinks below one MP3
         * frame, so the decimation loop ends up feeding essentially every frame (a full
         * decode), which keeps short files correct without a separate threshold branch.
         *
         * @return The sample interval in microseconds, always at least `1`.
         */
        fun sampleIntervalUs(durationUs: Long, bucketCount: Int): Long {
            val targetSamples = 2L * maxOf(1, bucketCount)
            return maxOf(1L, durationUs / targetSamples)
        }
    }
}
