package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for [WaveformGenerationService] driven by a fake [AudioFrameReader] —
 * no real audio decoding. Verifies the accumulator wiring: chunk streaming, bucket
 * peaks and normalization, and error mapping to [WaveformGenerationException].
 */
class WaveformGenerationServiceTest {
    private val logger = mock<LoggerProtocol>()

    private fun service(reader: FakeAudioFrameReader) = WaveformGenerationService(reader, logger)

    @Test
    fun `produces a full-resolution normalized waveform from streamed chunks`() = runTest {
        // Two halves of the file: first quiet, second loud. Expect a normalized result.
        val frames = 4_400
        val quiet = List(frames / 2) { 0.2f }
        val loud = List(frames / 2) { 0.8f }
        val reader = FakeAudioFrameReader(
            chunks = listOf(quiet, loud),
            totalFrameCount = frames
        )

        val waveform = service(reader).generateWaveform("content://test")

        assertEquals(MeditationWaveform.SAMPLE_COUNT, waveform.samples.size)
        // Loudest bar is normalized to 1.0; quiet bars are 0.25 of it.
        assertEquals(1.0f, waveform.samples.max())
        assertTrue(waveform.samples.first() in 0.24f..0.26f)
    }

    @Test
    fun `silent file yields an all-zero waveform`() = runTest {
        val reader = FakeAudioFrameReader(
            chunks = listOf(List(2_200) { 0.0f }),
            totalFrameCount = 2_200
        )

        val waveform = service(reader).generateWaveform("content://silent")

        assertEquals(MeditationWaveform.SAMPLE_COUNT, waveform.samples.size)
        assertTrue(waveform.samples.all { it == 0.0f })
    }

    @Test
    fun `empty file yields an all-zero waveform without crashing`() = runTest {
        val reader = FakeAudioFrameReader(chunks = emptyList(), totalFrameCount = 0)

        val waveform = service(reader).generateWaveform("content://empty")

        assertEquals(MeditationWaveform.SAMPLE_COUNT, waveform.samples.size)
        assertTrue(waveform.samples.all { it == 0.0f })
    }

    @Test
    fun `propagates a decoding failure as a generation exception`() = runTest {
        val reader = FakeAudioFrameReader(
            failOnOpen = WaveformGenerationException.FileNotAccessible()
        )

        val thrown = runCatching { service(reader).generateWaveform("content://gone") }
            .exceptionOrNull()

        assertTrue(thrown is WaveformGenerationException.FileNotAccessible)
    }
}
