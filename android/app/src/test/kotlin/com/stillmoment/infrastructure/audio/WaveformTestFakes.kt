package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.services.AudioFrameReader
import com.stillmoment.domain.services.AudioFrameSource
import com.stillmoment.domain.services.WaveformCacheServiceProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformGenerationServiceProtocol
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.CompletableDeferred

/** Builds a minimal [GuidedMeditation] for waveform tests. */
internal fun waveformMeditation(id: String = "med-1", uri: String = "content://test/audio", duration: Long = 600_000L) =
    GuidedMeditation(
        id = id,
        fileUri = uri,
        fileName = "test.mp3",
        duration = duration,
        teacher = "Teacher",
        name = "Name"
    )

/**
 * Fake [AudioFrameReader] serving canned mono chunks — no real decoding.
 *
 * @param chunks Mono sample chunks returned in order; an empty list models a silent file.
 * @param failOnOpen When set, [open] throws this instead of returning a source.
 */
internal class FakeAudioFrameReader(
    private val chunks: List<List<Float>> = emptyList(),
    private val sampleRate: Int = 44_100,
    private val channelCount: Int = 1,
    private val totalFrameCount: Int = chunks.sumOf { it.size },
    private val failOnOpen: WaveformGenerationException? = null
) : AudioFrameReader {
    var openCount = 0
        private set

    override fun open(uri: String): AudioFrameSource {
        openCount++
        failOnOpen?.let { throw it }
        return FakeSource(chunks, sampleRate, channelCount, totalFrameCount)
    }

    private class FakeSource(
        chunks: List<List<Float>>,
        override val sampleRate: Int,
        override val channelCount: Int,
        override val totalFrameCount: Int
    ) : AudioFrameSource {
        private val iterator = chunks.iterator()
        var closed = false
            private set

        override fun readChunk(): List<Float>? = if (iterator.hasNext()) iterator.next() else null

        override fun close() {
            closed = true
        }
    }
}

/** In-memory cache fake recording saves/loads/deletes. */
internal class FakeWaveformCacheService : WaveformCacheServiceProtocol {
    private val store = mutableMapOf<String, MeditationWaveform>()
    var saveCount = 0
        private set
    val deleted = mutableListOf<String>()

    fun seed(id: String, waveform: MeditationWaveform) {
        store[id] = waveform
    }

    override fun load(id: String): MeditationWaveform? = store[id]

    override fun save(id: String, waveform: MeditationWaveform) {
        saveCount++
        store[id] = waveform
    }

    override fun delete(id: String) {
        deleted += id
        store.remove(id)
    }
}

/**
 * Generation fake counting invocations. By default returns a full-resolution waveform.
 * [gate] lets a test hold generation open to exercise in-flight deduplication.
 */
internal class FakeWaveformGenerationService(
    private val result: MeditationWaveform =
        MeditationWaveform(List(MeditationWaveform.SAMPLE_COUNT) { 0.5f }),
    private val error: WaveformGenerationException? = null
) : WaveformGenerationServiceProtocol {
    val callCount = AtomicInteger(0)
    val gate = CompletableDeferred<Unit>().also { it.complete(Unit) }
    var heldGate: CompletableDeferred<Unit>? = null

    override suspend fun generateWaveform(uri: String): MeditationWaveform {
        callCount.incrementAndGet()
        heldGate?.await()
        error?.let { throw it }
        return result
    }
}
