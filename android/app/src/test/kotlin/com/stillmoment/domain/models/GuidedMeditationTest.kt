package com.stillmoment.domain.models

import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for GuidedMeditation and GuidedMeditationGroup domain models.
 */
class GuidedMeditationTest {
    // MARK: - GuidedMeditation Tests

    @Nested
    inner class GuidedMeditationCreation {
        @Test
        fun `create meditation with all fields succeeds`() {
            // Given
            val fileUri = "content://media/external/audio/media/123"
            val fileName = "meditation.mp3"
            val duration = 600_000L // 10 minutes
            val teacher = "Tara Brach"
            val name = "Loving Kindness"

            // When
            val meditation =
                GuidedMeditation(
                    fileUri = fileUri,
                    fileName = fileName,
                    duration = duration,
                    teacher = teacher,
                    name = name
                )

            // Then
            assertNotNull(meditation.id)
            assertEquals(fileUri, meditation.fileUri)
            assertEquals(fileName, meditation.fileName)
            assertEquals(duration, meditation.duration)
            assertEquals(teacher, meditation.teacher)
            assertEquals(name, meditation.name)
            assertTrue(meditation.dateAdded > 0)
        }

        @Test
        fun `meditation generates unique id by default`() {
            // Given/When
            val meditation1 = createTestMeditation()
            val meditation2 = createTestMeditation()

            // Then
            assertNotEquals(meditation1.id, meditation2.id)
        }
    }

    @Nested
    inner class FormattedDuration {
        @Test
        fun `formats duration under one hour correctly`() {
            // Given - 10 minutes 30 seconds = 630,000 ms
            val meditation = createTestMeditation(duration = 630_000L)

            // When/Then
            assertEquals("10:30", meditation.formattedDuration)
        }

        @Test
        fun `formats duration with leading zeros for seconds`() {
            // Given - 5 minutes 5 seconds = 305,000 ms
            val meditation = createTestMeditation(duration = 305_000L)

            // When/Then
            assertEquals("5:05", meditation.formattedDuration)
        }

        @Test
        fun `formats duration over one hour correctly`() {
            // Given - 1 hour 25 minutes 30 seconds = 5,130,000 ms
            val meditation = createTestMeditation(duration = 5_130_000L)

            // When/Then
            assertEquals("1:25:30", meditation.formattedDuration)
        }

        @Test
        fun `formats zero duration correctly`() {
            // Given
            val meditation = createTestMeditation(duration = 0L)

            // When/Then
            assertEquals("0:00", meditation.formattedDuration)
        }

        @Test
        fun `formats duration less than one minute correctly`() {
            // Given - 45 seconds = 45,000 ms
            val meditation = createTestMeditation(duration = 45_000L)

            // When/Then
            assertEquals("0:45", meditation.formattedDuration)
        }
    }

    @Nested
    inner class Serialization {
        @Test
        fun `meditation can be serialized to JSON`() {
            // Given
            val meditation =
                createTestMeditation(
                    teacher = "Test Teacher",
                    name = "Test Meditation"
                )

            // When
            val json = Json.encodeToString(meditation)

            // Then
            assertTrue(json.contains("Test Teacher"))
            assertTrue(json.contains("Test Meditation"))
        }

        @Test
        fun `meditation can be deserialized from JSON`() {
            // Given
            val original =
                createTestMeditation(
                    teacher = "Test Teacher",
                    name = "Test Meditation"
                )
            val json = Json.encodeToString(original)

            // When
            val restored = Json.decodeFromString<GuidedMeditation>(json)

            // Then
            assertEquals(original.id, restored.id)
            assertEquals(original.fileUri, restored.fileUri)
            assertEquals(original.teacher, restored.teacher)
            assertEquals(original.name, restored.name)
            assertEquals(original.duration, restored.duration)
        }

        @Test
        fun `serialization roundtrip preserves all fields`() {
            // Given
            val original =
                GuidedMeditation(
                    id = "test-id-123",
                    fileUri = "content://test/uri",
                    fileName = "test.mp3",
                    duration = 300_000L,
                    teacher = "Teacher",
                    name = "Name",
                    dateAdded = 1234567890L
                )

            // When
            val json = Json.encodeToString(original)
            val restored = Json.decodeFromString<GuidedMeditation>(json)

            // Then
            assertEquals(original, restored)
        }
    }

    // MARK: - GuidedMeditationGroup Tests

    @Nested
    inner class GuidedMeditationGroupTests {
        @Test
        fun `group count returns correct number of meditations`() {
            // Given
            val meditations =
                listOf(
                    createTestMeditation(name = "Meditation 1"),
                    createTestMeditation(name = "Meditation 2"),
                    createTestMeditation(name = "Meditation 3")
                )
            val group = GuidedMeditationGroup("Teacher", meditations)

            // When/Then
            assertEquals(3, group.count)
        }
    }

    // MARK: - groupByTeacher Extension Tests

    @Nested
    inner class GroupByTeacherTests {
        @Test
        fun `groupByTeacher groups meditations by teacher`() {
            // Given
            val meditations =
                listOf(
                    createTestMeditation(teacher = "Teacher A", name = "Med 1"),
                    createTestMeditation(teacher = "Teacher B", name = "Med 2"),
                    createTestMeditation(teacher = "Teacher A", name = "Med 3")
                )

            // When
            val groups = meditations.groupByTeacher()

            // Then
            assertEquals(2, groups.size)
            assertEquals("Teacher A", groups[0].teacher)
            assertEquals(2, groups[0].count)
            assertEquals("Teacher B", groups[1].teacher)
            assertEquals(1, groups[1].count)
        }

        @Test
        fun `groupByTeacher sorts groups alphabetically by teacher`() {
            // Given
            val meditations =
                listOf(
                    createTestMeditation(teacher = "Zebra"),
                    createTestMeditation(teacher = "Alpha"),
                    createTestMeditation(teacher = "Middle")
                )

            // When
            val groups = meditations.groupByTeacher()

            // Then
            assertEquals("Alpha", groups[0].teacher)
            assertEquals("Middle", groups[1].teacher)
            assertEquals("Zebra", groups[2].teacher)
        }

        @Test
        fun `groupByTeacher sorts meditations within group by name`() {
            // Given
            val meditations =
                listOf(
                    createTestMeditation(teacher = "Teacher", name = "Zebra"),
                    createTestMeditation(teacher = "Teacher", name = "Alpha"),
                    createTestMeditation(teacher = "Teacher", name = "Middle")
                )

            // When
            val groups = meditations.groupByTeacher()

            // Then
            assertEquals(1, groups.size)
            assertEquals("Alpha", groups[0].meditations[0].name)
            assertEquals("Middle", groups[0].meditations[1].name)
            assertEquals("Zebra", groups[0].meditations[2].name)
        }

        @Test
        fun `groupByTeacher returns empty list for empty input`() {
            // Given
            val meditations = emptyList<GuidedMeditation>()

            // When
            val groups = meditations.groupByTeacher()

            // Then
            assertTrue(groups.isEmpty())
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
        dateAdded: Long = System.currentTimeMillis()
    ): GuidedMeditation = GuidedMeditation(
        id = id,
        fileUri = fileUri,
        fileName = fileName,
        duration = duration,
        teacher = teacher,
        name = name,
        dateAdded = dateAdded
    )
}
