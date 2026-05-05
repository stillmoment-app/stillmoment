package com.stillmoment.data.migration

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Pure-logic tests for the JSON filter in [AttunementCleanupMigration].
 *
 * Full integration (DataStore reads/writes, filesystem deletion) is exercised
 * by the production code path during the first app start after upgrade.
 * These tests focus on the riskiest piece: filtering raw JSON without crashing
 * even though the [com.stillmoment.domain.models.CustomAudioType.ATTUNEMENT]
 * enum entry has been removed.
 */
class AttunementCleanupMigrationTest {

    @Test
    fun `removes ATTUNEMENT entries and keeps SOUNDSCAPE entries`() {
        val input = """
            [
              {"id":"a","name":"Soundscape A","filename":"a.mp3","durationMs":1000,"type":"SOUNDSCAPE","dateAdded":1},
              {"id":"b","name":"Attunement B","filename":"b.mp3","durationMs":2000,"type":"ATTUNEMENT","dateAdded":2},
              {"id":"c","name":"Soundscape C","filename":"c.mp3","durationMs":3000,"type":"SOUNDSCAPE","dateAdded":3}
            ]
        """.trimIndent()

        val (output, removedCount) = AttunementCleanupMigration.filterAttunementEntries(input)

        assertEquals(1, removedCount)
        assertTrue(output.contains("\"id\":\"a\""))
        assertTrue(output.contains("\"id\":\"c\""))
        assertFalse(output.contains("ATTUNEMENT"))
        assertFalse(output.contains("\"id\":\"b\""))
    }

    @Test
    fun `keeps soundscapes when only attunements were present`() {
        val input = """
            [
              {"id":"a","name":"Attunement A","filename":"a.mp3","durationMs":1000,"type":"ATTUNEMENT","dateAdded":1}
            ]
        """.trimIndent()

        val (output, removedCount) = AttunementCleanupMigration.filterAttunementEntries(input)

        assertEquals(1, removedCount)
        assertEquals("[]", output.replace("\\s+".toRegex(), ""))
    }

    @Test
    fun `returns input unchanged when no attunements present`() {
        val input = """[{"id":"a","name":"A","filename":"a.mp3","durationMs":1,"type":"SOUNDSCAPE","dateAdded":1}]"""

        val (output, removedCount) = AttunementCleanupMigration.filterAttunementEntries(input)

        assertEquals(0, removedCount)
        assertTrue(output.contains("\"id\":\"a\""))
        assertTrue(output.contains("SOUNDSCAPE"))
    }

    @Test
    fun `returns empty array for empty input array`() {
        val (output, removedCount) = AttunementCleanupMigration.filterAttunementEntries("[]")

        assertEquals(0, removedCount)
        assertEquals("[]", output.replace("\\s+".toRegex(), ""))
    }

    @Test
    fun `is idempotent - running twice yields the same result`() {
        val input = """
            [
              {"id":"a","name":"Soundscape A","filename":"a.mp3","durationMs":1,"type":"SOUNDSCAPE","dateAdded":1},
              {"id":"b","name":"Attunement B","filename":"b.mp3","durationMs":2,"type":"ATTUNEMENT","dateAdded":2}
            ]
        """.trimIndent()

        val (firstOutput, firstRemoved) = AttunementCleanupMigration.filterAttunementEntries(input)
        val (secondOutput, secondRemoved) = AttunementCleanupMigration.filterAttunementEntries(firstOutput)

        assertEquals(1, firstRemoved)
        assertEquals(0, secondRemoved)
        assertEquals(firstOutput, secondOutput)
    }
}
