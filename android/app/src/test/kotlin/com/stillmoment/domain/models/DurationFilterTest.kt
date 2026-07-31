package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Tests fuer den Dauer-Filter der Bibliothek (shared-081).
 *
 * Die Grenzen sind halboffen: 4:59 gehoert zu `bis 5 Min`, 5:00 zu `5–15 Min`.
 * Jede Dauer faellt in genau eine Stufe.
 */
class DurationFilterTest {
    @Nested
    inner class StepBoundaries {
        @Test
        fun `meditation just under five minutes falls into the shortest step`() {
            val duration = minutesAndSeconds(4, 59)

            assertTrue(DurationFilter.UP_TO_5.matches(duration))
            assertFalse(DurationFilter.FROM_5_TO_15.matches(duration))
        }

        @Test
        fun `meditation of exactly five minutes falls into the second step`() {
            val duration = minutesAndSeconds(5, 0)

            assertFalse(DurationFilter.UP_TO_5.matches(duration))
            assertTrue(DurationFilter.FROM_5_TO_15.matches(duration))
        }

        @Test
        fun `meditation just under fifteen minutes stays in the second step`() {
            val duration = minutesAndSeconds(14, 59)

            assertTrue(DurationFilter.FROM_5_TO_15.matches(duration))
            assertFalse(DurationFilter.FROM_15_TO_30.matches(duration))
        }

        @Test
        fun `meditation of exactly fifteen minutes falls into the third step`() {
            val duration = minutesAndSeconds(15, 0)

            assertFalse(DurationFilter.FROM_5_TO_15.matches(duration))
            assertTrue(DurationFilter.FROM_15_TO_30.matches(duration))
        }

        @Test
        fun `meditation just under thirty minutes stays in the third step`() {
            val duration = minutesAndSeconds(29, 59)

            assertTrue(DurationFilter.FROM_15_TO_30.matches(duration))
            assertFalse(DurationFilter.OVER_30.matches(duration))
        }

        @Test
        fun `meditation of exactly thirty minutes falls into the longest step`() {
            val duration = minutesAndSeconds(30, 0)

            assertFalse(DurationFilter.FROM_15_TO_30.matches(duration))
            assertTrue(DurationFilter.OVER_30.matches(duration))
        }

        @Test
        fun `the All step matches every duration`() {
            val durations = listOf(0L, minutesAndSeconds(4, 59), minutesAndSeconds(30, 0), minutesAndSeconds(120, 0))

            durations.forEach { duration ->
                assertTrue(DurationFilter.ALL.matches(duration), "`Alle` muss ${duration}ms einschliessen")
            }
        }
    }

    @Nested
    inner class FilteringALibrary {
        @Test
        fun `applying a step keeps only the matching meditations in order`() {
            val filtered = DurationFilter.FROM_5_TO_15.apply(libraryAtEveryBoundary())

            assertEquals(listOf("05:00", "14:59"), filtered.map { it.name })
        }

        @Test
        fun `applying All keeps the whole library in order`() {
            val library = libraryAtEveryBoundary()

            val filtered = DurationFilter.ALL.apply(library)

            assertEquals(library.map { it.name }, filtered.map { it.name })
        }

        @Test
        fun `a trimmed meditation is filtered by the duration shown in the list`() {
            // 42-Minuten-Datei, auf 12 Minuten getrimmt — die Liste zeigt 12:00.
            val trimmed = meditation(
                name = "Getrimmt",
                durationMs = minutesAndSeconds(42, 0),
                trimStartMs = 0L,
                trimEndMs = minutesAndSeconds(12, 0)
            )

            assertEquals(listOf("Getrimmt"), DurationFilter.FROM_5_TO_15.apply(listOf(trimmed)).map { it.name })
            assertTrue(DurationFilter.OVER_30.apply(listOf(trimmed)).isEmpty())
        }
    }

    @Nested
    inner class AvailableSteps {
        @Test
        fun `a step without any meditation is not available`() {
            // Kuerzeste Meditation ist 5:00 — die Stufe „bis 5 Min" bleibt leer.
            val library = listOf(
                meditation(durationMs = minutesAndSeconds(5, 0)),
                meditation(durationMs = minutesAndSeconds(20, 0))
            )

            val available = DurationFilter.availableSteps(library)

            assertFalse(available.contains(DurationFilter.UP_TO_5))
            assertTrue(available.contains(DurationFilter.FROM_5_TO_15))
            assertTrue(available.contains(DurationFilter.FROM_15_TO_30))
            assertFalse(available.contains(DurationFilter.OVER_30))
        }

        @Test
        fun `a library covering every step makes all steps available`() {
            val available = DurationFilter.availableSteps(libraryAtEveryBoundary())

            assertEquals(DurationFilter.entries.toSet(), available)
        }

        @Test
        fun `the All step is always available`() {
            assertTrue(DurationFilter.availableSteps(libraryAtEveryBoundary()).contains(DurationFilter.ALL))
            assertTrue(DurationFilter.availableSteps(emptyList()).contains(DurationFilter.ALL))
        }

        @Test
        fun `an empty library leaves only the All step`() {
            assertEquals(setOf(DurationFilter.ALL), DurationFilter.availableSteps(emptyList()))
        }
    }

    // MARK: - Test helpers

    /** Bibliothek mit je einer Meditation an jeder Stufengrenze. */
    private fun libraryAtEveryBoundary(): List<GuidedMeditation> =
        listOf(4 to 59, 5 to 0, 14 to 59, 15 to 0, 29 to 59, 30 to 0).map { (minutes, seconds) ->
            meditation(
                name = String.format(java.util.Locale.ROOT, "%02d:%02d", minutes, seconds),
                durationMs = minutesAndSeconds(minutes, seconds)
            )
        }

    private fun minutesAndSeconds(minutes: Int, seconds: Int): Long = (minutes * 60L + seconds) * 1000L

    private fun meditation(
        name: String = "Test Meditation",
        durationMs: Long,
        trimStartMs: Long? = null,
        trimEndMs: Long? = null
    ): GuidedMeditation = GuidedMeditation(
        fileUri = "content://test/uri",
        fileName = "test.mp3",
        duration = durationMs,
        teacher = "Tara Brach",
        name = name,
        trimStartMs = trimStartMs,
        trimEndMs = trimEndMs
    )
}
