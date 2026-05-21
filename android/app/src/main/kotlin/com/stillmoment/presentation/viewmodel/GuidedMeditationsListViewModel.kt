package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.domain.models.LibrarySearchState
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.domain.models.groupByTeacher
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.repositories.MeditationSourceRepository
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
import kotlinx.coroutines.flow.map
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
    /** Error message if any */
    val error: String? = null,
    /** Currently selected meditation for editing */
    val selectedMeditation: GuidedMeditation? = null,
    /** Whether the edit sheet is shown */
    val showEditSheet: Boolean = false,
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
     *
     * Computed via [LibrarySearchEngine.search] over [allMeditations].
     */
    val searchResults: ImmutableList<GuidedMeditation>
        get() = LibrarySearchEngine.search(allMeditations, searchQuery).toImmutableList()

    /**
     * Derived view state for the library body switch.
     *
     * - Empty query, not focused → [LibrarySearchState.Idle] (gruppierte Liste).
     * - Empty query, focused → [LibrarySearchState.History].
     * - Query with hits → [LibrarySearchState.Results].
     * - Query without hits → [LibrarySearchState.Empty].
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
    private val searchHistoryRepository: SearchHistoryRepository
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

    /**
     * Observes the persisted search history (shared-101) and mirrors it into UI state.
     */
    private fun observeSearchHistory() {
        viewModelScope.launch {
            searchHistoryRepository.historyFlow.collect { history ->
                _uiState.update { it.copy(searchHistory = history.toImmutableList()) }
            }
        }
    }

    /**
     * Mirrors the AudioService preview position into UI state (shared-098).
     * The slider in the library item reads `previewCurrentTimeMs` to render.
     */
    private fun observePreviewPosition() {
        viewModelScope.launch {
            audioService.meditationPreviewPositionFlow.collect { positionMs ->
                _uiState.update { it.copy(previewCurrentTimeMs = positionMs) }
            }
        }
    }

    /**
     * Mirrors the AudioService preview duration into UI state (shared-098).
     */
    private fun observePreviewDuration() {
        viewModelScope.launch {
            audioService.meditationPreviewDurationFlow.collect { durationMs ->
                _uiState.update { it.copy(previewDurationMs = durationMs) }
            }
        }
    }

    /**
     * Listens for natural end-of-file completions (shared-098) and flips the
     * preview back to idle so the play button switches from stop to play and
     * the slider fades out.
     */
    private fun observePreviewCompletion() {
        viewModelScope.launch {
            audioService.meditationPreviewCompletionFlow.collect {
                _uiState.update { it.copy(previewingMeditationId = null) }
            }
        }
    }

    // MARK: - Import

    /**
     * Imports a meditation from the given URI.
     *
     * @param uri Content URI from file picker
     */
    fun importMeditation(uri: Uri) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            repository.importMeditation(uri)
                .onSuccess { meditation ->
                    _uiState.update { it.copy(isLoading = false) }
                    showEditSheet(meditation)
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            error = error.message ?: "Import failed",
                            isLoading = false
                        )
                    }
                }
        }
    }

    // MARK: - Delete

    /**
     * Shows delete confirmation dialog.
     *
     * @param meditation Meditation to delete
     */
    fun confirmDelete(meditation: GuidedMeditation) {
        _uiState.update {
            it.copy(
                meditationToDelete = meditation,
                showDeleteConfirmation = true
            )
        }
    }

    /**
     * Cancels the delete operation.
     */
    fun cancelDelete() {
        _uiState.update {
            it.copy(
                meditationToDelete = null,
                showDeleteConfirmation = false
            )
        }
    }

    /**
     * Executes the delete operation for the pending meditation.
     */
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
     * Shows the edit sheet for a meditation.
     *
     * @param meditation Meditation to edit
     */
    fun showEditSheet(meditation: GuidedMeditation) {
        _uiState.update {
            it.copy(
                selectedMeditation = meditation,
                showEditSheet = true
            )
        }
    }

    /**
     * Hides the edit sheet.
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
     * Updates a meditation's metadata.
     *
     * @param meditation Updated meditation object
     */
    fun updateMeditation(meditation: GuidedMeditation) {
        viewModelScope.launch {
            repository.updateMeditation(meditation)
            hideEditSheet()
        }
    }

    /**
     * Updates the custom teacher name for the selected meditation.
     *
     * @param teacher New teacher name (null to reset to original)
     */
    fun updateCustomTeacher(teacher: String?) {
        val meditation = _uiState.value.selectedMeditation ?: return
        val updated = meditation.withCustomTeacher(teacher?.takeIf { it.isNotBlank() })
        _uiState.update { it.copy(selectedMeditation = updated) }
    }

    /**
     * Updates the custom name for the selected meditation.
     *
     * @param name New name (null to reset to original)
     */
    fun updateCustomName(name: String?) {
        val meditation = _uiState.value.selectedMeditation ?: return
        val updated = meditation.withCustomName(name?.takeIf { it.isNotBlank() })
        _uiState.update { it.copy(selectedMeditation = updated) }
    }

    // MARK: - Preview

    /**
     * Starts a meditation preview. Stops any previously running preview.
     *
     * @param meditation Meditation to preview
     */
    fun startPreview(meditation: GuidedMeditation) {
        _uiState.update { it.copy(previewingMeditationId = meditation.id) }
        audioService.playMeditationPreview(meditation.fileUri)
    }

    /**
     * Stops the current meditation preview. Idempotent.
     */
    fun stopPreview() {
        if (_uiState.value.previewingMeditationId == null) return
        _uiState.update { it.copy(previewingMeditationId = null) }
        audioService.stopMeditationPreview()
    }

    /**
     * Scrubs the active library preview to a new position (shared-098).
     * Apple-Music-style: audio keeps playing through the seek.
     *
     * @param positionMs Target position in milliseconds; the service clamps to `[0, duration]`.
     */
    fun seekPreview(positionMs: Long) {
        audioService.seekMeditationPreview(positionMs)
    }

    // MARK: - Content Guide

    /**
     * Loads the curated meditation sources for the given language and shows the guide sheet.
     *
     * @param languageCode Active language code (`"de"`, `"en"`, ...).
     */
    fun openGuideSheet(languageCode: String) {
        val sources = meditationSourceRepository.sources(languageCode).toImmutableList()
        _uiState.update { it.copy(guideSources = sources, showGuideSheet = true) }
    }

    /**
     * Hides the Content Guide sheet.
     */
    fun closeGuideSheet() {
        _uiState.update { it.copy(showGuideSheet = false) }
    }

    // MARK: - Library Search (shared-101)

    /**
     * Updates the search query (live filter — no debounce, runs on every key stroke).
     */
    fun updateSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }

    /**
     * Marks the search field as focused / unfocused.
     */
    fun setSearchFocused(focused: Boolean) {
        _uiState.update { it.copy(isSearchFocused = focused) }
    }

    /**
     * Confirms the current query via IME-Done (Search-Action).
     *
     * - Hits → commit to history.
     * - No hits → ignored (history remains untouched, see ticket AC).
     */
    fun submitSearch() {
        val state = _uiState.value
        if (state.searchResults.isEmpty()) {
            return
        }
        commitCurrentQueryToHistory(state.searchQuery)
    }

    /**
     * Called when the user opens a search result.
     *
     * - Commits the query to history (only if hits existed).
     * - Resets the search field so the library returns to Idle on the way back.
     */
    fun recordSearchCommittedByOpening() {
        val state = _uiState.value
        if (state.searchResults.isNotEmpty()) {
            commitCurrentQueryToHistory(state.searchQuery)
        }
        resetSearch()
    }

    /**
     * Sets the search query from a tapped history entry (re-runs the search immediately).
     */
    fun selectHistoryEntry(term: String) {
        _uiState.update { it.copy(searchQuery = term) }
    }

    /**
     * Clears the entire search history.
     */
    fun clearHistory() {
        viewModelScope.launch {
            searchHistoryRepository.clear()
        }
    }

    /**
     * Resets the search field (query + focus) — used on tab change and after opening a result.
     */
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

    /**
     * Clears the current error message.
     */
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
