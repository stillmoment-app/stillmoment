package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformCacheServiceProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformGenerationServiceProtocol
import com.stillmoment.domain.services.WaveformProviderProtocol
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/**
 * Serves waveforms for meditations, backed by a cache and an on-demand generator
 * (shared-107).
 *
 * Concurrent requests for the same meditation share one in-flight generation, so the
 * post-import precompute and an editor opening never decode the same file twice.
 * Generation runs on [generationDispatcher] (IO by default), off the main thread.
 */
@Singleton
class WaveformProvider
@Inject
constructor(
    private val generationService: WaveformGenerationServiceProtocol,
    private val cacheService: WaveformCacheServiceProtocol,
    private val logger: LoggerProtocol,
    private val generationDispatcher: CoroutineDispatcher = Dispatchers.IO
) : WaveformProviderProtocol {
    private val inFlightMutex = Mutex()
    private val inFlight = mutableMapOf<String, Deferred<MeditationWaveform>>()
    private val precomputeScope = CoroutineScope(SupervisorJob() + generationDispatcher)

    override suspend fun waveform(meditation: GuidedMeditation): MeditationWaveform {
        // A cached entry from a build with a different resolution counts as a miss, so
        // old caches upgrade themselves on first use.
        cacheService.load(meditation.id)?.let { cached ->
            if (cached.samples.size == MeditationWaveform.SAMPLE_COUNT) {
                return cached
            }
        }

        val deferred = inFlightMutex.withLock {
            inFlight[meditation.id] ?: precomputeScope.async {
                generateAndCache(meditation)
            }.also { inFlight[meditation.id] = it }
        }

        return try {
            deferred.await()
        } finally {
            // Clear only after completion (incl. cache save) so a later concurrent caller
            // is served from the cache. The error path clears it too, allowing a retry.
            inFlightMutex.withLock {
                if (inFlight[meditation.id] === deferred) {
                    inFlight.remove(meditation.id)
                }
            }
        }
    }

    override fun precompute(meditation: GuidedMeditation) {
        precomputeScope.launch {
            try {
                waveform(meditation)
            } catch (e: CancellationException) {
                throw e
            } catch (e: WaveformGenerationException) {
                logger.e(TAG, "Waveform precompute failed for ${meditation.id}", e)
            }
        }
    }

    override fun removeCached(id: String) {
        cacheService.delete(id)
    }

    private suspend fun generateAndCache(meditation: GuidedMeditation): MeditationWaveform {
        val waveform = withContext(generationDispatcher) {
            generationService.generateWaveform(meditation.fileUri)
        }
        try {
            cacheService.save(meditation.id, waveform)
        } catch (e: IOException) {
            // Non-fatal: a failed cache write only means we regenerate next time.
            logger.e(TAG, "Failed to cache waveform for ${meditation.id}", e)
        }
        return waveform
    }

    private companion object {
        const val TAG = "WaveformProvider"
    }
}
