package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for GuidedMeditationsListUiState.
 * Tests the pure data class logic without ViewModel dependencies.
 */
class GuidedMeditationsListViewModelTest {

    // MARK: - Initial State Tests

    @Nested
    inner class InitialState {

        @Test
        fun `initial state has correct default values`() {
            val state = GuidedMeditationsListUiState()

            assertTrue(state.groups.isEmpty())
            assertTrue(state.isLoading)
            assertNull(state.error)
            assertNull(state.selectedMeditation)
            assertFalse(state.showEditSheet)
            assertFalse(state.showDeleteConfirmation)
            assertNull(state.meditationToDelete)
        }

        @Test
        fun `initial state reports empty when not loading`() {
            val state = GuidedMeditationsListUiState(isLoading = false)

            assertTrue(state.isEmpty)
        }

        @Test
        fun `initial state does not report empty when loading`() {
            val state = GuidedMeditationsListUiState(isLoading = true)

            assertFalse(state.isEmpty)
        }
    }

    // MARK: - totalCount Tests

    @Nested
    inner class TotalCountTests {

        @Test
        fun `totalCount returns zero for empty groups`() {
            val state = GuidedMeditationsListUiState(groups = emptyList())

            assertEquals(0, state.totalCount)
        }

        @Test
        fun `totalCount sums meditations across all groups`() {
            val groups = listOf(
                createTestGroup("Teacher A", 3),
                createTestGroup("Teacher B", 2),
                createTestGroup("Teacher C", 5)
            )
            val state = GuidedMeditationsListUiState(groups = groups)

            assertEquals(10, state.totalCount)
        }

        @Test
        fun `totalCount handles single group`() {
            val groups = listOf(createTestGroup("Teacher", 7))
            val state = GuidedMeditationsListUiState(groups = groups)

            assertEquals(7, state.totalCount)
        }
    }

    // MARK: - isEmpty Tests

    @Nested
    inner class IsEmptyTests {

        @Test
        fun `isEmpty returns true when groups empty and not loading`() {
            val state = GuidedMeditationsListUiState(
                groups = emptyList(),
                isLoading = false
            )

            assertTrue(state.isEmpty)
        }

        @Test
        fun `isEmpty returns false when groups exist`() {
            val state = GuidedMeditationsListUiState(
                groups = listOf(createTestGroup("Teacher", 1)),
                isLoading = false
            )

            assertFalse(state.isEmpty)
        }

        @Test
        fun `isEmpty returns false when still loading`() {
            val state = GuidedMeditationsListUiState(
                groups = emptyList(),
                isLoading = true
            )

            assertFalse(state.isEmpty)
        }
    }

    // MARK: - State Copy Tests

    @Nested
    inner class StateCopyTests {

        @Test
        fun `copy preserves unchanged values`() {
            val meditation = createTestMeditation()
            val original = GuidedMeditationsListUiState(
                groups = listOf(createTestGroup("Teacher", 2)),
                isLoading = false,
                error = "Test error",
                selectedMeditation = meditation,
                showEditSheet = true
            )

            val updated = original.copy(showDeleteConfirmation = true)

            assertEquals(original.groups, updated.groups)
            assertEquals(original.isLoading, updated.isLoading)
            assertEquals(original.error, updated.error)
            assertEquals(original.selectedMeditation, updated.selectedMeditation)
            assertEquals(original.showEditSheet, updated.showEditSheet)
            assertTrue(updated.showDeleteConfirmation)
        }

        @Test
        fun `copy with new groups updates totalCount`() {
            val original = GuidedMeditationsListUiState(
                groups = listOf(createTestGroup("A", 3))
            )
            assertEquals(3, original.totalCount)

            val updated = original.copy(
                groups = listOf(
                    createTestGroup("A", 3),
                    createTestGroup("B", 5)
                )
            )
            assertEquals(8, updated.totalCount)
        }
    }

    // MARK: - Edit Sheet State Tests

    @Nested
    inner class EditSheetStateTests {

        @Test
        fun `edit sheet state tracks selected meditation`() {
            val meditation = createTestMeditation(name = "Selected Meditation")
            val state = GuidedMeditationsListUiState(
                selectedMeditation = meditation,
                showEditSheet = true
            )

            assertNotNull(state.selectedMeditation)
            assertEquals("Selected Meditation", state.selectedMeditation?.name)
            assertTrue(state.showEditSheet)
        }

        @Test
        fun `hiding edit sheet clears selection`() {
            val meditation = createTestMeditation()
            val showing = GuidedMeditationsListUiState(
                selectedMeditation = meditation,
                showEditSheet = true
            )

            val hidden = showing.copy(
                selectedMeditation = null,
                showEditSheet = false
            )

            assertNull(hidden.selectedMeditation)
            assertFalse(hidden.showEditSheet)
        }
    }

    // MARK: - Delete Confirmation State Tests

    @Nested
    inner class DeleteConfirmationStateTests {

        @Test
        fun `delete confirmation tracks meditation to delete`() {
            val meditation = createTestMeditation(name = "To Delete")
            val state = GuidedMeditationsListUiState(
                meditationToDelete = meditation,
                showDeleteConfirmation = true
            )

            assertNotNull(state.meditationToDelete)
            assertEquals("To Delete", state.meditationToDelete?.name)
            assertTrue(state.showDeleteConfirmation)
        }

        @Test
        fun `canceling delete clears state`() {
            val meditation = createTestMeditation()
            val confirming = GuidedMeditationsListUiState(
                meditationToDelete = meditation,
                showDeleteConfirmation = true
            )

            val canceled = confirming.copy(
                meditationToDelete = null,
                showDeleteConfirmation = false
            )

            assertNull(canceled.meditationToDelete)
            assertFalse(canceled.showDeleteConfirmation)
        }
    }

    // MARK: - Error State Tests

    @Nested
    inner class ErrorStateTests {

        @Test
        fun `error state can be set and cleared`() {
            val withError = GuidedMeditationsListUiState(error = "Import failed")
            assertEquals("Import failed", withError.error)

            val cleared = withError.copy(error = null)
            assertNull(cleared.error)
        }
    }

    // MARK: - Test Helpers

    private fun createTestMeditation(
        id: String = java.util.UUID.randomUUID().toString(),
        name: String = "Test Meditation",
        teacher: String = "Test Teacher",
        duration: Long = 600_000L
    ): GuidedMeditation = GuidedMeditation(
        id = id,
        fileUri = "content://test/uri",
        fileName = "test.mp3",
        duration = duration,
        teacher = teacher,
        name = name
    )

    private fun createTestGroup(
        teacher: String,
        meditationCount: Int
    ): GuidedMeditationGroup {
        val meditations = (1..meditationCount).map { index ->
            createTestMeditation(
                name = "Meditation $index",
                teacher = teacher
            )
        }
        return GuidedMeditationGroup(teacher = teacher, meditations = meditations)
    }
}
