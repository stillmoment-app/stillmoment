package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.*
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
 * - reset functionality
 */
class EditSheetStateTest {

    // MARK: - Initialization Tests

    @Nested
    inner class Initialization {

        @Test
        fun `fromMeditation initializes with effective values`() {
            // Given
            val meditation = createTestMeditation(
                teacher = "Original Teacher",
                name = "Original Name"
            )

            // When
            val state = EditSheetState.fromMeditation(meditation)

            // Then
            assertEquals("Original Teacher", state.editedTeacher)
            assertEquals("Original Name", state.editedName)
            assertSame(meditation, state.originalMeditation)
        }

        @Test
        fun `fromMeditation uses custom values when set`() {
            // Given
            val meditation = createTestMeditation(
                teacher = "Original Teacher",
                name = "Original Name",
                customTeacher = "Custom Teacher",
                customName = "Custom Name"
            )

            // When
            val state = EditSheetState.fromMeditation(meditation)

            // Then
            assertEquals("Custom Teacher", state.editedTeacher)
            assertEquals("Custom Name", state.editedName)
        }
    }

    // MARK: - hasChanges Tests

    @Nested
    inner class HasChanges {

        @Test
        fun `hasChanges is false when values unchanged`() {
            // Given
            val meditation = createTestMeditation(
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
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "Changed")

            // When/Then
            assertTrue(state.hasChanges)
        }

        @Test
        fun `hasChanges is true when name changed`() {
            // Given
            val meditation = createTestMeditation(name = "Original")
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedName = "Changed")

            // When/Then
            assertTrue(state.hasChanges)
        }

        @Test
        fun `hasChanges is true when both changed`() {
            // Given
            val meditation = createTestMeditation(
                teacher = "Original Teacher",
                name = "Original Name"
            )
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "New Teacher", editedName = "New Name")

            // When/Then
            assertTrue(state.hasChanges)
        }

        @Test
        fun `hasChanges compares against original not custom values`() {
            // Given - meditation with custom values
            val meditation = createTestMeditation(
                teacher = "Original",
                customTeacher = "Custom"
            )
            // State initialized with custom value
            val state = EditSheetState.fromMeditation(meditation)

            // When - hasChanges should be true because "Custom" != "Original"
            // Then
            assertTrue(state.hasChanges)
        }
    }

    // MARK: - isValid Tests

    @Nested
    inner class IsValid {

        @Test
        fun `isValid is true when both fields have content`() {
            // Given
            val state = createTestState(
                editedTeacher = "Teacher",
                editedName = "Name"
            )

            // When/Then
            assertTrue(state.isValid)
        }

        @Test
        fun `isValid is false when teacher is empty`() {
            // Given
            val state = createTestState(
                editedTeacher = "",
                editedName = "Name"
            )

            // When/Then
            assertFalse(state.isValid)
        }

        @Test
        fun `isValid is false when name is empty`() {
            // Given
            val state = createTestState(
                editedTeacher = "Teacher",
                editedName = ""
            )

            // When/Then
            assertFalse(state.isValid)
        }

        @Test
        fun `isValid is false when both fields empty`() {
            // Given
            val state = createTestState(
                editedTeacher = "",
                editedName = ""
            )

            // When/Then
            assertFalse(state.isValid)
        }

        @Test
        fun `isValid is false when teacher is only whitespace`() {
            // Given
            val state = createTestState(
                editedTeacher = "   ",
                editedName = "Name"
            )

            // When/Then
            assertFalse(state.isValid)
        }

        @Test
        fun `isValid is false when name is only whitespace`() {
            // Given
            val state = createTestState(
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
        fun `applyChanges sets customTeacher when different from original`() {
            // Given
            val meditation = createTestMeditation(teacher = "Original")
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "Changed")

            // When
            val updated = state.applyChanges()

            // Then
            assertEquals("Changed", updated.customTeacher)
            assertEquals("Original", updated.teacher) // Original unchanged
        }

        @Test
        fun `applyChanges sets customName when different from original`() {
            // Given
            val meditation = createTestMeditation(name = "Original")
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedName = "Changed")

            // When
            val updated = state.applyChanges()

            // Then
            assertEquals("Changed", updated.customName)
            assertEquals("Original", updated.name) // Original unchanged
        }

        @Test
        fun `applyChanges does not set customTeacher when same as original`() {
            // Given
            val meditation = createTestMeditation(teacher = "Same")
            val state = EditSheetState.fromMeditation(meditation)

            // When
            val updated = state.applyChanges()

            // Then
            assertNull(updated.customTeacher)
        }

        @Test
        fun `applyChanges does not set customName when same as original`() {
            // Given
            val meditation = createTestMeditation(name = "Same")
            val state = EditSheetState.fromMeditation(meditation)

            // When
            val updated = state.applyChanges()

            // Then
            assertNull(updated.customName)
        }

        @Test
        fun `applyChanges clears customTeacher when reset to original`() {
            // Given - meditation had custom value
            val meditation = createTestMeditation(
                teacher = "Original",
                customTeacher = "Was Custom"
            )
            // User edited back to original
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "Original")

            // When
            val updated = state.applyChanges()

            // Then - custom should be cleared
            assertNull(updated.customTeacher)
            assertEquals("Original", updated.effectiveTeacher)
        }

        @Test
        fun `applyChanges clears customName when reset to original`() {
            // Given - meditation had custom value
            val meditation = createTestMeditation(
                name = "Original",
                customName = "Was Custom"
            )
            // User edited back to original
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedName = "Original")

            // When
            val updated = state.applyChanges()

            // Then - custom should be cleared
            assertNull(updated.customName)
            assertEquals("Original", updated.effectiveName)
        }

        @Test
        fun `applyChanges does not set customTeacher when blank`() {
            // Given
            val meditation = createTestMeditation(teacher = "Original")
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "   ")

            // When
            val updated = state.applyChanges()

            // Then - blank should not be saved
            assertNull(updated.customTeacher)
        }

        @Test
        fun `applyChanges does not set customName when blank`() {
            // Given
            val meditation = createTestMeditation(name = "Original")
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedName = "")

            // When
            val updated = state.applyChanges()

            // Then - empty should not be saved
            assertNull(updated.customName)
        }

        @Test
        fun `applyChanges preserves meditation identity`() {
            // Given
            val meditation = createTestMeditation()
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "New", editedName = "New")

            // When
            val updated = state.applyChanges()

            // Then
            assertEquals(meditation.id, updated.id)
            assertEquals(meditation.fileUri, updated.fileUri)
            assertEquals(meditation.duration, updated.duration)
        }
    }

    // MARK: - reset Tests

    @Nested
    inner class Reset {

        @Test
        fun `reset restores original teacher value`() {
            // Given
            val meditation = createTestMeditation(teacher = "Original")
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "Changed")

            // When
            val reset = state.reset()

            // Then
            assertEquals("Original", reset.editedTeacher)
        }

        @Test
        fun `reset restores original name value`() {
            // Given
            val meditation = createTestMeditation(name = "Original")
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedName = "Changed")

            // When
            val reset = state.reset()

            // Then
            assertEquals("Original", reset.editedName)
        }

        @Test
        fun `reset makes hasChanges false`() {
            // Given
            val meditation = createTestMeditation(
                teacher = "Original Teacher",
                name = "Original Name"
            )
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "Changed", editedName = "Changed")

            // When
            val reset = state.reset()

            // Then
            assertFalse(reset.hasChanges)
        }

        @Test
        fun `reset preserves original meditation reference`() {
            // Given
            val meditation = createTestMeditation()
            val state = EditSheetState.fromMeditation(meditation)
                .copy(editedTeacher = "Changed")

            // When
            val reset = state.reset()

            // Then
            assertSame(meditation, reset.originalMeditation)
        }
    }

    // MARK: - Test Helpers

    private fun createTestMeditation(
        teacher: String = "Test Teacher",
        name: String = "Test Meditation",
        customTeacher: String? = null,
        customName: String? = null
    ): GuidedMeditation = GuidedMeditation(
        fileUri = "content://test/uri",
        fileName = "test.mp3",
        duration = 600_000L,
        teacher = teacher,
        name = name,
        customTeacher = customTeacher,
        customName = customName
    )

    private fun createTestState(
        editedTeacher: String = "Teacher",
        editedName: String = "Name"
    ): EditSheetState = EditSheetState(
        originalMeditation = createTestMeditation(),
        editedTeacher = editedTeacher,
        editedName = editedName
    )
}
