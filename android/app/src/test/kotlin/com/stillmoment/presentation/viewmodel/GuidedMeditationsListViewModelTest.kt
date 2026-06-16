package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.data.FileOpenException
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.domain.models.AudioMetadata
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.models.PendingImport
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.repositories.MeditationSourceRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.repositories.SearchHistoryRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformProviderProtocol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
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
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.mockito.kotlin.wheneverBlocking

/**
 * Unit tests for GuidedMeditationsListViewModel.
 *
 * Covers the shared-103 import flow (pending state, save, cancel) plus the
 * existing edit, delete, search, preview, and content-guide flows.
 */
@OptIn(ExperimentalCoroutinesApi::class)
@Suppress("LargeClass")
class GuidedMeditationsListViewModelTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeRepository: FakeGuidedMeditationRepository
    private lateinit var mockAudioService: AudioServiceProtocol
    private lateinit var previewPositionFlow: MutableStateFlow<Long>
    private lateinit var previewDurationFlow: MutableStateFlow<Long>
    private lateinit var previewCompletionFlow: MutableSharedFlow<Unit>
    private lateinit var fakeSourceRepository: FakeMeditationSourceRepository
    private lateinit var fakeSearchHistoryRepository: FakeSearchHistoryRepository
    private lateinit var mockFileOpenHandler: FileOpenHandler
    private lateinit var mockPraxisRepository: PraxisRepository
    private lateinit var mockWaveformProvider: WaveformProviderProtocol
    private lateinit var mockLogger: LoggerProtocol
    private lateinit var viewModel: GuidedMeditationsListViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeGuidedMeditationRepository()
        mockAudioService = mock()
        previewPositionFlow = MutableStateFlow(0L)
        previewDurationFlow = MutableStateFlow(0L)
        previewCompletionFlow = MutableSharedFlow(extraBufferCapacity = 1)
        whenever(mockAudioService.meditationPreviewPositionFlow).thenReturn(
            previewPositionFlow.asStateFlow()
        )
        whenever(mockAudioService.meditationPreviewDurationFlow).thenReturn(
            previewDurationFlow.asStateFlow()
        )
        whenever(mockAudioService.meditationPreviewCompletionFlow).thenReturn(
            previewCompletionFlow.asSharedFlow()
        )
        fakeSourceRepository = FakeMeditationSourceRepository()
        fakeSearchHistoryRepository = FakeSearchHistoryRepository()
        // The FileOpenHandler depends on Context/ContentResolver — for the
        // unit tests we work via the Fake repository directly and stub the
        // handler with a mock that callers can wire as needed.
        mockFileOpenHandler = mock()
        mockPraxisRepository = mock()
        wheneverBlocking { mockPraxisRepository.load() }.thenReturn(Praxis.Default)
        mockWaveformProvider = mock()
        mockLogger = mock()
        viewModel = GuidedMeditationsListViewModel(
            repository = fakeRepository,
            audioService = mockAudioService,
            meditationSourceRepository = fakeSourceRepository,
            searchHistoryRepository = fakeSearchHistoryRepository,
            fileOpenHandler = mockFileOpenHandler,
            praxisRepository = mockPraxisRepository,
            waveformProvider = mockWaveformProvider,
            logger = mockLogger
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // MARK: - UiState

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
            assertNull(state.pendingImport)
        }

        @Test
        fun `initial state reports empty when not loading`() {
            val state = GuidedMeditationsListUiState(isLoading = false)
            assertTrue(state.isEmpty)
        }
    }

    @Nested
    inner class UiStateGroupsRendering {
        @Test
        fun `groups produced from meditationsFlow`() = runTest {
            fakeRepository.emitMeditations(
                listOf(
                    meditation(teacher = "Tara Brach", name = "Body Scan"),
                    meditation(teacher = "Tara Brach", name = "Loving Kindness"),
                    meditation(teacher = "Jack Kornfield", name = "Mindfulness")
                )
            )
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertEquals(2, state.groups.size)
            assertEquals(3, state.totalCount)
        }
    }

    // MARK: - Save / Cancel pending import (shared-103)

    @Nested
    inner class PendingImportFlow {
        @Test
        fun `saveImportedMeditation persists via repository`() = runTest {
            fakeRepository.emitMeditations(emptyList())
            advanceUntilIdle()
            seedPendingImport()

            viewModel.saveImportedMeditation(
                GuidedMeditation(
                    fileUri = "content://test/uri",
                    fileName = "test.mp3",
                    duration = 600_000L,
                    teacher = "Tara Brach",
                    name = "Body Scan"
                )
            )
            advanceUntilIdle()

            val saved = fakeRepository.addedMeditations
            assertEquals(1, saved.size)
            assertEquals("Tara Brach", saved.first().teacher)
            assertEquals("Body Scan", saved.first().name)
            assertNull(viewModel.uiState.value.pendingImport)
            assertFalse(viewModel.uiState.value.showEditSheet)
        }

        @Test
        fun `saveImportedMeditation persists the chosen gong settings in one step`() = runTest {
            fakeRepository.emitMeditations(emptyList())
            advanceUntilIdle()
            seedPendingImport()

            viewModel.saveImportedMeditation(
                GuidedMeditation(
                    fileUri = "content://test/uri",
                    fileName = "test.mp3",
                    duration = 600_000L,
                    teacher = "Tara Brach",
                    name = "Body Scan",
                    startGongEnabled = true,
                    endGongEnabled = true,
                    gongSoundId = "deep-resonance"
                )
            )
            advanceUntilIdle()

            // The entry is persisted complete in a single add — no separate update
            // step that could leave a gong-less entry behind if it failed.
            val saved = fakeRepository.addedMeditations
            assertEquals(1, saved.size)
            assertTrue(saved.first().startGongEnabled)
            assertTrue(saved.first().endGongEnabled)
            assertEquals("deep-resonance", saved.first().gongSoundId)
            assertFalse(fakeRepository.updateWasCalled)
        }

        @Test
        fun `saveImportedMeditation precomputes the waveform after a successful import`() = runTest {
            fakeRepository.emitMeditations(emptyList())
            advanceUntilIdle()
            seedPendingImport()

            viewModel.saveImportedMeditation(
                GuidedMeditation(
                    fileUri = "content://test/uri",
                    fileName = "test.mp3",
                    duration = 600_000L,
                    teacher = "Tara Brach",
                    name = "Body Scan"
                )
            )
            advanceUntilIdle()

            val imported = fakeRepository.addedMeditations.first()
            verify(mockWaveformProvider).precompute(imported)
        }

        @Test
        fun `cancelImport discards without persisting`() = runTest {
            seedPendingImport()

            viewModel.cancelImport()
            advanceUntilIdle()

            assertTrue(fakeRepository.addedMeditations.isEmpty())
            assertNull(viewModel.uiState.value.pendingImport)
            assertFalse(viewModel.uiState.value.showEditSheet)
        }

        private fun seedPendingImport() {
            val draft = meditation(teacher = "", name = "")
            val pending = PendingImport(
                uri = "content://test/draft.mp3",
                fileName = "draft.mp3",
                metadata = AudioMetadata(duration = 600_000L, artist = null, title = null),
                prefill = ImportPrefill(teacher = null, name = null)
            )
            viewModel.javaClass.getDeclaredField("_uiState").apply {
                isAccessible = true
                @Suppress("UNCHECKED_CAST")
                val flow = get(viewModel) as MutableStateFlow<GuidedMeditationsListUiState>
                flow.value = flow.value.copy(
                    pendingImport = pending,
                    selectedMeditation = draft,
                    showEditSheet = true
                )
            }
        }
    }

    // MARK: - Import failure mapping (B1)

    @Nested
    inner class ImportFailureMapping {
        @Test
        fun `ALREADY_IMPORTED maps to LibraryError AlreadyImported`() = runTest {
            stubImportFailure(FileOpenError.ALREADY_IMPORTED)

            viewModel.importMeditation(mock<Uri>())
            advanceUntilIdle()

            assertEquals(LibraryError.AlreadyImported, viewModel.uiState.value.error)
            assertNull(viewModel.uiState.value.pendingImport)
        }

        @Test
        fun `UNSUPPORTED_FORMAT maps to LibraryError UnsupportedFormat`() = runTest {
            stubImportFailure(FileOpenError.UNSUPPORTED_FORMAT)

            viewModel.importMeditation(mock<Uri>())
            advanceUntilIdle()

            assertEquals(LibraryError.UnsupportedFormat, viewModel.uiState.value.error)
        }

        @Test
        fun `IMPORT_FAILED maps to LibraryError ImportFailed`() = runTest {
            stubImportFailure(FileOpenError.IMPORT_FAILED)

            viewModel.importMeditation(mock<Uri>())
            advanceUntilIdle()

            assertEquals(LibraryError.ImportFailed, viewModel.uiState.value.error)
        }

        @Test
        fun `non-FileOpenException failure also maps to ImportFailed`() = runTest {
            whenever(mockFileOpenHandler.validateAndPrepareImport(any()))
                .thenReturn(Result.failure(RuntimeException("boom")))

            viewModel.importMeditation(mock<Uri>())
            advanceUntilIdle()

            assertEquals(LibraryError.ImportFailed, viewModel.uiState.value.error)
        }

        @Test
        fun `successful import clears error and seeds pendingImport`() = runTest {
            val pending = PendingImport(
                uri = "content://test/import.mp3",
                fileName = "import.mp3",
                metadata = AudioMetadata(duration = 600_000L, artist = "Tara Brach", title = "Body Scan"),
                prefill = ImportPrefill(teacher = "Tara Brach", name = "Body Scan")
            )
            whenever(mockFileOpenHandler.validateAndPrepareImport(any()))
                .thenReturn(Result.success(pending))

            viewModel.importMeditation(mock<Uri>())
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertNull(state.error)
            assertNotNull(state.pendingImport)
            assertTrue(state.showEditSheet)
        }

        private suspend fun stubImportFailure(error: FileOpenError) {
            whenever(mockFileOpenHandler.validateAndPrepareImport(any()))
                .thenReturn(Result.failure(FileOpenException(error)))
        }
    }

    // MARK: - Delete

    @Nested
    inner class DeleteMeditationTests {
        @Test
        fun `confirmDelete sets meditationToDelete`() {
            val item = meditation()

            viewModel.confirmDelete(item)

            val state = viewModel.uiState.value
            assertEquals(item, state.meditationToDelete)
            assertTrue(state.showDeleteConfirmation)
        }

        @Test
        fun `cancelDelete clears state`() {
            viewModel.confirmDelete(meditation())
            viewModel.cancelDelete()

            val state = viewModel.uiState.value
            assertNull(state.meditationToDelete)
            assertFalse(state.showDeleteConfirmation)
        }

        @Test
        fun `executeDelete forwards id to repository`() = runTest {
            val item = meditation(id = "to-delete")
            viewModel.confirmDelete(item)

            viewModel.executeDelete()
            advanceUntilIdle()

            assertTrue(fakeRepository.deleteWasCalled)
            assertEquals("to-delete", fakeRepository.lastDeletedId)
            assertNull(viewModel.uiState.value.meditationToDelete)
            assertFalse(viewModel.uiState.value.showDeleteConfirmation)
        }
    }

    // MARK: - Edit

    @Nested
    inner class EditSheetTests {
        @Test
        fun `showEditSheet sets selectedMeditation and flag`() {
            val item = meditation()

            viewModel.showEditSheet(item)

            val state = viewModel.uiState.value
            assertEquals(item, state.selectedMeditation)
            assertTrue(state.showEditSheet)
        }

        @Test
        fun `hideEditSheet clears selection and flag`() {
            val item = meditation()
            viewModel.showEditSheet(item)

            viewModel.hideEditSheet()

            val state = viewModel.uiState.value
            assertNull(state.selectedMeditation)
            assertFalse(state.showEditSheet)
        }

        @Test
        fun `showEditSheet loads the waveform into state for the mini bars`() = runTest {
            val item = meditation(id = "med-wave")
            val waveform = MeditationWaveform(List(MeditationWaveform.SAMPLE_COUNT) { 0.5f })
            wheneverBlocking { mockWaveformProvider.waveform(item) }.thenReturn(waveform)

            viewModel.showEditSheet(item)
            advanceUntilIdle()

            assertEquals(waveform, viewModel.uiState.value.editorWaveform)
        }

        @Test
        fun `showEditSheet leaves waveform null when generation fails`() = runTest {
            val item = meditation(id = "med-fail")
            wheneverBlocking { mockWaveformProvider.waveform(item) }
                .thenAnswer { throw WaveformGenerationException.DecodingFailed("boom") }

            viewModel.showEditSheet(item)
            advanceUntilIdle()

            assertNull(viewModel.uiState.value.editorWaveform)
        }

        @Test
        fun `hideEditSheet clears the loaded waveform`() = runTest {
            val item = meditation(id = "med-wave")
            val waveform = MeditationWaveform(List(MeditationWaveform.SAMPLE_COUNT) { 0.5f })
            wheneverBlocking { mockWaveformProvider.waveform(item) }.thenReturn(waveform)
            viewModel.showEditSheet(item)
            advanceUntilIdle()

            viewModel.hideEditSheet()

            assertNull(viewModel.uiState.value.editorWaveform)
        }

        @Test
        fun `updateMeditation persists via repository`() = runTest {
            val item = meditation()
            viewModel.showEditSheet(item)

            viewModel.updateMeditation(item)
            advanceUntilIdle()

            assertTrue(fakeRepository.updateWasCalled)
            assertEquals(item, fakeRepository.lastUpdatedMeditation)
            assertFalse(viewModel.uiState.value.showEditSheet)
        }
    }

    // MARK: - Preview

    @Nested
    inner class PreviewTests {
        @Test
        fun `startPreview updates id and forwards to service`() {
            val item = meditation(id = "med-1")

            viewModel.startPreview(item)

            assertEquals("med-1", viewModel.uiState.value.previewingMeditationId)
            verify(mockAudioService).playMeditationPreview(item.fileUri)
        }

        @Test
        fun `stopPreview clears id and forwards to service`() {
            val item = meditation(id = "med-1")
            viewModel.startPreview(item)

            viewModel.stopPreview()

            assertNull(viewModel.uiState.value.previewingMeditationId)
            verify(mockAudioService).stopMeditationPreview()
        }

        @Test
        fun `stopPreview is idempotent when no preview active`() {
            viewModel.stopPreview()

            assertNull(viewModel.uiState.value.previewingMeditationId)
            verify(mockAudioService, never()).stopMeditationPreview()
        }

        @Test
        fun `seekPreview forwards position`() {
            viewModel.seekPreview(42_000L)
            verify(mockAudioService).seekMeditationPreview(42_000L)
        }

        @Test
        fun `position flow mirrors into state`() = runTest {
            previewPositionFlow.value = 12_345L
            advanceUntilIdle()

            assertEquals(12_345L, viewModel.uiState.value.previewCurrentTimeMs)
        }

        @Test
        fun `duration flow mirrors into state`() = runTest {
            previewDurationFlow.value = 600_000L
            advanceUntilIdle()

            assertEquals(600_000L, viewModel.uiState.value.previewDurationMs)
        }

        @Test
        fun `completion flow clears previewing id`() = runTest {
            val item = meditation(id = "med-x")
            viewModel.startPreview(item)

            previewCompletionFlow.emit(Unit)
            advanceUntilIdle()

            assertNull(viewModel.uiState.value.previewingMeditationId)
        }
    }

    // MARK: - Search

    @Nested
    inner class LibrarySearchStateTransitions {
        @Test
        fun `state is Idle when query empty and not focused`() = runTest {
            fakeRepository.emitMeditations(listOf(meditation()))
            advanceUntilIdle()

            assertEquals(
                com.stillmoment.domain.models.LibrarySearchState.Idle,
                viewModel.uiState.value.searchState
            )
        }

        @Test
        fun `state is History when query empty and focused`() = runTest {
            fakeRepository.emitMeditations(listOf(meditation()))
            advanceUntilIdle()
            viewModel.setSearchFocused(true)

            assertEquals(
                com.stillmoment.domain.models.LibrarySearchState.History,
                viewModel.uiState.value.searchState
            )
        }

        @Test
        fun `state is Results when query has hits`() = runTest {
            fakeRepository.emitMeditations(listOf(meditation(name = "Atemmeditation")))
            advanceUntilIdle()
            viewModel.setSearchFocused(true)
            viewModel.updateSearchQuery("Atem")

            assertEquals(
                com.stillmoment.domain.models.LibrarySearchState.Results,
                viewModel.uiState.value.searchState
            )
        }

        @Test
        fun `state is Empty when query has no hits`() = runTest {
            fakeRepository.emitMeditations(listOf(meditation(name = "Atemmeditation")))
            advanceUntilIdle()
            viewModel.setSearchFocused(true)
            viewModel.updateSearchQuery("xyz123")

            assertEquals(
                com.stillmoment.domain.models.LibrarySearchState.Empty,
                viewModel.uiState.value.searchState
            )
        }
    }

    @Nested
    inner class LibrarySearchHistoryCommit {
        @Test
        fun `submitSearch commits to history when results exist`() = runTest {
            fakeRepository.emitMeditations(listOf(meditation(name = "Atem")))
            advanceUntilIdle()

            viewModel.updateSearchQuery("atem")
            viewModel.submitSearch()
            advanceUntilIdle()

            assertEquals(listOf("atem"), viewModel.uiState.value.searchHistory.toList())
        }

        @Test
        fun `submitSearch does not commit when no results`() = runTest {
            fakeRepository.emitMeditations(listOf(meditation(name = "Atem")))
            advanceUntilIdle()

            viewModel.updateSearchQuery("xyz123")
            viewModel.submitSearch()
            advanceUntilIdle()

            assertTrue(viewModel.uiState.value.searchHistory.isEmpty())
        }

        @Test
        fun `recordSearchCommittedByOpening commits and resets`() = runTest {
            fakeRepository.emitMeditations(listOf(meditation(name = "Atem")))
            advanceUntilIdle()
            viewModel.setSearchFocused(true)
            viewModel.updateSearchQuery("atem")

            viewModel.recordSearchCommittedByOpening()
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertEquals(listOf("atem"), state.searchHistory.toList())
            assertEquals("", state.searchQuery)
            assertFalse(state.isSearchFocused)
        }

        @Test
        fun `clearHistory empties the persistent store`() = runTest {
            fakeSearchHistoryRepository.seed(listOf("a", "b", "c"))
            advanceUntilIdle()
            assertEquals(3, viewModel.uiState.value.searchHistory.size)

            viewModel.clearHistory()
            advanceUntilIdle()

            assertTrue(viewModel.uiState.value.searchHistory.isEmpty())
        }
    }

    @Nested
    inner class LibrarySearchResetBehaviour {
        @Test
        fun `resetSearch clears query and focus`() {
            viewModel.setSearchFocused(true)
            viewModel.updateSearchQuery("atem")

            viewModel.resetSearch()

            val state = viewModel.uiState.value
            assertEquals("", state.searchQuery)
            assertFalse(state.isSearchFocused)
        }

        @Test
        fun `selectHistoryEntry sets query`() {
            viewModel.setSearchFocused(true)

            viewModel.selectHistoryEntry("Tara")

            val state = viewModel.uiState.value
            assertEquals("Tara", state.searchQuery)
            assertTrue(state.isSearchFocused)
        }
    }

    // MARK: - Content Guide

    @Nested
    inner class ContentGuideSheetFlow {
        @Test
        fun `openGuideSheet loads sources for given language and shows sheet`() = runTest {
            fakeSourceRepository.catalog = mapOf(
                "de" to listOf(makeTestSource("mangold")),
                "en" to listOf(makeTestSource("tara-brach"))
            )

            viewModel.openGuideSheet("de")
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertTrue(state.showGuideSheet)
            assertEquals(listOf("mangold"), state.guideSources.map { it.id })
        }

        @Test
        fun `closeGuideSheet hides sheet`() = runTest {
            fakeSourceRepository.catalog = mapOf("en" to listOf(makeTestSource("tara")))
            viewModel.openGuideSheet("en")
            advanceUntilIdle()

            viewModel.closeGuideSheet()
            advanceUntilIdle()

            assertFalse(viewModel.uiState.value.showGuideSheet)
        }
    }

    // MARK: - Error handling

    @Nested
    inner class ErrorHandlingTests {
        @Test
        fun `clearError sets error to null`() = runTest {
            viewModel.javaClass.getDeclaredField("_uiState").apply {
                isAccessible = true
                @Suppress("UNCHECKED_CAST")
                val flow = get(viewModel) as MutableStateFlow<GuidedMeditationsListUiState>
                flow.value = flow.value.copy(error = LibraryError.ImportFailed)
            }
            assertNotNull(viewModel.uiState.value.error)

            viewModel.clearError()

            assertNull(viewModel.uiState.value.error)
        }
    }

    // MARK: - Test helpers

    private fun meditation(
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

    private fun makeTestSource(id: String) = MeditationSource(
        id = id,
        name = id,
        author = null,
        description = "desc",
        host = "h",
        url = "https://example.com/$id"
    )
}

// MARK: - Fakes

class FakeSearchHistoryRepository : SearchHistoryRepository {
    private val _history = MutableStateFlow<List<String>>(emptyList())

    override val historyFlow: Flow<List<String>>
        get() = _history

    override suspend fun save(history: List<String>) {
        _history.value = history
    }

    override suspend fun clear() {
        _history.value = emptyList()
    }

    fun seed(history: List<String>) {
        _history.value = history
    }
}

class FakeMeditationSourceRepository : MeditationSourceRepository {
    var catalog: Map<String, List<MeditationSource>> = emptyMap()

    override fun sources(languageCode: String): List<MeditationSource> {
        return catalog[languageCode] ?: catalog["en"].orEmpty()
    }
}

class FakeGuidedMeditationRepository : GuidedMeditationRepository {
    private val _meditations = MutableStateFlow<List<GuidedMeditation>>(emptyList())

    val addedMeditations: MutableList<GuidedMeditation> = mutableListOf()
    var deleteWasCalled = false
        private set
    var updateWasCalled = false
        private set
    var lastDeletedId: String? = null
        private set
    var lastUpdatedMeditation: GuidedMeditation? = null
        private set

    var extractedMetadata: AudioMetadata = AudioMetadata(duration = 0L, artist = null, title = null)
    var fileName: String = "test.mp3"

    override val meditationsFlow: Flow<List<GuidedMeditation>>
        get() = _meditations

    override suspend fun extractMetadata(uri: String): AudioMetadata = extractedMetadata

    override suspend fun getFileName(uri: String): String = fileName

    override suspend fun addMeditation(
        sourceUri: String,
        fileName: String,
        metadata: AudioMetadata,
        teacher: String,
        name: String,
        startGongEnabled: Boolean,
        endGongEnabled: Boolean,
        gongSoundId: String
    ): Result<GuidedMeditation> {
        val item = GuidedMeditation(
            fileUri = sourceUri,
            fileName = fileName,
            duration = metadata.duration,
            teacher = teacher,
            name = name,
            startGongEnabled = startGongEnabled,
            endGongEnabled = endGongEnabled,
            gongSoundId = gongSoundId
        )
        addedMeditations += item
        _meditations.value = _meditations.value + item
        return Result.success(item)
    }

    override suspend fun deleteMeditation(id: String) {
        deleteWasCalled = true
        lastDeletedId = id
        _meditations.value = _meditations.value.filter { it.id != id }
    }

    override suspend fun updateMeditation(meditation: GuidedMeditation) {
        updateWasCalled = true
        lastUpdatedMeditation = meditation
        _meditations.value = _meditations.value.map {
            if (it.id == meditation.id) meditation else it
        }
    }

    override suspend fun getMeditation(id: String): GuidedMeditation? {
        return _meditations.value.find { it.id == id }
    }

    fun emitMeditations(meditations: List<GuidedMeditation>) {
        _meditations.value = meditations
    }
}
