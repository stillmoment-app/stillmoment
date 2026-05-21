package com.stillmoment.domain.services

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [SearchHistory] pure-function logic (shared-101).
 */
class SearchHistoryTest {
    private val limit = 6

    @Nested
    inner class Prepend {
        @Test
        fun `empty term leaves history unchanged`() {
            val history = listOf("Atem")
            assertEquals(history, SearchHistory.prepend(history, "", limit))
            assertEquals(history, SearchHistory.prepend(history, "   ", limit))
        }

        @Test
        fun `adds new term at the top`() {
            val result = SearchHistory.prepend(listOf("Atem", "Tara"), "Body", limit)
            assertEquals(listOf("Body", "Atem", "Tara"), result)
        }

        @Test
        fun `trims whitespace from term`() {
            val result = SearchHistory.prepend(emptyList(), "  Atem  ", limit)
            assertEquals(listOf("Atem"), result)
        }

        @Test
        fun `duplicate moves to top with new casing`() {
            val result = SearchHistory.prepend(listOf("Atem", "Tara"), "ATEM", limit)
            assertEquals(listOf("ATEM", "Tara"), result)
        }

        @Test
        fun `dedup is diacritic insensitive`() {
            val result = SearchHistory.prepend(listOf("Übung", "Tara"), "Ubung", limit)
            assertEquals(listOf("Ubung", "Tara"), result)
        }

        @Test
        fun `respects FIFO cap`() {
            val full = listOf("a", "b", "c", "d", "e", "f")
            val result = SearchHistory.prepend(full, "g", limit)
            assertEquals(listOf("g", "a", "b", "c", "d", "e"), result)
            assertEquals(limit, result.size)
        }
    }

    @Nested
    inner class Normalize {
        @Test
        fun `lowercases ascii`() {
            assertEquals("atem", SearchHistory.normalize("Atem"))
        }

        @Test
        fun `strips diacritics`() {
            assertEquals("ubung", SearchHistory.normalize("Übung"))
        }

        @Test
        fun `combination strips and lowercases`() {
            assertEquals("ubung", SearchHistory.normalize("ÜBUNG"))
        }
    }
}
