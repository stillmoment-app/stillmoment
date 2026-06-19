package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.models.SampledWaveformAccumulator
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformGenerationServiceProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import javax.inject.Inject
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive

/**
 * Sampling-based [WaveformGenerationServiceProtocol] for Android (android-080).
 *
 * The exact, full-decode [WaveformGenerationService] decodes every frame, which takes
 * ~43s for a 20-min MP3 on the software MP3 decoder (the cost is codec input submission,
 * not waiting). This service instead decodes only a sampled subset of frames: it skips
 * cheaply through the file with `extractor.advance()` and only submits ~a handful of
 * frames per second to the codec, mapping each decoded frame's peak to its waveform bar.
 *
 * The result is a *plausible UI envelope*, not a sample-accurate waveform (correlation
 * ~0.6 to the exact form on the validation spike, ~5.7s instead of ~43s) — explicitly
 * accepted for the trim editor. iOS keeps its exact (fast) decoder; the resulting
 * cross-platform shape difference is accepted (a user only ever sees one platform).
 *
 * The sample rate is adaptive ([SampledWaveformAccumulator.sampleIntervalUs]): it targets
 * a fixed number of decoded frames regardless of length, so long files stay fast and
 * short files (where the interval drops below one frame) end up fully decoded — no
 * separate threshold branch.
 *
 * Decoding is device-only and not unit-tested (like [MediaCodecAudioFrameReader]); the
 * testable bucket/normalize logic lives in [SampledWaveformAccumulator].
 */
class SamplingWaveformGenerationService
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) : WaveformGenerationServiceProtocol {
    override suspend fun generateWaveform(uri: String): MeditationWaveform {
        currentCoroutineContext().ensureActive()
        val extractor = MediaExtractor()
        try {
            setDataSource(extractor, Uri.parse(uri))
            val trackIndex = selectAudioTrack(extractor)
                ?: throw WaveformGenerationException.DecodingFailed("No audio track in $uri")
            extractor.selectTrack(trackIndex)
            val inputFormat = extractor.getTrackFormat(trackIndex)
            val durationUs = runCatching { inputFormat.getLong(MediaFormat.KEY_DURATION) }.getOrDefault(0L)
            if (durationUs <= 0L) {
                logger.w(TAG, "Waveform sampling: file has no duration, returning empty waveform")
                return MeditationWaveform(List(MeditationWaveform.SAMPLE_COUNT) { 0f })
            }
            return decodeSampled(extractor, inputFormat, durationUs)
        } catch (e: IOException) {
            throw WaveformGenerationException.DecodingFailed("Failed to read $uri", e)
        } catch (e: IllegalArgumentException) {
            throw WaveformGenerationException.DecodingFailed("Invalid audio source $uri", e)
        } finally {
            runCatching { extractor.release() }
        }
    }

    private suspend fun decodeSampled(
        extractor: MediaExtractor,
        inputFormat: MediaFormat,
        durationUs: Long
    ): MeditationWaveform {
        val codec = createDecoder(inputFormat)
        val decoder = SamplingDecoder(extractor, codec, durationUs)
        try {
            val waveform = decoder.run()
            val seconds = durationUs / MICROS_PER_SECOND
            logger.d(TAG, "Sampled waveform generated (${seconds}s, ${decoder.decodedFrames} frames decoded)")
            return waveform
        } finally {
            runCatching { codec.stop() }
            runCatching { codec.release() }
        }
    }

    private fun createDecoder(inputFormat: MediaFormat): MediaCodec {
        val mime = inputFormat.getString(MediaFormat.KEY_MIME)
            ?: throw WaveformGenerationException.DecodingFailed("Missing MIME type")
        return try {
            MediaCodec.createDecoderByType(mime).apply {
                configure(inputFormat, null, null, 0)
                start()
            }
        } catch (e: IOException) {
            throw WaveformGenerationException.DecodingFailed("Could not create decoder for $mime", e)
        } catch (e: IllegalStateException) {
            throw WaveformGenerationException.DecodingFailed("Decoder failed to start", e)
        }
    }

    private fun setDataSource(extractor: MediaExtractor, uri: Uri) {
        when (uri.scheme) {
            "content" -> {
                val pfd = context.contentResolver.openFileDescriptor(uri, "r")
                    ?: throw WaveformGenerationException.FileNotAccessible()
                pfd.use { extractor.setDataSource(it.fileDescriptor) }
            }
            "file" -> {
                val path = uri.path ?: throw WaveformGenerationException.FileNotAccessible()
                extractor.setDataSource(path)
            }
            else -> throw WaveformGenerationException.DecodingFailed("Unsupported scheme: ${uri.scheme}")
        }
    }

    private fun selectAudioTrack(extractor: MediaExtractor): Int? {
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) {
                return index
            }
        }
        return null
    }

    private companion object {
        const val TAG = "WaveformSampling"
        const val MICROS_PER_SECOND = 1_000_000L
    }
}

/**
 * Drives the decimated `MediaCodec` decode loop for one file, feeding each sampled frame's
 * peak into a [SampledWaveformAccumulator]. Holds the loop's mutable state so the loop body
 * stays small; mirrors the streaming-source split in [MediaCodecAudioFrameReader].
 */
private class SamplingDecoder(
    private val extractor: MediaExtractor,
    private val codec: MediaCodec,
    private val durationUs: Long
) {
    private val bufferInfo = MediaCodec.BufferInfo()

    // The MP3 decoder does NOT pass our input presentationTimeUs through to the output; it
    // numbers outputs by cumulative sample count. With decimated input that would collapse
    // every decoded frame onto the first ~9% of the timeline ("waveform only at the start").
    // So we track fed input timestamps in FIFO order and map each output back to the frame
    // we actually fed.
    private val pendingUs = ArrayDeque<Long>()
    private val intervalUs = SampledWaveformAccumulator.sampleIntervalUs(durationUs, MeditationWaveform.SAMPLE_COUNT)
    private val accumulator = SampledWaveformAccumulator(MeditationWaveform.SAMPLE_COUNT, durationUs)

    private var nextSampleUs = 0L
    private var inputDone = false
    private var outputDone = false

    var decodedFrames = 0
        private set

    suspend fun run(): MeditationWaveform {
        while (!outputDone) {
            currentCoroutineContext().ensureActive()
            try {
                if (!inputDone) {
                    feedNextSample()
                }
                drainOutput()
            } catch (e: CancellationException) {
                throw e
            } catch (e: IllegalStateException) {
                throw WaveformGenerationException.DecodingFailed("Decoder failed while sampling", e)
            }
        }
        return accumulator.finalize()
    }

    private fun feedNextSample() {
        // Skip cheaply through frames before the next sample slot — no output drain in
        // between (a 10ms-timeout drain per skipped frame would take minutes on a long file).
        var sampleTime = extractor.sampleTime
        while (sampleTime in 0 until nextSampleUs) {
            if (!extractor.advance()) {
                sampleTime = -1L
                break
            }
            sampleTime = extractor.sampleTime
        }
        val inIndex = codec.dequeueInputBuffer(TIMEOUT_US)
        if (inIndex < 0) {
            return
        }
        val inBuf = codec.getInputBuffer(inIndex)
        val size = if (sampleTime < 0L || inBuf == null) -1 else extractor.readSampleData(inBuf, 0)
        if (size < 0) {
            codec.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            inputDone = true
        } else {
            codec.queueInputBuffer(inIndex, 0, size, sampleTime, 0)
            pendingUs.addLast(sampleTime)
            nextSampleUs = sampleTime + intervalUs
            decodedFrames++
            extractor.advance()
        }
    }

    private fun drainOutput() {
        // Don't block while still feeding (timeout 0); only wait once input is done.
        val outIndex = codec.dequeueOutputBuffer(bufferInfo, if (inputDone) TIMEOUT_US else 0L)
        if (outIndex < 0) {
            return
        }
        val outBuf = codec.getOutputBuffer(outIndex)
        if (outBuf != null && bufferInfo.size > 0) {
            val timestampUs = pendingUs.removeFirstOrNull() ?: bufferInfo.presentationTimeUs
            accumulator.add(timestampUs, peakOf(outBuf, bufferInfo.offset, bufferInfo.size))
        }
        codec.releaseOutputBuffer(outIndex, false)
        if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
            outputDone = true
        }
    }

    /** Peak absolute amplitude of a 16-bit signed LE PCM buffer, sub-sampled by [STRIDE]. */
    private fun peakOf(buffer: ByteBuffer, offset: Int, size: Int): Float {
        buffer.position(offset)
        buffer.limit(offset + size)
        val shorts = buffer.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        var peak = 0f
        val count = shorts.remaining()
        var i = 0
        while (i < count) {
            val magnitude = kotlin.math.abs(shorts.get(i) / Short.MAX_VALUE.toFloat())
            if (magnitude > peak) {
                peak = magnitude
            }
            i += STRIDE
        }
        return peak
    }

    private companion object {
        const val TIMEOUT_US = 10_000L
        const val STRIDE = 4 // sub-sample within a decoded frame for the peak (every 4th sample)
    }
}
