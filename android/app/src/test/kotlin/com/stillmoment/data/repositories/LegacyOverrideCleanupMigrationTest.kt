package com.stillmoment.data.repositories

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Pure-logic tests for [GuidedMeditationRepositoryImpl.foldLegacyOverrides].
 *
 * The migration folds the legacy override fields `customTeacher` / `customName`
 * (used before shared-103) into the canonical `teacher` / `name` slots and
 * strips the legacy keys. Sister test to [com.stillmoment.data.migration.AttunementCleanupMigrationTest]
 * — both focus on the JSON-rewrite step in isolation; the DataStore/flag
 * plumbing is exercised by the production code path on first app start.
 */
class LegacyOverrideCleanupMigrationTest {

    @Test
    fun `customTeacher overrides teacher and is dropped`() {
        val input = """
            [
              {"id":"a","fileUri":"f://a","fileName":"a.mp3","duration":1000,
               "teacher":"Y","name":"Body Scan","customTeacher":"X"}
            ]
        """.trimIndent()

        val output = GuidedMeditationRepositoryImpl.foldLegacyOverrides(input)

        assertNotNull(output)
        assertTrue(output!!.contains("\"teacher\":\"X\""))
        assertFalse(output.contains("customTeacher"))
        // unrelated fields stay intact
        assertTrue(output.contains("\"name\":\"Body Scan\""))
    }

    @Test
    fun `customName overrides name and is dropped`() {
        val input = """
            [
              {"id":"a","fileUri":"f://a","fileName":"a.mp3","duration":1000,
               "teacher":"Tara","name":"Original","customName":"Edited"}
            ]
        """.trimIndent()

        val output = GuidedMeditationRepositoryImpl.foldLegacyOverrides(input)

        assertNotNull(output)
        assertTrue(output!!.contains("\"name\":\"Edited\""))
        assertFalse(output.contains("customName"))
        // teacher untouched
        assertTrue(output.contains("\"teacher\":\"Tara\""))
    }

    @Test
    fun `entries without legacy keys stay untouched`() {
        val input = """
            [
              {"id":"a","fileUri":"f://a","fileName":"a.mp3","duration":1000,
               "teacher":"Tara","name":"Body Scan"}
            ]
        """.trimIndent()

        val output = GuidedMeditationRepositoryImpl.foldLegacyOverrides(input)

        // null signals "no rewrite needed" — caller skips the write
        assertNull(output)
    }

    @Test
    fun `blank customTeacher falls back to existing teacher`() {
        val input = """
            [
              {"id":"a","fileUri":"f://a","fileName":"a.mp3","duration":1000,
               "teacher":"Fallback","name":"X","customTeacher":""}
            ]
        """.trimIndent()

        val output = GuidedMeditationRepositoryImpl.foldLegacyOverrides(input)

        assertNotNull(output)
        // empty override -> teacher stays "Fallback", legacy key dropped
        assertTrue(output!!.contains("\"teacher\":\"Fallback\""))
        assertFalse(output.contains("customTeacher"))
    }

    @Test
    fun `second run on already-migrated JSON is a no-op`() {
        val original = """
            [
              {"id":"a","fileUri":"f://a","fileName":"a.mp3","duration":1000,
               "teacher":"Tara","name":"Body Scan","customTeacher":"Real Teacher"}
            ]
        """.trimIndent()

        val firstRun = GuidedMeditationRepositoryImpl.foldLegacyOverrides(original)
        assertNotNull(firstRun)

        val secondRun = GuidedMeditationRepositoryImpl.foldLegacyOverrides(firstRun!!)

        // second run returns null because no legacy keys are left
        assertNull(secondRun)
    }

    @Test
    fun `mixed list rewrites only entries with legacy keys`() {
        val input = """
            [
              {"id":"a","fileUri":"f://a","fileName":"a.mp3","duration":1000,
               "teacher":"Tara","name":"Plain"},
              {"id":"b","fileUri":"f://b","fileName":"b.mp3","duration":2000,
               "teacher":"Original","name":"Old","customTeacher":"New","customName":"Renamed"}
            ]
        """.trimIndent()

        val output = GuidedMeditationRepositoryImpl.foldLegacyOverrides(input)

        assertNotNull(output)
        // first entry unchanged content-wise
        assertTrue(output!!.contains("\"id\":\"a\""))
        assertTrue(output.contains("\"teacher\":\"Tara\""))
        // second entry folded
        assertTrue(output.contains("\"teacher\":\"New\""))
        assertTrue(output.contains("\"name\":\"Renamed\""))
        assertFalse(output.contains("customTeacher"))
        assertFalse(output.contains("customName"))
    }

    @Test
    fun `empty array returns null - nothing to migrate`() {
        val output = GuidedMeditationRepositoryImpl.foldLegacyOverrides("[]")

        // empty input -> no legacy keys -> no rewrite
        assertNull(output)
    }

    @Test
    fun `customTeacher equal to teacher still drops the legacy key`() {
        // When the user's override equals the original ID3 teacher, the
        // canonical schema still has to drop customTeacher.
        val input = """
            [
              {"id":"a","fileUri":"f://a","fileName":"a.mp3","duration":1000,
               "teacher":"Tara","name":"X","customTeacher":"Tara"}
            ]
        """.trimIndent()

        val output = GuidedMeditationRepositoryImpl.foldLegacyOverrides(input)

        assertNotNull(output)
        assertEquals(1, output!!.split("\"teacher\":\"Tara\"").size - 1)
        assertFalse(output.contains("customTeacher"))
    }
}
