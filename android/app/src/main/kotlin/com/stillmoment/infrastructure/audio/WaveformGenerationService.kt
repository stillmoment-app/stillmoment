package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.models.WaveformAccumulator
import com.stillmoment.domain.services.AudioFrameReader
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformGenerationServiceProtocol
import javax.inject.Inject
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive

/**
 * Concrete [WaveformGenerationServiceProtocol] backed by an [AudioFrameReader] seam
 * (shared-107). The reader hides `MediaExtractor`/`MediaCodec`; this service only drives
 * the streaming loop, feeding each mono chunk to a [WaveformAccumulator]. The full file
 * is never held in memory at once, and the loop checks for cancellation between chunks.
 */
class WaveformGenerationService
@Inject
constructor(
    private val frameReader: AudioFrameReader,
    private val logger: LoggerProtocol
) : WaveformGenerationServiceProtocol {
    override suspend fun generateWaveform(uri: String): MeditationWaveform {
        currentCoroutineContext().ensureActive()

        val source = frameReader.open(uri)
        return source.use {
            val totalFrames = source.totalFrameCount
            if (totalFrames <= 0) {
                logger.w(TAG, "Waveform generation: file has no frames, returning empty waveform")
                return@use WaveformAccumulator(MeditationWaveform.SAMPLE_COUNT, totalFrameCount = 0)
                    .finalize()
            }

            val accumulator = WaveformAccumulator(
                bucketCount = MeditationWaveform.SAMPLE_COUNT,
                totalFrameCount = totalFrames
            )

            while (true) {
                currentCoroutineContext().ensureActive()
                val chunk = source.readChunk() ?: break
                if (chunk.isNotEmpty()) {
                    accumulator.append(chunk)
                }
            }

            logger.d(TAG, "Waveform generated for $uri ($totalFrames frames)")
            accumulator.finalize()
        }
    }

    private companion object {
        const val TAG = "WaveformGeneration"
    }
}
