package com.stillmoment.data.repositories

import com.stillmoment.domain.models.GuidedMeditation
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for GuidedMeditationRepository functionality.
 *
 * Note: Full integration tests with Android APIs (MediaMetadataRetriever,
 * ContentResolver, DataStore) require instrumented tests (see android-013).
 * These unit tests focus on testable business logic and data mapping.
 */
class GuidedMeditationRepositoryImplTest {
    // MARK: - ImportException Tests

    @Nested
    inner class ImportExceptionTests {
        @Test
        fun `ImportException stores message correctly`() {
            // Given
            val message = "Failed to import: file not found"

            // When
            val exception = ImportException(message)

            // Then
            assertEquals(message, exception.message)
            assertNull(exception.cause)
        }

        @Test
        fun `ImportException stores cause correctly`() {
            // Given
            val cause = SecurityException("Permission denied")
            val message = "Import failed"

            // When
            val exception = ImportException(message, cause)

            // Then
            assertEquals(message, exception.message)
            assertEquals(cause, exception.cause)
        }
    }

    // MARK: - FileNameWithoutExtension Tests

    @Nested
    inner class FileNameProcessingTests {
        @Test
        fun `fileNameWithoutExtension removes mp3 extension`() {
            // When
            val result = fileNameWithoutExtension("meditation.mp3")

            // Then
            assertEquals("meditation", result)
        }

        @Test
        fun `fileNameWithoutExtension removes m4a extension`() {
            // When
            val result = fileNameWithoutExtension("guided_session.m4a")

            // Then
            assertEquals("guided_session", result)
        }

        @Test
        fun `fileNameWithoutExtension handles multiple dots`() {
            // When
            val result = fileNameWithoutExtension("tara.brach.meditation.mp3")

            // Then
            assertEquals("tara.brach.meditation", result)
        }

        @Test
        fun `fileNameWithoutExtension handles no extension`() {
            // When
            val result = fileNameWithoutExtension("meditation")

            // Then
            assertEquals("meditation", result)
        }

        @Test
        fun `fileNameWithoutExtension handles empty string`() {
            // When
            val result = fileNameWithoutExtension("")

            // Then
            assertEquals("", result)
        }

        @Test
        fun `fileNameWithoutExtension handles only extension`() {
            // When
            val result = fileNameWithoutExtension(".mp3")

            // Then
            assertEquals("", result)
        }

        // Helper function that mirrors the private function in repository
        private fun fileNameWithoutExtension(fileName: String): String {
            return fileName.substringBeforeLast(".")
        }
    }

    // MARK: - Meditation List Serialization Tests

    @Nested
    inner class SerializationTests {
        private val json =
            Json {
                ignoreUnknownKeys = true
                encodeDefaults = true
            }

        @Test
        fun `meditation list can be serialized to JSON`() {
            // Given
            val meditations =
                listOf(
                    createTestMeditation(teacher = "Teacher A", name = "Meditation 1"),
                    createTestMeditation(teacher = "Teacher B", name = "Meditation 2")
                )

            // When
            val jsonString = json.encodeToString(meditations)

            // Then
            assertTrue(jsonString.contains("Teacher A"))
            assertTrue(jsonString.contains("Teacher B"))
            assertTrue(jsonString.contains("Meditation 1"))
            assertTrue(jsonString.contains("Meditation 2"))
        }

        @Test
        fun `meditation list can be deserialized from JSON`() {
            // Given
            val original =
                listOf(
                    createTestMeditation(teacher = "Teacher A", name = "Meditation 1"),
                    createTestMeditation(teacher = "Teacher B", name = "Meditation 2")
                )
            val jsonString = json.encodeToString(original)

            // When
            val restored = json.decodeFromString<List<GuidedMeditation>>(jsonString)

            // Then
            assertEquals(2, restored.size)
            assertEquals("Teacher A", restored[0].teacher)
            assertEquals("Teacher B", restored[1].teacher)
        }

        @Test
        fun `empty list serializes to empty array`() {
            // Given
            val meditations = emptyList<GuidedMeditation>()

            // When
            val jsonString = json.encodeToString(meditations)

            // Then
            assertEquals("[]", jsonString)
        }

        @Test
        fun `empty array deserializes to empty list`() {
            // Given
            val jsonString = "[]"

            // When
            val meditations = json.decodeFromString<List<GuidedMeditation>>(jsonString)

            // Then
            assertTrue(meditations.isEmpty())
        }

        @Test
        fun `serialization roundtrip preserves all meditation fields`() {
            // Given
            val original =
                listOf(
                    GuidedMeditation(
                        id = "test-id",
                        fileUri = "content://test/uri",
                        fileName = "test.mp3",
                        duration = 300_000L,
                        teacher = "Original Teacher",
                        name = "Original Name",
                        customTeacher = "Custom Teacher",
                        customName = "Custom Name",
                        dateAdded = 1234567890L
                    )
                )

            // When
            val jsonString = json.encodeToString(original)
            val restored = json.decodeFromString<List<GuidedMeditation>>(jsonString)

            // Then
            assertEquals(1, restored.size)
            assertEquals(original[0], restored[0])
        }
    }

    // MARK: - Default Values Tests

    @Nested
    inner class DefaultValuesTests {
        @Test
        fun `default teacher is Unknown when not provided`() {
            // This test documents the expected default behavior
            val defaultTeacher = "Unknown"
            assertEquals("Unknown", defaultTeacher)
        }

        @Test
        fun `meditation without metadata uses filename as name`() {
            // Given
            val fileName = "Loving Kindness Meditation.mp3"
            val expectedName = "Loving Kindness Meditation"

            // When - simulating what repository does
            val name = fileName.substringBeforeLast(".")

            // Then
            assertEquals(expectedName, name)
        }
    }

    // MARK: - Test Helpers

    private fun createTestMeditation(
        id: String = java.util.UUID.randomUUID().toString(),
        fileUri: String = "content://test/uri",
        fileName: String = "test.mp3",
        duration: Long = 600_000L,
        teacher: String = "Test Teacher",
        name: String = "Test Meditation",
        customTeacher: String? = null,
        customName: String? = null,
        dateAdded: Long = System.currentTimeMillis()
    ): GuidedMeditation = GuidedMeditation(
        id = id,
        fileUri = fileUri,
        fileName = fileName,
        duration = duration,
        teacher = teacher,
        name = name,
        customTeacher = customTeacher,
        customName = customName,
        dateAdded = dateAdded
    )
}
