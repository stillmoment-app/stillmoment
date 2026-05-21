package com.stillmoment.domain.services

import com.stillmoment.domain.models.GuidedMeditation
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [LibrarySearchEngine].
 *
 * Verifies the pure Such-Engine: Token-Splitting, Diakritika-Normalisierung,
 * Multi-Token-UND, Substring-Match, Rangfolge der vier Buckets, Tiebreaker nach `dateAdded`,
 * Highlight-Ranges-Merging.
 */
class LibrarySearchEngineTest {
    private fun meditation(
        id: String = "m-${counter++}",
        name: String,
        teacher: String,
        dateAdded: Long = 1_000L
    ): GuidedMeditation = GuidedMeditation(
        id = id,
        fileUri = "content://test/$id",
        fileName = "$id.mp3",
        duration = 600_000L,
        teacher = teacher,
        name = name,
        dateAdded = dateAdded
    )

    @Nested
    inner class Tokens {
        @Test
        fun `empty query yields no tokens`() {
            assertEquals(emptyList<String>(), LibrarySearchEngine.tokens(""))
            assertEquals(emptyList<String>(), LibrarySearchEngine.tokens("   "))
        }

        @Test
        fun `splits on whitespace`() {
            assertEquals(listOf("tara", "body"), LibrarySearchEngine.tokens("tara body"))
        }

        @Test
        fun `collapses multiple whitespace`() {
            assertEquals(listOf("a", "b"), LibrarySearchEngine.tokens("  a   b  "))
        }
    }

    @Nested
    inner class Search {
        @Test
        fun `empty query returns empty list`() {
            val items = listOf(meditation(name = "Atem", teacher = "Tara"))
            assertEquals(emptyList<GuidedMeditation>(), LibrarySearchEngine.search(items, ""))
        }

        @Test
        fun `case insensitive match in title`() {
            val item = meditation(name = "Atemmeditation", teacher = "Tara Brach")
            val result = LibrarySearchEngine.search(listOf(item), "ATEM")
            assertEquals(listOf(item), result)
        }

        @Test
        fun `diacritic insensitive match in title`() {
            val item = meditation(name = "Übung im Loslassen", teacher = "Tara Brach")
            val result = LibrarySearchEngine.search(listOf(item), "ubung")
            assertEquals(listOf(item), result)
        }

        @Test
        fun `substring match in middle of word`() {
            // "ara" liegt mittendrin in "Tara" (Position 1..3)
            val item = meditation(name = "Tara Brach", teacher = "Tara Brach")
            val result = LibrarySearchEngine.search(listOf(item), "ara")
            assertEquals(listOf(item), result)
        }

        @Test
        fun `match in teacher name`() {
            val item = meditation(name = "Body Scan", teacher = "Elisabeth Slator")
            val result = LibrarySearchEngine.search(listOf(item), "slat")
            assertEquals(listOf(item), result)
        }

        @Test
        fun `multi token AND filters items missing any token`() {
            val match = meditation(id = "match", name = "Body Scan", teacher = "Tara Brach")
            val miss = meditation(id = "miss", name = "Atemmeditation", teacher = "Tara Brach")

            val result = LibrarySearchEngine.search(listOf(match, miss), "tara body")
            assertEquals(listOf(match), result)
        }

        @Test
        fun `ranks word-start title before word-start teacher`() {
            val titleStart = meditation(id = "title", name = "Atemraum", teacher = "Tara")
            val teacherStart = meditation(id = "teacher", name = "Body Scan", teacher = "Atem Lehrer")

            val result = LibrarySearchEngine.search(listOf(teacherStart, titleStart), "Atem")
            assertEquals(listOf(titleStart, teacherStart), result)
        }

        @Test
        fun `ranks all four buckets in order`() {
            val wordStartTitle = meditation(id = "1", name = "Atem fliesst", teacher = "Other")
            val wordStartTeacher = meditation(id = "2", name = "Body Scan", teacher = "Atem Person")
            val substringTitle = meditation(id = "3", name = "Pratemmacher", teacher = "Other")
            val substringTeacher = meditation(id = "4", name = "Body Scan", teacher = "Pratemson")

            val result = LibrarySearchEngine.search(
                listOf(substringTeacher, substringTitle, wordStartTeacher, wordStartTitle),
                "Atem"
            )
            assertEquals(listOf(wordStartTitle, wordStartTeacher, substringTitle, substringTeacher), result)
        }

        @Test
        fun `tiebreak by dateAdded descending`() {
            val older = meditation(id = "older", name = "Atem A", teacher = "T", dateAdded = 1_000L)
            val newer = meditation(id = "newer", name = "Atem B", teacher = "T", dateAdded = 2_000L)

            val result = LibrarySearchEngine.search(listOf(older, newer), "atem")
            assertEquals(listOf(newer, older), result)
        }

        @Test
        fun `multi token best match wins per meditation`() {
            // best-match-wins: pro Meditation gewinnt der kleinste (beste) Bucket ueber alle Tokens.
            //
            // Meditation A: "Tara Body" / "Anyone"
            //   - "tara" passt am Wortanfang im Titel → Bucket 0
            //   - "body" passt am Wortanfang im Titel → Bucket 0  → best = 0
            //
            // Meditation B: "Body Scan" / "Tara Brach"
            //   - "tara" passt am Wortanfang im Teacher → Bucket 1
            //   - "body" passt am Wortanfang im Titel → Bucket 0  → best = 0
            //
            // Beide haben best=0; Tiebreaker dateAdded entscheidet — neuere zuerst.
            val newer = meditation(id = "newer", name = "Tara Body", teacher = "Anyone", dateAdded = 2_000L)
            val older = meditation(id = "older", name = "Body Scan", teacher = "Tara Brach", dateAdded = 1_000L)

            val result = LibrarySearchEngine.search(listOf(older, newer), "tara body")
            assertEquals(listOf(newer, older), result)
        }
    }

    @Nested
    inner class HighlightRanges {
        @Test
        fun `empty query yields no ranges`() {
            assertEquals(emptyList<IntRange>(), LibrarySearchEngine.highlightRanges("Tara Brach", ""))
        }

        @Test
        fun `finds single occurrence`() {
            val ranges = LibrarySearchEngine.highlightRanges("Tara Brach", "tara")
            assertEquals(listOf(0..3), ranges)
        }

        @Test
        fun `finds multiple non-overlapping occurrences`() {
            val ranges = LibrarySearchEngine.highlightRanges("Tara and Tara", "tara")
            assertEquals(listOf(0..3, 9..12), ranges)
        }

        @Test
        fun `merges overlapping ranges from multiple tokens`() {
            // tokens "tara" und "ara" ueberlappen in "Tara"
            val ranges = LibrarySearchEngine.highlightRanges("Tara", "tara ara")
            assertEquals(listOf(0..3), ranges)
        }

        @Test
        fun `merges touching ranges`() {
            // "ta" + "ra" zusammen ergeben einen zusammenhaengenden Range
            val ranges = LibrarySearchEngine.highlightRanges("Tara", "ta ra")
            assertEquals(listOf(0..3), ranges)
        }

        @Test
        fun `case insensitive ranges`() {
            val ranges = LibrarySearchEngine.highlightRanges("TARA brach", "tara")
            assertEquals(listOf(0..3), ranges)
        }

        @Test
        fun `diacritic insensitive ranges`() {
            // "Übung" -> Folded "ubung" — Match auf Original-Indizes 0..4
            val text = "Übung"
            val ranges = LibrarySearchEngine.highlightRanges(text, "ubung")
            assertEquals(1, ranges.size)
            val range = ranges.first()
            // Substring "Übung" beginnt bei 0 und endet bei 4 (5 Chars)
            assertEquals(0, range.first)
            assertEquals(4, range.last)
            assertEquals("Übung", text.substring(range.first, range.last + 1))
        }
    }

    companion object {
        private var counter = 0
    }
}
