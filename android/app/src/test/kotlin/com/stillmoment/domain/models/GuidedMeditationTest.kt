package com.stillmoment.domain.models

import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
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
                    name = name,
                )

            // Then
            assertNotNull(meditation.id)
            assertEquals(fileUri, meditation.fileUri)
            assertEquals(fileName, meditation.fileName)
            assertEquals(duration, meditation.duration)
            assertEquals(teacher, meditation.teacher)
            assertEquals(name, meditation.name)
            assertNull(meditation.customTeacher)
            assertNull(meditation.customName)
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
    inner class EffectiveValues {
        @Test
        fun `effectiveTeacher returns original when no custom set`() {
            // Given
            val meditation = createTestMeditation(teacher = "Original Teacher")

            // When/Then
            assertEquals("Original Teacher", meditation.effectiveTeacher)
        }

        @Test
        fun `effectiveTeacher returns custom when set`() {
            // Given
            val meditation =
                createTestMeditation(
                    teacher = "Original Teacher",
                    customTeacher = "Custom Teacher",
                )

            // When/Then
            assertEquals("Custom Teacher", meditation.effectiveTeacher)
        }

        @Test
        fun `effectiveName returns original when no custom set`() {
            // Given
            val meditation = createTestMeditation(name = "Original Name")

            // When/Then
            assertEquals("Original Name", meditation.effectiveName)
        }

        @Test
        fun `effectiveName returns custom when set`() {
            // Given
            val meditation =
                createTestMeditation(
                    name = "Original Name",
                    customName = "Custom Name",
                )

            // When/Then
            assertEquals("Custom Name", meditation.effectiveName)
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
    inner class WithMethods {
        @Test
        fun `withCustomTeacher creates copy with new teacher`() {
            // Given
            val original = createTestMeditation(teacher = "Original")

            // When
            val updated = original.withCustomTeacher("Custom")

            // Then
            assertEquals("Custom", updated.customTeacher)
            assertEquals("Custom", updated.effectiveTeacher)
            assertEquals(original.id, updated.id) // Same ID
            assertEquals(original.teacher, updated.teacher) // Original unchanged
        }

        @Test
        fun `withCustomTeacher with null clears custom teacher`() {
            // Given
            val original = createTestMeditation(customTeacher = "Custom")

            // When
            val updated = original.withCustomTeacher(null)

            // Then
            assertNull(updated.customTeacher)
            assertEquals(original.teacher, updated.effectiveTeacher)
        }

        @Test
        fun `withCustomName creates copy with new name`() {
            // Given
            val original = createTestMeditation(name = "Original")

            // When
            val updated = original.withCustomName("Custom")

            // Then
            assertEquals("Custom", updated.customName)
            assertEquals("Custom", updated.effectiveName)
            assertEquals(original.id, updated.id) // Same ID
            assertEquals(original.name, updated.name) // Original unchanged
        }

        @Test
        fun `withCustomName with null clears custom name`() {
            // Given
            val original = createTestMeditation(customName = "Custom")

            // When
            val updated = original.withCustomName(null)

            // Then
            assertNull(updated.customName)
            assertEquals(original.name, updated.effectiveName)
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
                    name = "Test Meditation",
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
                    name = "Test Meditation",
                    customTeacher = "Custom Teacher",
                )
            val json = Json.encodeToString(original)

            // When
            val restored = Json.decodeFromString<GuidedMeditation>(json)

            // Then
            assertEquals(original.id, restored.id)
            assertEquals(original.fileUri, restored.fileUri)
            assertEquals(original.teacher, restored.teacher)
            assertEquals(original.name, restored.name)
            assertEquals(original.customTeacher, restored.customTeacher)
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
                    customTeacher = "Custom Teacher",
                    customName = "Custom Name",
                    dateAdded = 1234567890L,
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
                    createTestMeditation(name = "Meditation 3"),
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
        fun `groupByTeacher groups meditations by effective teacher`() {
            // Given
            val meditations =
                listOf(
                    createTestMeditation(teacher = "Teacher A", name = "Med 1"),
                    createTestMeditation(teacher = "Teacher B", name = "Med 2"),
                    createTestMeditation(teacher = "Teacher A", name = "Med 3"),
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
        fun `groupByTeacher uses customTeacher when set`() {
            // Given
            val meditations =
                listOf(
                    createTestMeditation(teacher = "Original", customTeacher = "Custom A"),
                    createTestMeditation(teacher = "Original", customTeacher = "Custom B"),
                    createTestMeditation(teacher = "Original"),
                )

            // When
            val groups = meditations.groupByTeacher()

            // Then
            assertEquals(3, groups.size)
            assertTrue(groups.any { it.teacher == "Custom A" })
            assertTrue(groups.any { it.teacher == "Custom B" })
            assertTrue(groups.any { it.teacher == "Original" })
        }

        @Test
        fun `groupByTeacher sorts groups alphabetically by teacher`() {
            // Given
            val meditations =
                listOf(
                    createTestMeditation(teacher = "Zebra"),
                    createTestMeditation(teacher = "Alpha"),
                    createTestMeditation(teacher = "Middle"),
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
                    createTestMeditation(teacher = "Teacher", name = "Middle"),
                )

            // When
            val groups = meditations.groupByTeacher()

            // Then
            assertEquals(1, groups.size)
            assertEquals("Alpha", groups[0].meditations[0].effectiveName)
            assertEquals("Middle", groups[0].meditations[1].effectiveName)
            assertEquals("Zebra", groups[0].meditations[2].effectiveName)
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
        duration: Long = 600_000L, // 10 minutes
        teacher: String = "Test Teacher",
        name: String = "Test Meditation",
        customTeacher: String? = null,
        customName: String? = null,
        dateAdded: Long = System.currentTimeMillis(),
    ): GuidedMeditation =
        GuidedMeditation(
            id = id,
            fileUri = fileUri,
            fileName = fileName,
            duration = duration,
            teacher = teacher,
            name = name,
            customTeacher = customTeacher,
            customName = customName,
            dateAdded = dateAdded,
        )
}
