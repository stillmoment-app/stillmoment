package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for GuidedMeditationsListViewModel.
 *
 * Tests both the UiState data class and the actual ViewModel logic
 * including import, delete, update, and edit sheet flows.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class GuidedMeditationsListViewModelTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeRepository: FakeGuidedMeditationRepository
    private lateinit var viewModel: GuidedMeditationsListViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeGuidedMeditationRepository()
        viewModel = GuidedMeditationsListViewModel(fakeRepository)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ============================================================
    // MARK: - UiState Data Class Tests (existing tests)
    // ============================================================

    @Nested
    inner class UiStateInitialState {
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

    @Nested
    inner class UiStateTotalCountTests {
        @Test
        fun `totalCount returns zero for empty groups`() {
            val state = GuidedMeditationsListUiState(groups = emptyList())

            assertEquals(0, state.totalCount)
        }

        @Test
        fun `totalCount sums meditations across all groups`() {
            val groups =
                listOf(
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

    @Nested
    inner class UiStateIsEmptyTests {
        @Test
        fun `isEmpty returns true when groups empty and not loading`() {
            val state =
                GuidedMeditationsListUiState(
                    groups = emptyList(),
                    isLoading = false
                )

            assertTrue(state.isEmpty)
        }

        @Test
        fun `isEmpty returns false when groups exist`() {
            val state =
                GuidedMeditationsListUiState(
                    groups = listOf(createTestGroup("Teacher", 1)),
                    isLoading = false
                )

            assertFalse(state.isEmpty)
        }

        @Test
        fun `isEmpty returns false when still loading`() {
            val state =
                GuidedMeditationsListUiState(
                    groups = emptyList(),
                    isLoading = true
                )

            assertFalse(state.isEmpty)
        }
    }

    @Nested
    inner class UiStateAvailableTeachersTests {
        @Test
        fun `availableTeachers returns empty list for empty groups`() {
            val state = GuidedMeditationsListUiState(groups = emptyList())

            assertTrue(state.availableTeachers.isEmpty())
        }

        @Test
        fun `availableTeachers returns unique teacher names`() {
            val groups =
                listOf(
                    createTestGroup("Tara Brach", 2),
                    createTestGroup("Jack Kornfield", 1),
                    createTestGroup("Sharon Salzberg", 3)
                )
            val state = GuidedMeditationsListUiState(groups = groups)

            assertEquals(3, state.availableTeachers.size)
            assertTrue(state.availableTeachers.contains("Tara Brach"))
            assertTrue(state.availableTeachers.contains("Jack Kornfield"))
            assertTrue(state.availableTeachers.contains("Sharon Salzberg"))
        }

        @Test
        fun `availableTeachers is sorted alphabetically`() {
            val groups =
                listOf(
                    createTestGroup("Zebra Teacher", 1),
                    createTestGroup("Alpha Teacher", 1),
                    createTestGroup("Middle Teacher", 1)
                )
            val state = GuidedMeditationsListUiState(groups = groups)

            assertEquals("Alpha Teacher", state.availableTeachers[0])
            assertEquals("Middle Teacher", state.availableTeachers[1])
            assertEquals("Zebra Teacher", state.availableTeachers[2])
        }
    }

    // ============================================================
    // MARK: - ViewModel Initialization Tests
    // ============================================================

    @Nested
    inner class ViewModelInitialization {
        @Test
        fun `viewModel observes repository on init`() = runTest {
            // Given - repository has meditations
            val meditation = createTestMeditation()
            fakeRepository.emitMeditations(listOf(meditation))

            // When - advance coroutines
            advanceUntilIdle()

            // Then - viewModel state reflects repository
            val state = viewModel.uiState.value
            assertFalse(state.isLoading)
            assertEquals(1, state.totalCount)
        }

        @Test
        fun `viewModel starts with loading state`() {
            // Given - new viewModel (no advanceUntilIdle)

            // Then - initial state is loading
            val state = viewModel.uiState.value
            assertTrue(state.isLoading)
        }

        @Test
        fun `viewModel groups meditations by teacher`() = runTest {
            // Given
            val med1 = createTestMeditation(teacher = "Alice", name = "Med1")
            val med2 = createTestMeditation(teacher = "Alice", name = "Med2")
            val med3 = createTestMeditation(teacher = "Bob", name = "Med3")
            fakeRepository.emitMeditations(listOf(med1, med2, med3))

            // When
            advanceUntilIdle()

            // Then
            val state = viewModel.uiState.value
            assertEquals(2, state.groups.size)
            assertEquals(3, state.totalCount)
        }
    }

    // ============================================================
    // MARK: - Import Meditation Tests
    // ============================================================

    @Nested
    inner class ImportMeditationTests {
        @Test
        fun `importMeditation success updates state`() = runTest {
            // Given
            val uri = mock<Uri>()
            fakeRepository.importShouldFail = false

            // When
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // Then
            val state = viewModel.uiState.value
            assertFalse(state.isLoading)
            assertNull(state.error)
            assertTrue(fakeRepository.importWasCalled)
        }

        @Test
        fun `importMeditation sets and clears loading state`() = runTest {
            // Given
            val uri = mock<Uri>()
            fakeRepository.emitMeditations(emptyList())
            advanceUntilIdle()
            assertFalse(viewModel.uiState.value.isLoading) // starts not loading

            // When - import completes
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // Then - loading is cleared after completion
            assertFalse(viewModel.uiState.value.isLoading)
            assertTrue(fakeRepository.importWasCalled)
        }

        @Test
        fun `importMeditation failure sets error`() = runTest {
            // Given
            val uri = mock<Uri>()
            fakeRepository.importShouldFail = true
            fakeRepository.importErrorMessage = "File not found"

            // When
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // Then
            val state = viewModel.uiState.value
            assertFalse(state.isLoading)
            assertNotNull(state.error)
            assertEquals("File not found", state.error)
        }

        @Test
        fun `importMeditation clears previous error`() = runTest {
            // Given - existing error
            val uri = mock<Uri>()
            fakeRepository.importShouldFail = true
            viewModel.importMeditation(uri)
            advanceUntilIdle()
            assertNotNull(viewModel.uiState.value.error)

            // When - new successful import
            fakeRepository.importShouldFail = false
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // Then - error is cleared
            assertNull(viewModel.uiState.value.error)
        }
    }

    // ============================================================
    // MARK: - Delete Meditation Tests
    // ============================================================

    @Nested
    inner class DeleteMeditationTests {
        @Test
        fun `deleteMeditation calls repository`() = runTest {
            // Given
            val meditation = createTestMeditation()
            fakeRepository.emitMeditations(listOf(meditation))
            advanceUntilIdle()

            // When
            viewModel.deleteMeditation(meditation)
            advanceUntilIdle()

            // Then
            assertTrue(fakeRepository.deleteWasCalled)
            assertEquals(meditation.id, fakeRepository.lastDeletedId)
        }

        @Test
        fun `confirmDelete sets meditationToDelete`() = runTest {
            // Given
            val meditation = createTestMeditation()

            // When
            viewModel.confirmDelete(meditation)

            // Then
            val state = viewModel.uiState.value
            assertEquals(meditation, state.meditationToDelete)
            assertTrue(state.showDeleteConfirmation)
        }

        @Test
        fun `cancelDelete clears delete state`() = runTest {
            // Given - pending delete
            val meditation = createTestMeditation()
            viewModel.confirmDelete(meditation)
            assertTrue(viewModel.uiState.value.showDeleteConfirmation)

            // When
            viewModel.cancelDelete()

            // Then
            val state = viewModel.uiState.value
            assertNull(state.meditationToDelete)
            assertFalse(state.showDeleteConfirmation)
        }

        @Test
        fun `executeDelete deletes pending meditation`() = runTest {
            // Given
            val meditation = createTestMeditation()
            fakeRepository.emitMeditations(listOf(meditation))
            advanceUntilIdle()
            viewModel.confirmDelete(meditation)

            // When
            viewModel.executeDelete()
            advanceUntilIdle()

            // Then
            assertTrue(fakeRepository.deleteWasCalled)
            assertEquals(meditation.id, fakeRepository.lastDeletedId)
            assertFalse(viewModel.uiState.value.showDeleteConfirmation)
        }

        @Test
        fun `executeDelete does nothing without pending meditation`() = runTest {
            // Given - no pending deletion

            // When
            viewModel.executeDelete()
            advanceUntilIdle()

            // Then
            assertFalse(fakeRepository.deleteWasCalled)
        }
    }

    // ============================================================
    // MARK: - Update Meditation Tests
    // ============================================================

    @Nested
    inner class UpdateMeditationTests {
        @Test
        fun `updateMeditation calls repository`() = runTest {
            // Given
            val meditation = createTestMeditation()

            // When
            viewModel.updateMeditation(meditation)
            advanceUntilIdle()

            // Then
            assertTrue(fakeRepository.updateWasCalled)
            assertEquals(meditation, fakeRepository.lastUpdatedMeditation)
        }

        @Test
        fun `updateMeditation hides edit sheet`() = runTest {
            // Given - edit sheet is shown
            val meditation = createTestMeditation()
            viewModel.showEditSheet(meditation)
            assertTrue(viewModel.uiState.value.showEditSheet)

            // When
            viewModel.updateMeditation(meditation)
            advanceUntilIdle()

            // Then
            assertFalse(viewModel.uiState.value.showEditSheet)
        }

        @Test
        fun `updateCustomTeacher updates selected meditation`() = runTest {
            // Given - meditation selected for editing
            val meditation = createTestMeditation(teacher = "Original")
            viewModel.showEditSheet(meditation)

            // When
            viewModel.updateCustomTeacher("Custom Teacher")

            // Then
            val selected = viewModel.uiState.value.selectedMeditation
            assertNotNull(selected)
            assertEquals("Custom Teacher", selected?.customTeacher)
            assertEquals("Custom Teacher", selected?.effectiveTeacher)
        }

        @Test
        fun `updateCustomTeacher clears custom when blank`() = runTest {
            // Given
            val meditation = createTestMeditation(teacher = "Original")
            viewModel.showEditSheet(meditation)
            viewModel.updateCustomTeacher("Custom")
            assertNotNull(viewModel.uiState.value.selectedMeditation?.customTeacher)

            // When - blank string
            viewModel.updateCustomTeacher("   ")

            // Then - should be null
            assertNull(viewModel.uiState.value.selectedMeditation?.customTeacher)
        }

        @Test
        fun `updateCustomName updates selected meditation`() = runTest {
            // Given
            val meditation = createTestMeditation(name = "Original")
            viewModel.showEditSheet(meditation)

            // When
            viewModel.updateCustomName("Custom Name")

            // Then
            val selected = viewModel.uiState.value.selectedMeditation
            assertNotNull(selected)
            assertEquals("Custom Name", selected?.customName)
            assertEquals("Custom Name", selected?.effectiveName)
        }

        @Test
        fun `updateCustomName does nothing without selection`() = runTest {
            // Given - no meditation selected

            // When
            viewModel.updateCustomName("Custom Name")

            // Then - no crash, state unchanged
            assertNull(viewModel.uiState.value.selectedMeditation)
        }
    }

    // ============================================================
    // MARK: - Edit Sheet Tests
    // ============================================================

    @Nested
    inner class EditSheetTests {
        @Test
        fun `showEditSheet sets selectedMeditation and flag`() {
            // Given
            val meditation = createTestMeditation()

            // When
            viewModel.showEditSheet(meditation)

            // Then
            val state = viewModel.uiState.value
            assertEquals(meditation, state.selectedMeditation)
            assertTrue(state.showEditSheet)
        }

        @Test
        fun `hideEditSheet clears selection and flag`() {
            // Given - sheet is shown
            val meditation = createTestMeditation()
            viewModel.showEditSheet(meditation)
            assertTrue(viewModel.uiState.value.showEditSheet)

            // When
            viewModel.hideEditSheet()

            // Then
            val state = viewModel.uiState.value
            assertNull(state.selectedMeditation)
            assertFalse(state.showEditSheet)
        }
    }

    // ============================================================
    // MARK: - Error Handling Tests
    // ============================================================

    @Nested
    inner class ErrorHandlingTests {
        @Test
        fun `clearError sets error to null`() = runTest {
            // Given - error exists
            val uri = mock<Uri>()
            fakeRepository.importShouldFail = true
            viewModel.importMeditation(uri)
            advanceUntilIdle()
            assertNotNull(viewModel.uiState.value.error)

            // When
            viewModel.clearError()

            // Then
            assertNull(viewModel.uiState.value.error)
        }

        @Test
        fun `error is cleared on successful operation`() = runTest {
            // Given - existing error
            val uri = mock<Uri>()
            fakeRepository.importShouldFail = true
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // When - successful import
            fakeRepository.importShouldFail = false
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // Then
            assertNull(viewModel.uiState.value.error)
        }
    }

    // ============================================================
    // MARK: - Loading State Tests
    // ============================================================

    @Nested
    inner class LoadingStateTests {
        @Test
        fun `loading state is managed during import`() = runTest {
            // Given - repository emits, viewModel is ready
            fakeRepository.emitMeditations(emptyList())
            advanceUntilIdle()
            assertFalse(viewModel.uiState.value.isLoading)

            // When - import
            val uri = mock<Uri>()
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // Then - loading is cleared
            assertFalse(viewModel.uiState.value.isLoading)
        }

        @Test
        fun `loading state cleared after import success`() = runTest {
            // Given
            val uri = mock<Uri>()

            // When
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // Then
            assertFalse(viewModel.uiState.value.isLoading)
        }

        @Test
        fun `loading state cleared after import failure`() = runTest {
            // Given
            val uri = mock<Uri>()
            fakeRepository.importShouldFail = true

            // When
            viewModel.importMeditation(uri)
            advanceUntilIdle()

            // Then
            assertFalse(viewModel.uiState.value.isLoading)
        }
    }

    // ============================================================
    // MARK: - Test Helpers
    // ============================================================

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

    private fun createTestGroup(teacher: String, meditationCount: Int): GuidedMeditationGroup {
        val meditations =
            (1..meditationCount).map { index ->
                createTestMeditation(
                    name = "Meditation $index",
                    teacher = teacher
                )
            }
        return GuidedMeditationGroup(teacher = teacher, meditations = meditations)
    }
}

// ============================================================
// MARK: - Fake Repository
// ============================================================

/**
 * Fake implementation of GuidedMeditationRepository for testing.
 *
 * Allows controlling behavior via flags and tracking method calls.
 */
class FakeGuidedMeditationRepository : GuidedMeditationRepository {
    // State
    private val _meditations = MutableStateFlow<List<GuidedMeditation>>(emptyList())

    // Behavior flags
    var importShouldFail = false
    var importErrorMessage = "Import failed"

    // Call tracking
    var importWasCalled = false
        private set
    var deleteWasCalled = false
        private set
    var updateWasCalled = false
        private set
    var lastDeletedId: String? = null
        private set
    var lastUpdatedMeditation: GuidedMeditation? = null
        private set

    override val meditationsFlow: Flow<List<GuidedMeditation>>
        get() = _meditations

    override suspend fun importMeditation(uri: Uri): Result<GuidedMeditation> {
        importWasCalled = true
        return if (importShouldFail) {
            Result.failure(Exception(importErrorMessage))
        } else {
            val meditation =
                GuidedMeditation(
                    id = java.util.UUID.randomUUID().toString(),
                    fileUri = uri.toString(),
                    fileName = "imported.mp3",
                    duration = 600_000L,
                    teacher = "Imported Teacher",
                    name = "Imported Meditation"
                )
            _meditations.value = _meditations.value + meditation
            Result.success(meditation)
        }
    }

    override suspend fun deleteMeditation(id: String) {
        deleteWasCalled = true
        lastDeletedId = id
        _meditations.value = _meditations.value.filter { it.id != id }
    }

    override suspend fun updateMeditation(meditation: GuidedMeditation) {
        updateWasCalled = true
        lastUpdatedMeditation = meditation
        _meditations.value =
            _meditations.value.map {
                if (it.id == meditation.id) meditation else it
            }
    }

    override suspend fun getMeditation(id: String): GuidedMeditation? {
        return _meditations.value.find { it.id == id }
    }

    // Test helpers
    fun emitMeditations(meditations: List<GuidedMeditation>) {
        _meditations.value = meditations
    }

    fun reset() {
        _meditations.value = emptyList()
        importShouldFail = false
        importWasCalled = false
        deleteWasCalled = false
        updateWasCalled = false
        lastDeletedId = null
        lastUpdatedMeditation = null
    }
}
