package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.data.FileOpenException
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.domain.models.LibrarySearchState
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.domain.models.PendingImport
import com.stillmoment.domain.models.groupByTeacher
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.repositories.MeditationSourceRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.repositories.SearchHistoryRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.LibrarySearchEngine
import com.stillmoment.domain.services.SearchHistory
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.toImmutableList
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * UI State for the Guided Meditations Library screen.
 */
data class GuidedMeditationsListUiState(
    /** Meditations grouped by teacher */
    val groups: ImmutableList<GuidedMeditationGroup> = persistentListOf(),
    /** Flat meditation list (for search; identical content to groups but ungrouped) */
    val allMeditations: ImmutableList<GuidedMeditation> = persistentListOf(),
    /** Whether data is being loaded */
    val isLoading: Boolean = true,
    /**
     * UI-level error from the import flow, or `null` when nothing went wrong.
     * The composable layer resolves each [LibraryError] case to a localized
     * string via `stringResource(...)`.
     */
    val error: LibraryError? = null,
    /** Currently selected meditation for editing */
    val selectedMeditation: GuidedMeditation? = null,
    /** Whether the edit sheet is shown */
    val showEditSheet: Boolean = false,
    /** Pending import waiting for the user to confirm in the edit sheet (shared-103) */
    val pendingImport: PendingImport? = null,
    /** Whether delete confirmation is shown */
    val showDeleteConfirmation: Boolean = false,
    /** Meditation pending deletion (awaiting confirmation) */
    val meditationToDelete: GuidedMeditation? = null,
    /** ID of the meditation currently being previewed, or null if none */
    val previewingMeditationId: String? = null,
    /** Current playback position of the active library preview (ms). 0 when idle (shared-098). */
    val previewCurrentTimeMs: Long = 0L,
    /** Total duration of the active library preview (ms). 0 when idle (shared-098). */
    val previewDurationMs: Long = 0L,
    /** Whether the Content Guide sheet is shown */
    val showGuideSheet: Boolean = false,
    /** Curated sources for the current locale (Content Guide) */
    val guideSources: ImmutableList<MeditationSource> = persistentListOf(),
    // MARK: - Library search (shared-101)
    /** Current search query (raw user input, not trimmed) */
    val searchQuery: String = "",
    /** Whether the search field currently holds focus */
    val isSearchFocused: Boolean = false,
    /** Persisted search history (newest first, max 6 entries) */
    val searchHistory: ImmutableList<String> = persistentListOf()
) {
    /** Total number of meditations across all groups */
    val totalCount: Int
        get() = groups.sumOf { it.count }

    /** Whether the library is empty */
    val isEmpty: Boolean
        get() = groups.isEmpty() && !isLoading

    /** List of unique teacher names for autocomplete */
    val availableTeachers: ImmutableList<String>
        get() = groups.map { it.teacher }.distinct().sorted().toImmutableList()

    /**
     * Currently visible search results for the query — empty if no query.
     */
    val searchResults: ImmutableList<GuidedMeditation>
        get() = LibrarySearchEngine.search(allMeditations, searchQuery).toImmutableList()

    /**
     * Derived view state for the library body switch.
     */
    val searchState: LibrarySearchState
        get() {
            val trimmed = searchQuery.trim()
            if (trimmed.isEmpty()) {
                return if (isSearchFocused) LibrarySearchState.History else LibrarySearchState.Idle
            }
            return if (searchResults.isEmpty()) LibrarySearchState.Empty else LibrarySearchState.Results
        }
}

/**
 * ViewModel for the Guided Meditations Library screen.
 *
 * Manages the list of guided meditations, import functionality,
 * and edit/delete operations.
 */
@Suppress("TooManyFunctions") // ViewModel orchestrates library + search + import + preview flows
@HiltViewModel
class GuidedMeditationsListViewModel
@Inject
constructor(
    private val repository: GuidedMeditationRepository,
    private val audioService: AudioServiceProtocol,
    private val meditationSourceRepository: MeditationSourceRepository,
    private val searchHistoryRepository: SearchHistoryRepository,
    private val fileOpenHandler: FileOpenHandler,
    private val praxisRepository: PraxisRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(GuidedMeditationsListUiState())
    val uiState: StateFlow<GuidedMeditationsListUiState> = _uiState.asStateFlow()

    init {
        observeMeditations()
        observeSearchHistory()
        observePreviewPosition()
        observePreviewDuration()
        observePreviewCompletion()
    }

    /**
     * Observes meditation list changes and updates UI state.
     */
    private fun observeMeditations() {
        viewModelScope.launch {
            repository.meditationsFlow.collect { meditations ->
                val groups = meditations.groupByTeacher().toImmutableList()
                _uiState.update {
                    it.copy(
                        groups = groups,
                        allMeditations = meditations.toImmutableList(),
                        isLoading = false
                    )
                }
            }
        }
    }

    private fun observeSearchHistory() {
        viewModelScope.launch {
            searchHistoryRepository.historyFlow.collect { history ->
                _uiState.update { it.copy(searchHistory = history.toImmutableList()) }
            }
        }
    }

    private fun observePreviewPosition() {
        viewModelScope.launch {
            audioService.meditationPreviewPositionFlow.collect { positionMs ->
                _uiState.update { it.copy(previewCurrentTimeMs = positionMs) }
            }
        }
    }

    private fun observePreviewDuration() {
        viewModelScope.launch {
            audioService.meditationPreviewDurationFlow.collect { durationMs ->
                _uiState.update { it.copy(previewDurationMs = durationMs) }
            }
        }
    }

    private fun observePreviewCompletion() {
        viewModelScope.launch {
            audioService.meditationPreviewCompletionFlow.collect {
                _uiState.update { it.copy(previewingMeditationId = null) }
            }
        }
    }

    // MARK: - Import (shared-103)

    /**
     * Starts the share-import flow. Validates the file, extracts metadata,
     * computes prefill against the current library, and opens the edit sheet
     * in IMPORT mode. Persistence happens on save (see [saveImportedMeditation]).
     *
     * @param uri Content URI from the share intent
     */
    fun importMeditation(uri: Uri) {
        viewModelScope.launch {
            _uiState.update { it.copy(error = null) }
            val result = fileOpenHandler.validateAndPrepareImport(uri)
            result.onSuccess { pending ->
                // Re-compute the prefill so it picks up the *current* known
                // teachers. FileOpenHandler stays library-agnostic.
                val refinedPrefill = ImportPrefill.compute(
                    metadata = pending.metadata,
                    fileName = pending.fileName,
                    knownTeachers = _uiState.value.availableTeachers
                )
                val refined = pending.copy(prefill = refinedPrefill)
                val draft = GuidedMeditation(
                    fileUri = refined.uri,
                    fileName = refined.fileName,
                    duration = refined.metadata.duration,
                    teacher = refined.prefill.teacher ?: "",
                    name = refined.prefill.name ?: ""
                )
                _uiState.update {
                    it.copy(
                        pendingImport = refined,
                        selectedMeditation = draft,
                        showEditSheet = true,
                        error = null
                    )
                }
            }.onFailure { error ->
                val libraryError = when ((error as? FileOpenException)?.error) {
                    FileOpenError.ALREADY_IMPORTED -> LibraryError.AlreadyImported
                    FileOpenError.UNSUPPORTED_FORMAT -> LibraryError.UnsupportedFormat
                    FileOpenError.IMPORT_FAILED, null -> LibraryError.ImportFailed
                }
                _uiState.update { it.copy(error = libraryError) }
            }
        }
    }

    /**
     * Persists the pending import using the (potentially edited) values from
     * the edit sheet. Closes the sheet and clears the pending state.
     */
    fun saveImportedMeditation(edited: GuidedMeditation) {
        val pending = _uiState.value.pendingImport ?: return
        viewModelScope.launch {
            // Persist the entry complete with its gong settings (shared-106) in a
            // single operation, so a failure can never leave a gong-less entry behind.
            repository.addMeditation(
                sourceUri = pending.uri,
                fileName = pending.fileName,
                metadata = pending.metadata,
                teacher = edited.teacher.trim(),
                name = edited.name.trim(),
                startGongEnabled = edited.startGongEnabled,
                endGongEnabled = edited.endGongEnabled,
                gongSoundId = edited.gongSoundId
            ).onFailure {
                // Repository failures during the save step are surfaced as the
                // generic "Import failed" message — the exact reason (IO,
                // metadata, copy) is not actionable for the user.
                _uiState.update { it.copy(error = LibraryError.ImportFailed) }
            }
            _uiState.update {
                it.copy(
                    pendingImport = null,
                    selectedMeditation = null,
                    showEditSheet = false
                )
            }
        }
    }

    /**
     * Discards the pending import without persisting anything. Used by the
     * Cancel button and modal-swipe-down in the import edit sheet.
     */
    fun cancelImport() {
        _uiState.update {
            it.copy(
                pendingImport = null,
                selectedMeditation = null,
                showEditSheet = false
            )
        }
    }

    // MARK: - Delete

    fun confirmDelete(meditation: GuidedMeditation) {
        _uiState.update {
            it.copy(
                meditationToDelete = meditation,
                showDeleteConfirmation = true
            )
        }
    }

    fun cancelDelete() {
        _uiState.update {
            it.copy(
                meditationToDelete = null,
                showDeleteConfirmation = false
            )
        }
    }

    fun executeDelete() {
        val meditation = _uiState.value.meditationToDelete ?: return

        viewModelScope.launch {
            repository.deleteMeditation(meditation.id)
            _uiState.update {
                it.copy(
                    meditationToDelete = null,
                    showDeleteConfirmation = false
                )
            }
        }
    }

    // MARK: - Edit

    /**
     * Shows the edit sheet for a meditation (Edit mode).
     */
    fun showEditSheet(meditation: GuidedMeditation) {
        _uiState.update {
            it.copy(
                selectedMeditation = meditation,
                showEditSheet = true,
                pendingImport = null
            )
        }
    }

    /**
     * Hides the edit sheet (Edit mode — does not affect [pendingImport]).
     */
    fun hideEditSheet() {
        _uiState.update {
            it.copy(
                selectedMeditation = null,
                showEditSheet = false
            )
        }
    }

    /**
     * Updates a meditation's metadata (Edit mode).
     */
    fun updateMeditation(meditation: GuidedMeditation) {
        viewModelScope.launch {
            repository.updateMeditation(meditation)
            hideEditSheet()
        }
    }

    // MARK: - Preview

    fun startPreview(meditation: GuidedMeditation) {
        _uiState.update { it.copy(previewingMeditationId = meditation.id) }
        audioService.playMeditationPreview(meditation.fileUri)
    }

    fun stopPreview() {
        if (_uiState.value.previewingMeditationId == null) return
        _uiState.update { it.copy(previewingMeditationId = null) }
        audioService.stopMeditationPreview()
    }

    fun seekPreview(positionMs: Long) {
        audioService.seekMeditationPreview(positionMs)
    }

    // MARK: - Gong Preview (editor, shared-106)

    /**
     * Previews a gong sound in the editor at the timer's gong volume.
     * Mirrors iOS: the per-meditation gong volume follows the timer settings.
     */
    fun previewGong(soundId: String) {
        viewModelScope.launch {
            audioService.playGongPreview(soundId, praxisRepository.load().gongVolume)
        }
    }

    fun stopGongPreview() {
        audioService.stopGongPreview()
    }

    // MARK: - Content Guide

    fun openGuideSheet(languageCode: String) {
        val sources = meditationSourceRepository.sources(languageCode).toImmutableList()
        _uiState.update { it.copy(guideSources = sources, showGuideSheet = true) }
    }

    fun closeGuideSheet() {
        _uiState.update { it.copy(showGuideSheet = false) }
    }

    // MARK: - Library Search (shared-101)

    fun updateSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }

    fun setSearchFocused(focused: Boolean) {
        _uiState.update { it.copy(isSearchFocused = focused) }
    }

    fun submitSearch() {
        val state = _uiState.value
        if (state.searchResults.isEmpty()) {
            return
        }
        commitCurrentQueryToHistory(state.searchQuery)
    }

    fun recordSearchCommittedByOpening() {
        val state = _uiState.value
        if (state.searchResults.isNotEmpty()) {
            commitCurrentQueryToHistory(state.searchQuery)
        }
        resetSearch()
    }

    fun selectHistoryEntry(term: String) {
        _uiState.update { it.copy(searchQuery = term) }
    }

    fun clearHistory() {
        viewModelScope.launch {
            searchHistoryRepository.clear()
        }
    }

    fun resetSearch() {
        _uiState.update { it.copy(searchQuery = "", isSearchFocused = false) }
    }

    private fun commitCurrentQueryToHistory(query: String) {
        val currentHistory = _uiState.value.searchHistory
        val updated = SearchHistory.prepend(
            history = currentHistory,
            term = query,
            limit = SEARCH_HISTORY_LIMIT
        )
        if (updated == currentHistory) {
            return
        }
        viewModelScope.launch {
            searchHistoryRepository.save(updated)
        }
    }

    // MARK: - Error Handling

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    override fun onCleared() {
        super.onCleared()
        audioService.stopMeditationPreview()
    }

    companion object {
        /** Maximum entries in the persistent search history (shared-101). */
        const val SEARCH_HISTORY_LIMIT = 6
    }
}
