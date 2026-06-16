package com.stillmoment.domain.services

import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.MeditationWaveform

/**
 * Errors that can occur while generating a waveform from an audio file (shared-107).
 *
 * The provider turns these into a fallback (a flat line instead of bars) so the trim
 * editor stays usable even when decoding fails.
 */
sealed class WaveformGenerationException(message: String, cause: Throwable? = null) :
    Exception(message, cause) {
    /** The audio file could not be opened (permission lost, file gone). */
    class FileNotAccessible(cause: Throwable? = null) :
        WaveformGenerationException("Could not access audio file for waveform generation", cause)

    /** The audio could not be decoded into PCM. */
    class DecodingFailed(reason: String, cause: Throwable? = null) :
        WaveformGenerationException("Could not decode audio for waveform generation: $reason", cause)
}

/**
 * Generates a normalized [MeditationWaveform] by decoding an audio file (shared-107).
 *
 * Implementations decode chunk-wise off the main thread; decoding a long file can take
 * several seconds, so callers treat this as expensive.
 */
interface WaveformGenerationServiceProtocol {
    /**
     * Decodes the audio file and produces a normalized waveform with
     * [MeditationWaveform.SAMPLE_COUNT] samples.
     *
     * @param uri Content/file URI string of the audio file.
     * @throws WaveformGenerationException if the file cannot be accessed or decoded.
     */
    suspend fun generateWaveform(uri: String): MeditationWaveform
}

/**
 * Persists precomputed waveforms per meditation so they only need to be generated once
 * (shared-107). Cache entries are small and never need invalidation because audio files
 * are never modified (non-destructive invariant) — only a changed sample count counts as
 * a miss.
 */
interface WaveformCacheServiceProtocol {
    /** Returns the cached waveform for a meditation, or null if none is stored. */
    fun load(id: String): MeditationWaveform?

    /**
     * Stores the waveform for a meditation.
     *
     * @throws java.io.IOException if the waveform cannot be encoded or written.
     */
    fun save(id: String, waveform: MeditationWaveform)

    /** Removes the cached waveform for a meditation, if present. */
    fun delete(id: String)
}

/**
 * Orchestrates waveform access for a meditation (shared-107): serves a cached waveform
 * when present, otherwise generates and caches it.
 *
 * Concurrent requests for the same meditation share a single in-flight generation so the
 * background precompute (after import) and an editor opening never decode the file twice.
 */
interface WaveformProviderProtocol {
    /**
     * Returns the waveform for a meditation.
     *
     * Cache hit returns immediately; on a miss the waveform is generated, cached, and
     * returned. A failing cache-save is non-fatal — the generated waveform is still returned.
     *
     * @throws WaveformGenerationException if the file cannot be decoded.
     */
    suspend fun waveform(meditation: GuidedMeditation): MeditationWaveform

    /**
     * Kicks off generation in the background (fire-and-forget) so the waveform is cached
     * by the time the editor is opened. Never blocks the caller and never crashes on error.
     */
    fun precompute(meditation: GuidedMeditation)

    /** Removes the cached waveform for a meditation (called when the meditation is deleted). */
    fun removeCached(id: String)
}
