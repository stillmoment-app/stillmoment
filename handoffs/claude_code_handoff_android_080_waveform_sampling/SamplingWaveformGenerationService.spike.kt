// SPIKE REFERENCE — android-080. NOT production code, NOT wired into the build.
//
// This is the verified working prototype from the 2026-06-17 spike: ~5.7s instead of
// ~43s for a 20-min MP3 on the emulator, correlation ~0.6 to the exact waveform
// (accepted as "plausible UI waveform"). Use it as the reference for the subtle bits
// the ticket prose can only approximate — they were each gotten WRONG first and fixed
// by measurement:
//   1. FIFO timestamp mapping (the MP3 decoder does NOT pass presentationTimeUs through).
//   2. Output drain with timeout 0 while feeding (10ms-per-skipped-frame = 7 min otherwise).
//   3. Cheap skip loop via extractor.advance() (no queueInputBuffer for skipped frames).
//   4. Peak computed directly on the ShortBuffer (no List<Float> boxing).
//
// Production TODO (see README.md): remove PERF instrumentation, handle the short-file
// edge case (fixed 4/s gives too few points for 2200 bars on short files → decode fully
// below a threshold), add unit tests for the FIFO/bucket mapping (extract it from the
// device-only decode), wire cleanly into AppModule (replace the Android binding behind
// WaveformGenerationServiceProtocol).

package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformGenerationServiceProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import javax.inject.Inject
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive

/**
 * Sampling-based waveform generation (android-080 spike).
 *
 * Decodes only ~4 MP3 frames per second of audio instead of the whole file, mapping each
 * decoded frame's peak to its waveform bar. Input-side decimation: frames between sample
 * slots are skipped with extractor.advance() (cheap) instead of being submitted to the
 * codec (queueInputBuffer was 37% of the full-decode cost).
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
                logger.w(TAG, "Sampling: no duration, returning empty waveform")
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
        val mime = inputFormat.getString(MediaFormat.KEY_MIME)
            ?: throw WaveformGenerationException.DecodingFailed("Missing MIME type")
        val codec = try {
            MediaCodec.createDecoderByType(mime).apply {
                configure(inputFormat, null, null, 0)
                start()
            }
        } catch (e: IOException) {
            throw WaveformGenerationException.DecodingFailed("Could not create decoder for $mime", e)
        } catch (e: IllegalStateException) {
            throw WaveformGenerationException.DecodingFailed("Decoder failed to start", e)
        }

        val buckets = MeditationWaveform.SAMPLE_COUNT
        val peaks = FloatArray(buckets)
        val intervalUs = 1_000_000L / TARGET_SAMPLES_PER_SEC
        val bufferInfo = MediaCodec.BufferInfo()
        // The MP3 decoder does NOT pass our input presentationTimeUs through to the output;
        // it numbers outputs by cumulative sample count. With decimated input that collapses
        // every decoded frame onto the first ~9% of the timeline. So we track the fed input
        // timestamps in FIFO order and map each output back to the frame we actually fed.
        val pendingUs = ArrayDeque<Long>()
        var nextSampleUs = 0L
        var inputDone = false
        var outputDone = false
        var decodedFrames = 0
        val wallStart = System.nanoTime() // PERF (remove in production)
        try {
            while (!outputDone) {
                currentCoroutineContext().ensureActive()
                if (!inputDone) {
                    // Skip cheaply through frames before the next sample slot — no output drain
                    // in between (that 10ms-timeout-per-skip is what made this "take forever").
                    var sampleTime = extractor.sampleTime
                    while (sampleTime in 0 until nextSampleUs) {
                        if (!extractor.advance()) {
                            sampleTime = -1L
                            break
                        }
                        sampleTime = extractor.sampleTime
                    }
                    val inIndex = codec.dequeueInputBuffer(TIMEOUT_US)
                    if (inIndex >= 0) {
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
                }

                // Drain without blocking while still feeding; only wait once input is done.
                val outIndex = codec.dequeueOutputBuffer(bufferInfo, if (inputDone) TIMEOUT_US else 0L)
                if (outIndex >= 0) {
                    val outBuf = codec.getOutputBuffer(outIndex)
                    if (outBuf != null && bufferInfo.size > 0) {
                        val ts = pendingUs.removeFirstOrNull() ?: bufferInfo.presentationTimeUs
                        val bucket = (ts * buckets / durationUs).toInt().coerceIn(0, buckets - 1)
                        val p = peakOf(outBuf, bufferInfo.offset, bufferInfo.size)
                        if (p > peaks[bucket]) peaks[bucket] = p
                    }
                    codec.releaseOutputBuffer(outIndex, false)
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        outputDone = true
                    }
                }
            }
        } catch (e: IllegalStateException) {
            throw WaveformGenerationException.DecodingFailed("Decoder failed while sampling", e)
        } finally {
            runCatching { codec.stop() }
            runCatching { codec.release() }
        }

        val wallMs = (System.nanoTime() - wallStart) / 1_000_000 // PERF (remove in production)
        logger.d(TAG, "PERF-SAMPLING wall=${wallMs}ms buckets=$buckets rate=${TARGET_SAMPLES_PER_SEC}/s decoded=$decodedFrames")
        return normalize(peaks)
    }

    /** Peak absolute amplitude (channel 0) of a 16-bit signed LE interleaved PCM buffer. */
    private fun peakOf(buffer: ByteBuffer, offset: Int, size: Int): Float {
        buffer.position(offset)
        buffer.limit(offset + size)
        val shorts = buffer.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        var peak = 0f
        val count = shorts.remaining()
        var i = 0
        while (i < count) {
            val v = kotlin.math.abs(shorts.get(i) / Short.MAX_VALUE.toFloat())
            if (v > peak) peak = v
            i += STRIDE
        }
        return peak
    }

    private fun normalize(peaks: FloatArray): MeditationWaveform {
        val globalMax = peaks.maxOrNull() ?: 0f
        if (globalMax <= 0f) {
            return MeditationWaveform(List(peaks.size) { 0f })
        }
        return MeditationWaveform(peaks.map { it / globalMax })
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
            if (mime.startsWith("audio/")) return index
        }
        return null
    }

    private companion object {
        const val TAG = "WaveformSampling"
        const val TIMEOUT_US = 10_000L
        const val TARGET_SAMPLES_PER_SEC = 4L // measure ~4 frames per second of audio
        const val STRIDE = 4 // sub-sample within a decoded frame for the peak (every 4th sample)
    }
}
