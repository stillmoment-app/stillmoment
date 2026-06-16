package com.stillmoment.domain.services

/**
 * Decoder seam over an audio file (shared-107). Hides `MediaExtractor`/`MediaCodec`
 * behind a pure interface so the waveform generation logic can be unit-tested with a
 * fake reader that serves synthetic samples — no real audio needed.
 *
 * A reader opens a file into an [AudioFrameSource], which streams mono PCM frame chunks
 * (channel 0). The full file is never decoded into memory at once.
 */
interface AudioFrameReader {
    /**
     * Opens the audio file at [uri] for streaming mono frame chunks.
     *
     * @param uri Content/file URI string of the audio file.
     * @return An open [AudioFrameSource]. The caller must close it.
     * @throws WaveformGenerationException if the file cannot be accessed or decoded.
     */
    fun open(uri: String): AudioFrameSource
}

/**
 * A streaming source of mono PCM frames for one audio file. Closeable — the caller owns
 * the lifecycle and closes it when done (or on error).
 */
interface AudioFrameSource : AutoCloseable {
    /** Output sample rate in Hz (from the decoder's output format). */
    val sampleRate: Int

    /** Output channel count (from the decoder's output format). */
    val channelCount: Int

    /**
     * Estimated total mono frame count (`durationUs * sampleRate / 1e6` on Android).
     * Used by the accumulator to map frames to buckets.
     */
    val totalFrameCount: Int

    /**
     * Reads the next chunk of mono samples (channel 0), or `null` at end of stream.
     * Samples are normalized to `[-1, 1]`.
     *
     * @throws WaveformGenerationException if decoding fails mid-stream.
     */
    fun readChunk(): List<Float>?
}
