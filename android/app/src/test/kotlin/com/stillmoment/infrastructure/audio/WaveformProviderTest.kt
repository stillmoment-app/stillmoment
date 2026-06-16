package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for [WaveformProvider] — cache-first lookup, request deduplication,
 * precompute fire-and-forget, and removeCached. Uses fakes; no real audio.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class WaveformProviderTest {
    private val logger: LoggerProtocol = mock()

    @Test
    fun `serves a cached waveform without generating`() = runTest {
        val cache = FakeWaveformCacheService().apply {
            seed("med-1", MeditationWaveform(List(MeditationWaveform.SAMPLE_COUNT) { 0.3f }))
        }
        val generation = FakeWaveformGenerationService()
        val provider = WaveformProvider(generation, cache, logger, StandardTestDispatcher(testScheduler))

        val waveform = provider.waveform(waveformMeditation())

        assertEquals(0.3f, waveform.samples.first())
        assertEquals(0, generation.callCount.get())
    }

    @Test
    fun `treats a cached entry with the wrong sample count as a miss`() = runTest {
        val cache = FakeWaveformCacheService().apply {
            seed("med-1", MeditationWaveform(listOf(0.9f, 0.9f))) // stale resolution
        }
        val generation = FakeWaveformGenerationService()
        val provider = WaveformProvider(generation, cache, logger, StandardTestDispatcher(testScheduler))

        val waveform = provider.waveform(waveformMeditation())

        assertEquals(MeditationWaveform.SAMPLE_COUNT, waveform.samples.size)
        assertEquals(1, generation.callCount.get())
    }

    @Test
    fun `generates and caches on a miss`() = runTest {
        val cache = FakeWaveformCacheService()
        val generation = FakeWaveformGenerationService()
        val provider = WaveformProvider(generation, cache, logger, StandardTestDispatcher(testScheduler))

        provider.waveform(waveformMeditation())

        assertEquals(1, generation.callCount.get())
        assertEquals(1, cache.saveCount)
    }

    @Test
    fun `concurrent requests for the same meditation share one generation`() = runTest {
        val cache = FakeWaveformCacheService()
        val generation = FakeWaveformGenerationService().apply {
            heldGate = CompletableDeferred() // hold generation open
        }
        val provider = WaveformProvider(generation, cache, logger, StandardTestDispatcher(testScheduler))
        val meditation = waveformMeditation()

        val first = async { provider.waveform(meditation) }
        val second = async { provider.waveform(meditation) }
        advanceUntilIdle()

        generation.heldGate?.complete(Unit)
        first.await()
        second.await()

        assertEquals(1, generation.callCount.get())
    }

    @Test
    fun `clears the in-flight entry on failure so a retry generates again`() = runTest {
        val cache = FakeWaveformCacheService()
        val generation = FakeWaveformGenerationService(
            error = WaveformGenerationException.DecodingFailed("boom")
        )
        val provider = WaveformProvider(generation, cache, logger, StandardTestDispatcher(testScheduler))
        val meditation = waveformMeditation()

        val firstError = runCatching { provider.waveform(meditation) }.exceptionOrNull()
        val secondError = runCatching { provider.waveform(meditation) }.exceptionOrNull()

        assertTrue(firstError is WaveformGenerationException.DecodingFailed)
        assertTrue(secondError is WaveformGenerationException.DecodingFailed)
        assertEquals(2, generation.callCount.get())
    }

    @Test
    fun `precompute caches in the background without blocking`() = runTest {
        val cache = FakeWaveformCacheService()
        val generation = FakeWaveformGenerationService()
        val provider = WaveformProvider(generation, cache, logger, StandardTestDispatcher(testScheduler))

        provider.precompute(waveformMeditation())
        advanceUntilIdle()

        assertEquals(1, cache.saveCount)
    }

    @Test
    fun `removeCached deletes the cached entry`() = runTest {
        val cache = FakeWaveformCacheService().apply {
            seed("med-1", MeditationWaveform(listOf(0.5f)))
        }
        val provider = WaveformProvider(
            FakeWaveformGenerationService(),
            cache,
            logger,
            StandardTestDispatcher(testScheduler)
        )

        provider.removeCached("med-1")

        assertTrue(cache.deleted.contains("med-1"))
    }
}
