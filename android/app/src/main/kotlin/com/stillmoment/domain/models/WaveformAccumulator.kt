package com.stillmoment.domain.models

import kotlin.math.abs

/**
 * Builds a [MeditationWaveform] by streaming PCM sample chunks into a fixed number
 * of buckets (shared-107).
 *
 * The total frame count is known up front (estimated from the audio file's duration
 * and sample rate on Android), so each incoming frame is assigned to a bucket by its
 * global position. Each bucket tracks the peak (maximum absolute amplitude) of the
 * frames that fall into it. [finalize] normalizes all peaks against the global maximum.
 *
 * This is a mutable builder by design, with no Android framework dependencies — fully
 * unit-testable with synthetic samples. Mirrors the iOS `WaveformAccumulator`.
 *
 * @param bucketCount Number of buckets (waveform bars) to produce. Clamped to at least 1.
 * @param totalFrameCount Total number of mono frames that will be appended. Used to map
 *   each frame to its bucket. A value of `0` produces an all-zero waveform.
 */
class WaveformAccumulator(
    bucketCount: Int,
    totalFrameCount: Int
) {
    private val bucketCount: Int = maxOf(1, bucketCount)
    private val totalFrameCount: Int = maxOf(0, totalFrameCount)
    private val peaks: FloatArray = FloatArray(this.bucketCount)
    private var processedFrameCount: Int = 0

    /**
     * Feeds a chunk of mono PCM samples sequentially. Samples are assigned to buckets
     * by their running global frame index. Values may be negative; the absolute value
     * is used. A no-op when [totalFrameCount] is `0`.
     */
    fun append(samples: List<Float>) {
        if (totalFrameCount == 0) {
            return
        }
        for (sample in samples) {
            val bucketIndex = bucketIndex(processedFrameCount)
            val magnitude = abs(sample)
            if (magnitude > peaks[bucketIndex]) {
                peaks[bucketIndex] = magnitude
            }
            processedFrameCount++
        }
    }

    /**
     * Produces the normalized waveform. Peaks are divided by the global maximum so the
     * loudest bar becomes `1.0`. An all-silent input (global max `0`) yields all zeros
     * (no division by zero).
     */
    fun finalize(): MeditationWaveform {
        val globalMax = peaks.maxOrNull() ?: 0f
        if (globalMax <= 0f) {
            return MeditationWaveform(List(bucketCount) { 0f })
        }
        return MeditationWaveform(peaks.map { it / globalMax })
    }

    /** Maps a global frame index to its bucket, distributing frames evenly. */
    private fun bucketIndex(frame: Int): Int {
        val rawIndex = frame * bucketCount / totalFrameCount
        return minOf(rawIndex, bucketCount - 1)
    }
}
