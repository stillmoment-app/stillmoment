package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelStore
import com.stillmoment.data.FileOpenException
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.domain.models.AudioMetadata
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.domain.models.PendingImport
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.WaveformProviderProtocol
import com.stillmoment.presentation.navigation.SharedEntry
import com.stillmoment.presentation.navigation.SharedEntryGate
import com.stillmoment.testutil.FakeImportDownloads
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever

/**
 * shared-138: An entry shared while the library imports waits until the
 * library's import is done — edit sheet saved or discarded, message closed.
 * Every edit sheet counts, also the one of a meditation already in the library
 * and the one opened via the import button.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class LibraryImportEndsViewModelTest {
    private val testDispatcher = StandardTestDispatcher()
    private val fakeRepository = FakeGuidedMeditationRepository()
    private val fileOpenHandler = mock<FileOpenHandler>()
    private val gate = SharedEntryGate(logger = mock())
    private val waitingLink = SharedEntry.Link("https://www.audiodharma.org/talks/25402/download")
    private val talk25401 = PendingImport(
        uri = "file:///data/cache/link_import/1111/download",
        fileName = "download",
        metadata = AudioMetadata(duration = 2_400_000L, artist = "Gil Fronsdal", title = "Dharmette"),
        prefill = ImportPrefill(teacher = "Gil Fronsdal", name = "Dharmette")
    )
    private val libraryMeditation = GuidedMeditation(
        fileUri = "content://library/body-scan.mp3",
        fileName = "body-scan.mp3",
        duration = 600_000L,
        teacher = "Tara Brach",
        name = "Body Scan"
    )
    private lateinit var viewModel: GuidedMeditationsListViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = createViewModel()
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun createViewModel(): GuidedMeditationsListViewModel {
        val audioService = mock<AudioServiceProtocol>()
        whenever(audioService.meditationPreviewPositionFlow).thenReturn(MutableStateFlow(0L).asStateFlow())
        whenever(audioService.meditationPreviewDurationFlow).thenReturn(MutableStateFlow(0L).asStateFlow())
        whenever(audioService.meditationPreviewCompletionFlow)
            .thenReturn(MutableSharedFlow<Unit>(extraBufferCapacity = 1).asSharedFlow())
        val praxisRepository = mock<PraxisRepository>()
        whenever { praxisRepository.load() }.thenReturn(Praxis.Default)
        return GuidedMeditationsListViewModel(
            repository = fakeRepository,
            audioService = audioService,
            meditationSourceRepository = FakeMeditationSourceRepository(),
            searchHistoryRepository = FakeSearchHistoryRepository(),
            fileOpenHandler = fileOpenHandler,
            praxisRepository = praxisRepository,
            waveformProvider = mock<WaveformProviderProtocol>(),
            importDownloads = FakeImportDownloads(),
            sharedEntryGate = gate,
            logger = mock()
        )
    }

    /** The gate lets a shared entry through and the library takes it over. */
    private suspend fun libraryTakesOverSharedEntry(prepared: Result<PendingImport>) {
        val uri = mock<Uri>()
        whenever(fileOpenHandler.validateAndPrepareImport(uri)).thenReturn(prepared)
        gate.share(SharedEntry.File(uri = uri, fileName = "download", sizeBytes = 38_000_000L))
        gate.started()
        viewModel.importMeditation(uri)
    }

    /** A file picked via the import button — no sharing involved. */
    private suspend fun pickFileViaImportButton(prepared: Result<PendingImport>) {
        val uri = mock<Uri>()
        whenever(fileOpenHandler.validateAndPrepareImport(uri)).thenReturn(prepared)
        viewModel.importMeditation(uri)
    }

    private fun shareMeanwhile() = gate.share(waitingLink)

    private val waitingEntryStarted: Boolean
        get() = gate.toStart.value == waitingLink

    private fun openSheetDraft(): GuidedMeditation =
        checkNotNull(viewModel.uiState.value.selectedMeditation) { "No edit sheet open" }

    @Nested
    inner class ImportEditSheet {

        @Test
        fun `stays open with its entries when something new is shared`() = runTest(testDispatcher) {
            libraryTakesOverSharedEntry(Result.success(talk25401))
            advanceUntilIdle()
            val sheetBefore = viewModel.uiState.value

            shareMeanwhile()
            advanceUntilIdle()

            assertFalse(waitingEntryStarted)
            assertEquals(sheetBefore, viewModel.uiState.value)
        }

        @Test
        fun `lets the waiting entry start only once saving is done`() = runTest(testDispatcher) {
            libraryTakesOverSharedEntry(Result.success(talk25401))
            advanceUntilIdle()
            shareMeanwhile()

            viewModel.saveImportedMeditation(openSheetDraft().copy(teacher = "Gil Fronsdal"))
            assertFalse(waitingEntryStarted, "Still saving — the new sheet must not be closed by the old save")
            advanceUntilIdle()

            assertTrue(waitingEntryStarted)
            assertFalse(viewModel.uiState.value.showEditSheet)
            assertEquals(1, fakeRepository.addedMeditations.size)
        }

        @Test
        fun `lets the waiting entry start once it is discarded`() = runTest(testDispatcher) {
            libraryTakesOverSharedEntry(Result.success(talk25401))
            advanceUntilIdle()
            shareMeanwhile()

            viewModel.cancelImport()
            advanceUntilIdle()

            assertTrue(waitingEntryStarted)
        }
    }

    @Nested
    inner class Messages {

        @Test
        fun `the waiting entry starts only once "already there" is closed`() = runTest(testDispatcher) {
            libraryTakesOverSharedEntry(Result.failure(FileOpenException(FileOpenError.ALREADY_IMPORTED)))
            shareMeanwhile()
            advanceUntilIdle()
            assertEquals(LibraryError.AlreadyImported, viewModel.uiState.value.error)
            assertFalse(waitingEntryStarted, "The message is still shown")

            viewModel.clearError()

            assertTrue(waitingEntryStarted)
        }

        @Test
        fun `the waiting entry starts only once the message after a failed save is closed`() = runTest(testDispatcher) {
            fakeRepository.addFailure = IllegalStateException("copy failed")
            libraryTakesOverSharedEntry(Result.success(talk25401))
            advanceUntilIdle()
            shareMeanwhile()

            viewModel.saveImportedMeditation(openSheetDraft())
            advanceUntilIdle()
            assertEquals(LibraryError.ImportFailed, viewModel.uiState.value.error)
            assertFalse(waitingEntryStarted)

            viewModel.clearError()

            assertTrue(waitingEntryStarted)
        }

        @Test
        fun `a message closed while the next file is still being read does not end its import`() =
            runTest(testDispatcher) {
                libraryTakesOverSharedEntry(Result.failure(FileOpenException(FileOpenError.ALREADY_IMPORTED)))
                advanceUntilIdle()
                shareMeanwhile()

                pickFileViaImportButton(Result.success(talk25401))
                viewModel.clearError()
                advanceUntilIdle()

                assertTrue(viewModel.uiState.value.showEditSheet)
                assertFalse(waitingEntryStarted, "The picked file's edit sheet is open")
            }
    }

    @Nested
    inner class EditSheetOfALibraryMeditation {

        @Test
        fun `holds back a shared entry until it is closed`() = runTest(testDispatcher) {
            viewModel.showEditSheet(libraryMeditation)
            shareMeanwhile()
            assertFalse(waitingEntryStarted)

            viewModel.hideEditSheet()

            assertTrue(waitingEntryStarted)
        }

        @Test
        fun `holds back a shared entry until its changes are saved`() = runTest(testDispatcher) {
            viewModel.showEditSheet(libraryMeditation)
            shareMeanwhile()

            viewModel.updateMeditation(libraryMeditation.copy(teacher = "Tara"))
            assertFalse(waitingEntryStarted, "Still saving")
            advanceUntilIdle()

            assertTrue(waitingEntryStarted)
        }
    }

    @Nested
    inner class ImportButton {

        @Test
        fun `its edit sheet holds back a shared entry until it is discarded`() = runTest(testDispatcher) {
            pickFileViaImportButton(Result.success(talk25401))
            advanceUntilIdle()
            shareMeanwhile()
            assertFalse(waitingEntryStarted)

            viewModel.cancelImport()
            advanceUntilIdle()

            assertTrue(waitingEntryStarted)
        }

        @Test
        fun `after its import the next share starts right away`() = runTest(testDispatcher) {
            pickFileViaImportButton(Result.success(talk25401))
            advanceUntilIdle()
            viewModel.saveImportedMeditation(openSheetDraft())
            advanceUntilIdle()

            shareMeanwhile()

            assertTrue(waitingEntryStarted)
        }
    }

    @Nested
    inner class LibraryGone {

        @Test
        fun `a library closed for good with its edit sheet open does not block later shares`() =
            runTest(testDispatcher) {
                val store = ViewModelStore()
                val library = ViewModelProvider(store, LibraryFactory())[GuidedMeditationsListViewModel::class.java]
                library.showEditSheet(libraryMeditation)
                shareMeanwhile()
                assertFalse(waitingEntryStarted)

                store.clear()

                assertTrue(waitingEntryStarted)
            }
    }

    private inner class LibraryFactory : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T = createViewModel() as T
    }
}
