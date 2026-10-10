package com.stillmoment.data.repositories

import com.stillmoment.domain.services.AudioDurationProbe
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The play length of an imported custom audio file is detected after the file is
 * already listed (android-079). These tests describe what ends up in the list.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class CustomAudioDurationBackfillTest {
    private class ProbeStub(private val answer: suspend (String) -> Long?) : AudioDurationProbe {
        val probedPaths = mutableListOf<String>()

        override suspend fun durationMs(filePath: String): Long? {
            probedPaths += filePath
            return answer(filePath)
        }
    }

    private val storedDurations = mutableMapOf<String, Long>()

    private fun TestScope.backfill(probe: AudioDurationProbe, timeoutMs: Long = 10_000L) = CustomAudioDurationBackfill(
        probe = probe,
        storeDuration = { id, durationMs -> storedDurations[id] = durationMs },
        scope = backgroundScope,
        timeoutMs = timeoutMs
    )

    @Test
    fun `detected play length is added to the imported file`() = runTest {
        val probe = ProbeStub { 1_800_000L }

        backfill(probe).schedule(fileId = "rain", filePath = "/files/rain.mp3")
        runCurrent()

        assertEquals(1_800_000L, storedDurations["rain"])
        assertEquals(listOf("/files/rain.mp3"), probe.probedPaths)
    }

    @Test
    fun `play length stays empty when detection fails`() = runTest {
        backfill(ProbeStub { null }).schedule(fileId = "rain", filePath = "/files/rain.mp3")
        runCurrent()

        assertTrue(storedDurations.isEmpty())
    }

    @Test
    fun `play length stays empty when detection takes too long`() = runTest {
        val neverAnswers = CompletableDeferred<Long?>()
        val probe = ProbeStub { neverAnswers.await() }

        backfill(probe, timeoutMs = 5_000L).schedule(fileId = "rain", filePath = "/files/rain.mp3")
        advanceTimeBy(5_001L)
        runCurrent()
        neverAnswers.complete(1_800_000L)
        runCurrent()

        assertTrue(storedDurations.isEmpty())
    }
}
