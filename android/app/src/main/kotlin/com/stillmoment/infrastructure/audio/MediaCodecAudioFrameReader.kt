package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import com.stillmoment.domain.services.AudioFrameReader
import com.stillmoment.domain.services.AudioFrameSource
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.FileNotFoundException
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import javax.inject.Inject

/**
 * Real [AudioFrameReader] decoding compressed audio (MP3/M4A) to PCM with
 * `MediaExtractor` + `MediaCodec` (shared-107). Verified by the Phase-C spike:
 * synchronous decode loop, 16-bit signed little-endian PCM output, sampleRate /
 * channelCount read from the OUTPUT format, mono downmix via channel 0.
 *
 * Decoding is never unit-tested (device-only); unit tests use the fake reader. This class
 * stays thin and delegates the streaming loop to [MediaCodecAudioFrameSource].
 */
class MediaCodecAudioFrameReader
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) : AudioFrameReader {
    override fun open(uri: String): AudioFrameSource {
        val parsed = Uri.parse(uri)
        val extractor = MediaExtractor()
        try {
            setDataSource(extractor, parsed)
            val trackIndex = selectAudioTrack(extractor)
                ?: throw WaveformGenerationException.DecodingFailed("No audio track in $uri")
            extractor.selectTrack(trackIndex)
            val inputFormat = extractor.getTrackFormat(trackIndex)
            return MediaCodecAudioFrameSource(extractor, inputFormat, logger)
        } catch (e: WaveformGenerationException) {
            extractor.release()
            throw e
        } catch (e: IOException) {
            extractor.release()
            throw WaveformGenerationException.DecodingFailed("Failed to read $uri", e)
        } catch (e: IllegalArgumentException) {
            extractor.release()
            throw WaveformGenerationException.DecodingFailed("Invalid audio source $uri", e)
        }
    }

    private fun setDataSource(extractor: MediaExtractor, uri: Uri) {
        when (uri.scheme) {
            "content" -> {
                val pfd = openFileDescriptor(uri)
                pfd.use { extractor.setDataSource(it.fileDescriptor) }
            }
            "file" -> {
                val path = uri.path
                    ?: throw WaveformGenerationException.FileNotAccessible()
                extractor.setDataSource(path)
            }
            else -> throw WaveformGenerationException.DecodingFailed("Unsupported scheme: ${uri.scheme}")
        }
    }

    private fun openFileDescriptor(uri: Uri): android.os.ParcelFileDescriptor {
        return try {
            context.contentResolver.openFileDescriptor(uri, "r")
                ?: throw WaveformGenerationException.FileNotAccessible()
        } catch (e: SecurityException) {
            logger.e(TAG, "URI permission lost: $uri", e)
            throw WaveformGenerationException.FileNotAccessible(e)
        } catch (e: FileNotFoundException) {
            logger.e(TAG, "File not found: $uri", e)
            throw WaveformGenerationException.FileNotAccessible(e)
        }
    }

    private fun selectAudioTrack(extractor: MediaExtractor): Int? {
        for (index in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(index)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) {
                return index
            }
        }
        return null
    }

    private companion object {
        const val TAG = "MediaCodecReader"
    }
}

/**
 * Streaming PCM source over a configured [MediaExtractor]. Drives a synchronous
 * `MediaCodec` decode loop, emitting mono (channel 0) float samples chunk-by-chunk.
 *
 * `sampleRate` / `channelCount` are read lazily from the decoder's OUTPUT format after
 * the first `INFO_OUTPUT_FORMAT_CHANGED`; until then they fall back to the input format.
 */
private class MediaCodecAudioFrameSource(
    private val extractor: MediaExtractor,
    inputFormat: MediaFormat,
    private val logger: LoggerProtocol
) : AudioFrameSource {
    private val codec: MediaCodec
    private val bufferInfo = MediaCodec.BufferInfo()
    private var inputDone = false
    private var outputDone = false

    private var outSampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
    private var outChannelCount = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

    init {
        val mime = inputFormat.getString(MediaFormat.KEY_MIME)
            ?: throw WaveformGenerationException.DecodingFailed("Missing MIME type")
        codec = try {
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

    override val sampleRate: Int get() = outSampleRate
    override val channelCount: Int get() = outChannelCount

    override val totalFrameCount: Int
        get() {
            val durationUs = extractor.let { ext ->
                val track = ext.sampleTrackIndex.coerceAtLeast(0)
                runCatching { ext.getTrackFormat(track).getLong(MediaFormat.KEY_DURATION) }
                    .getOrDefault(0L)
            }
            return (durationUs * outSampleRate / MICROS_PER_SECOND).toInt()
        }

    override fun readChunk(): List<Float>? {
        if (outputDone) {
            return null
        }
        // MediaCodec operations can throw IllegalStateException / MediaCodec.CodecException
        // (a subclass) on device-specific decoder hiccups. Wrap them so the contract holds:
        // generation only throws WaveformGenerationException, and the editor falls back to a
        // flat line instead of crashing the app.
        return try {
            feedInput()
            drainOutput()
        } catch (e: IllegalStateException) {
            throw WaveformGenerationException.DecodingFailed("Decoder failed while reading PCM", e)
        }
    }

    private fun feedInput() {
        if (inputDone) {
            return
        }
        val inputIndex = codec.dequeueInputBuffer(TIMEOUT_US)
        if (inputIndex < 0) {
            return
        }
        val inputBuffer = codec.getInputBuffer(inputIndex) ?: return
        val sampleSize = extractor.readSampleData(inputBuffer, 0)
        if (sampleSize < 0) {
            codec.queueInputBuffer(inputIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            inputDone = true
        } else {
            codec.queueInputBuffer(inputIndex, 0, sampleSize, extractor.sampleTime, 0)
            extractor.advance()
        }
    }

    private fun drainOutput(): List<Float>? {
        val outputIndex = codec.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
        when {
            outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                updateOutputFormat(codec.outputFormat)
                return emptyList()
            }
            outputIndex < 0 -> return emptyList()
        }

        val outputBuffer = codec.getOutputBuffer(outputIndex)
        val samples = if (outputBuffer != null && bufferInfo.size > 0) {
            monoSamples(outputBuffer)
        } else {
            emptyList()
        }
        codec.releaseOutputBuffer(outputIndex, false)

        if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
            outputDone = true
        }
        return samples
    }

    private fun updateOutputFormat(format: MediaFormat) {
        outSampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        outChannelCount = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
    }

    /** Extracts channel-0 samples from a 16-bit signed LE interleaved PCM buffer. */
    private fun monoSamples(buffer: ByteBuffer): List<Float> {
        buffer.position(bufferInfo.offset)
        buffer.limit(bufferInfo.offset + bufferInfo.size)
        val shorts = buffer.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val channels = outChannelCount.coerceAtLeast(1)
        val frameCount = shorts.remaining() / channels
        val result = ArrayList<Float>(frameCount)
        for (frame in 0 until frameCount) {
            val sample = shorts.get(frame * channels) // channel 0
            result.add(sample / Short.MAX_VALUE.toFloat())
        }
        return result
    }

    override fun close() {
        runCatching { codec.stop() }
        runCatching { codec.release() }
        runCatching { extractor.release() }
    }

    private companion object {
        const val TIMEOUT_US = 10_000L
        const val MICROS_PER_SECOND = 1_000_000L
    }
}
