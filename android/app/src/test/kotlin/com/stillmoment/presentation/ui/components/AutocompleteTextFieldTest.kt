package com.stillmoment.presentation.ui.components

import kotlinx.collections.immutable.persistentListOf
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for AutocompleteTextField filtering logic.
 */
class AutocompleteTextFieldTest {
    // MARK: - Filter Suggestions Tests

    @Nested
    inner class FilterSuggestionsTests {
        @Test
        fun `empty text returns empty list`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield", "Sharon Salzberg")
            val text = ""

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertTrue(result.isEmpty())
        }

        @Test
        fun `blank text returns empty list`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield")
            val text = "   "

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertTrue(result.isEmpty())
        }

        @Test
        fun `filters suggestions by case insensitive contains match`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield", "Sharon Salzberg")
            val text = "tar"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertEquals(1, result.size)
            assertEquals("Tara Brach", result[0])
        }

        @Test
        fun `filters with uppercase input works`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield")
            val text = "TARA"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertEquals(1, result.size)
            assertEquals("Tara Brach", result[0])
        }

        @Test
        fun `excludes exact matches ignoring case`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield")
            val text = "Tara Brach"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertTrue(result.isEmpty())
        }

        @Test
        fun `excludes exact matches with different case`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield")
            val text = "tara brach"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertTrue(result.isEmpty())
        }

        @Test
        fun `returns multiple matching suggestions`() {
            // Given
            val suggestions =
                persistentListOf("Tara Brach", "Jack Kornfield", "Sharon Salzberg", "Sam Harris")
            val text = "a"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertEquals(4, result.size)
            assertTrue(result.contains("Tara Brach"))
            assertTrue(result.contains("Jack Kornfield"))
            assertTrue(result.contains("Sharon Salzberg"))
            assertTrue(result.contains("Sam Harris"))
        }

        @Test
        fun `limits results to maximum 5 suggestions`() {
            // Given
            val suggestions =
                persistentListOf(
                    "Teacher 1",
                    "Teacher 2",
                    "Teacher 3",
                    "Teacher 4",
                    "Teacher 5",
                    "Teacher 6",
                    "Teacher 7"
                )
            val text = "Teacher"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertEquals(5, result.size)
        }

        @Test
        fun `returns empty list when no suggestions match`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield")
            val text = "xyz"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertTrue(result.isEmpty())
        }

        @Test
        fun `handles empty suggestions list`() {
            // Given
            val suggestions = persistentListOf<String>()
            val text = "test"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertTrue(result.isEmpty())
        }

        @Test
        fun `matches substring in middle of suggestion`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield")
            val text = "orn"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertEquals(1, result.size)
            assertEquals("Jack Kornfield", result[0])
        }

        @Test
        fun `matches at end of suggestion`() {
            // Given
            val suggestions = persistentListOf("Tara Brach", "Jack Kornfield")
            val text = "ach"

            // When
            val result = filterSuggestions(suggestions, text)

            // Then
            assertEquals(1, result.size)
            assertEquals("Tara Brach", result[0])
        }
    }
}
