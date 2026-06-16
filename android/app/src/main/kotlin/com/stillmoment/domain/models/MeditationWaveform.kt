package com.stillmoment.domain.models

import kotlin.math.ceil
import kotlin.math.floor
import kotlinx.serialization.Serializable

/**
 * A precomputed, normalized waveform for a guided meditation (shared-107/108).
 *
 * Holds a fixed number of peak samples ([SAMPLE_COUNT]), each normalized to `[0, 1]`.
 * The resolution is deliberately higher than the ~220 bars an overview renders so a
 * zoomed-in view shows real detail; overviews call [downsampled]. The data is small
 * (~2200 floats), cached per meditation, and never derived from a mutating audio file,
 * so it does not need invalidation (non-destructive invariant).
 *
 * Pure domain model — no Android framework dependencies. Cross-platform values
 * ([SAMPLE_COUNT]) match iOS exactly so both platforms render the same resolution.
 */
@Serializable
data class MeditationWaveform(
    /** Peak amplitudes, normalized to `[0, 1]`. All zeros for an all-silent file. */
    val samples: List<Float>
) {
    /**
     * Reduces the waveform to [targetCount] display bars, keeping the loudest sample
     * of each bucket so short peaks stay visible. Returns `this` when the waveform
     * already has [targetCount] samples or fewer, or [targetCount] is not positive.
     */
    fun downsampled(to: Int): MeditationWaveform {
        if (to <= 0 || samples.size <= to) {
            return this
        }

        val peaks = FloatArray(to)
        samples.forEachIndexed { index, sample ->
            val bucket = minOf(index * to / samples.size, to - 1)
            if (sample > peaks[bucket]) {
                peaks[bucket] = sample
            }
        }
        return MeditationWaveform(peaks.toList())
    }

    /**
     * Cuts out the sample range covered by a fractional window of the file — the
     * zoomed trim editor renders this slice instead of the full waveform. Fractions
     * are clamped to `[0, 1]`; partially covered edge samples are included. Returns an
     * empty waveform when the lower bound is not below the upper bound.
     */
    fun windowed(fromFraction: Double, toFraction: Double): MeditationWaveform {
        val count = samples.size.toDouble()
        val lower = floor(fromFraction.coerceIn(0.0, 1.0) * count).toInt()
        val upper = ceil(toFraction.coerceIn(0.0, 1.0) * count).toInt()
        if (lower >= upper) {
            return MeditationWaveform(emptyList())
        }
        return MeditationWaveform(samples.subList(lower, upper).toList())
    }

    companion object {
        /**
         * The number of peak samples generated per file. Fixed across the app (and
         * matching iOS) so cached data and renderers agree on resolution.
         */
        const val SAMPLE_COUNT = 2200
    }
}
