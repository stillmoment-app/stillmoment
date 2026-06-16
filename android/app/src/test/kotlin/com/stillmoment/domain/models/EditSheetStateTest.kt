package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertSame
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for EditSheetState domain model.
 *
 * Tests cover:
 * - State initialization from meditation
 * - hasChanges detection
 * - isValid validation
 * - applyChanges logic
 */
class EditSheetStateTest {
    // MARK: - Initialization Tests

    @Nested
    inner class Initialization {
        @Test
        fun `fromMeditation initializes with meditation values`() {
            // Given
            val meditation =
                createTestMeditation(
                    teacher = "Tara Brach",
                    name = "Body Scan"
                )

            // When
            val state = EditSheetState.fromMeditation(meditation)

            // Then
            assertEquals("Tara Brach", state.editedTeacher)
            assertEquals("Body Scan", state.editedName)
            assertSame(meditation, state.originalMeditation)
        }
    }

    // MARK: - hasChanges Tests

    @Nested
    inner class HasChanges {
        @Test
        fun `hasChanges is false when values unchanged`() {
            // Given
            val meditation =
                createTestMeditation(
                    teacher = "Teacher",
                    name = "Name"
                )
            val state = EditSheetState.fromMeditation(meditation)

            // When/Then
            assertFalse(state.hasChanges)
        }

        @Test
        fun `hasChanges is true when teacher changed`() {
            // Given
            val meditation = createTestMeditation(teacher = "Original")
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedTeacher = "Changed")

            // When/Then
            assertTrue(state.hasChanges)
        }

        @Test
        fun `hasChanges is true when name changed`() {
            // Given
            val meditation = createTestMeditation(name = "Original")
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedName = "Changed")

            // When/Then
            assertTrue(state.hasChanges)
        }

        @Test
        fun `hasChanges is true when both changed`() {
            // Given
            val meditation =
                createTestMeditation(
                    teacher = "Original Teacher",
                    name = "Original Name"
                )
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedTeacher = "New Teacher", editedName = "New Name")

            // When/Then
            assertTrue(state.hasChanges)
        }
    }

    // MARK: - Gong Field Tests (shared-106)

    @Nested
    inner class GongFields {
        @Test
        fun `fromMeditation initializes with meditation gong values`() {
            // Given
            val meditation =
                createTestMeditation().copy(
                    startGongEnabled = true,
                    endGongEnabled = true,
                    gongSoundId = "deep-resonance"
                )

            // When
            val state = EditSheetState.fromMeditation(meditation)

            // Then
            assertTrue(state.editedStartGongEnabled)
            assertTrue(state.editedEndGongEnabled)
            assertEquals("deep-resonance", state.editedGongSoundId)
        }

        @Test
        fun `hasChanges is true when start gong toggled`() {
            // Given
            val meditation = createTestMeditation().copy(startGongEnabled = false)
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedStartGongEnabled = true)

            // When/Then
            assertTrue(state.hasChanges)
        }

        @Test
        fun `hasChanges is true when end gong toggled`() {
            // Given
            val meditation = createTestMeditation().copy(endGongEnabled = false)
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedEndGongEnabled = true)

            // When/Then
            assertTrue(state.hasChanges)
        }

        @Test
        fun `hasChanges is true when gong sound changed`() {
            // Given
            val meditation = createTestMeditation().copy(gongSoundId = "temple-bell")
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedGongSoundId = "clear-strike")

            // When/Then
            assertTrue(state.hasChanges)
        }

        @Test
        fun `hasChanges is false when gong fields unchanged`() {
            // Given
            val meditation =
                createTestMeditation().copy(
                    startGongEnabled = true,
                    endGongEnabled = false,
                    gongSoundId = "classic-bowl"
                )
            val state = EditSheetState.fromMeditation(meditation)

            // When/Then
            assertFalse(state.hasChanges)
        }

        @Test
        fun `applyChanges writes gong fields`() {
            // Given
            val meditation = createTestMeditation()
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(
                        editedStartGongEnabled = true,
                        editedEndGongEnabled = true,
                        editedGongSoundId = "deep-resonance"
                    )

            // When
            val updated = state.applyChanges()

            // Then
            assertTrue(updated.startGongEnabled)
            assertTrue(updated.endGongEnabled)
            assertEquals("deep-resonance", updated.gongSoundId)
        }
    }

    // MARK: - isValid Tests

    @Nested
    inner class IsValid {
        @Test
        fun `isValid is true when both fields have content`() {
            // Given
            val state =
                createTestState(
                    editedTeacher = "Teacher",
                    editedName = "Name"
                )

            // When/Then
            assertTrue(state.isValid)
        }

        @Test
        fun `isValid is false when teacher is empty`() {
            // Given
            val state =
                createTestState(
                    editedTeacher = "",
                    editedName = "Name"
                )

            // When/Then
            assertFalse(state.isValid)
        }

        @Test
        fun `isValid is false when name is empty`() {
            // Given
            val state =
                createTestState(
                    editedTeacher = "Teacher",
                    editedName = ""
                )

            // When/Then
            assertFalse(state.isValid)
        }

        @Test
        fun `isValid is false when both fields empty`() {
            // Given
            val state =
                createTestState(
                    editedTeacher = "",
                    editedName = ""
                )

            // When/Then
            assertFalse(state.isValid)
        }

        @Test
        fun `isValid is false when teacher is only whitespace`() {
            // Given
            val state =
                createTestState(
                    editedTeacher = "   ",
                    editedName = "Name"
                )

            // When/Then
            assertFalse(state.isValid)
        }

        @Test
        fun `isValid is false when name is only whitespace`() {
            // Given
            val state =
                createTestState(
                    editedTeacher = "Teacher",
                    editedName = "\t\n"
                )

            // When/Then
            assertFalse(state.isValid)
        }
    }

    // MARK: - applyChanges Tests

    @Nested
    inner class ApplyChanges {
        @Test
        fun `applyChanges writes teacher directly`() {
            // Given
            val meditation = createTestMeditation(teacher = "Original")
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedTeacher = "Changed")

            // When
            val updated = state.applyChanges()

            // Then
            assertEquals("Changed", updated.teacher)
        }

        @Test
        fun `applyChanges writes name directly`() {
            // Given
            val meditation = createTestMeditation(name = "Original")
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedName = "Changed")

            // When
            val updated = state.applyChanges()

            // Then
            assertEquals("Changed", updated.name)
        }

        @Test
        fun `applyChanges trims teacher and name`() {
            // Given
            val meditation = createTestMeditation(teacher = "T", name = "N")
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedTeacher = "  Tara  ", editedName = "  Body Scan  ")

            // When
            val updated = state.applyChanges()

            // Then
            assertEquals("Tara", updated.teacher)
            assertEquals("Body Scan", updated.name)
        }

        @Test
        fun `applyChanges preserves meditation identity`() {
            // Given
            val meditation = createTestMeditation()
            val state =
                EditSheetState.fromMeditation(meditation)
                    .copy(editedTeacher = "New", editedName = "New")

            // When
            val updated = state.applyChanges()

            // Then
            assertEquals(meditation.id, updated.id)
            assertEquals(meditation.fileUri, updated.fileUri)
            assertEquals(meditation.duration, updated.duration)
        }
    }

    // MARK: - Test Helpers

    private fun createTestMeditation(
        teacher: String = "Test Teacher",
        name: String = "Test Meditation"
    ): GuidedMeditation = GuidedMeditation(
        fileUri = "content://test/uri",
        fileName = "test.mp3",
        duration = 600_000L,
        teacher = teacher,
        name = name
    )

    private fun createTestState(editedTeacher: String = "Teacher", editedName: String = "Name"): EditSheetState =
        EditSheetState(
            originalMeditation = createTestMeditation(),
            editedTeacher = editedTeacher,
            editedName = editedName
        )
}
