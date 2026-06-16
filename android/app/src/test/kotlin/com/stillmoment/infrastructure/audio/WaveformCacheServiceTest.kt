package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.services.LoggerProtocol
import java.io.File
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for [WaveformCacheService] — JSON roundtrip in a temp directory.
 *
 * Mirrors iOS: one JSON file per meditation, loaded back identically; a missing entry
 * returns null and delete removes it.
 */
class WaveformCacheServiceTest {
    private lateinit var tempDir: File
    private lateinit var sut: WaveformCacheService
    private val logger: LoggerProtocol = mock()

    @BeforeEach
    fun setUp() {
        tempDir = File.createTempFile("waveforms", "").apply {
            delete()
            mkdirs()
        }
        sut = WaveformCacheService(directory = tempDir, logger = logger)
    }

    @AfterEach
    fun tearDown() {
        tempDir.deleteRecursively()
    }

    @Test
    fun `saves and loads a waveform unchanged`() {
        val waveform = MeditationWaveform(listOf(0.0f, 0.25f, 0.5f, 1.0f))

        sut.save("med-1", waveform)
        val loaded = sut.load("med-1")

        assertEquals(waveform, loaded)
    }

    @Test
    fun `returns null for an unknown meditation`() {
        assertNull(sut.load("missing"))
    }

    @Test
    fun `delete removes the cached entry`() {
        sut.save("med-1", MeditationWaveform(listOf(0.5f)))

        sut.delete("med-1")

        assertNull(sut.load("med-1"))
    }

    @Test
    fun `deleting a missing entry is a no-op`() {
        sut.delete("missing")

        assertNull(sut.load("missing"))
    }
}
