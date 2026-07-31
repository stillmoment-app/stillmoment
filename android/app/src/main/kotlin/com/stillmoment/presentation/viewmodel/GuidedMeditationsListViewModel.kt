package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.data.FileOpenException
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.domain.models.DurationFilter
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.domain.models.LibrarySearchState
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.models.PendingImport
import com.stillmoment.domain.models.groupByTeacher
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.repositories.MeditationSourceRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.repositories.SearchHistoryRepository
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.LibrarySearchEngine
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.SearchHistory
import com.stillmoment.domain.services.WaveformGenerationException
import com.stillmoment.domain.services.WaveformProviderProtocol
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.ImmutableSet
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.toImmutableList
import kotlinx.collections.immutable.toImmutableSet
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
    /**
     * Cached waveform for the meditation currently being edited (shared-107). Drives the
     * mini bars in the playback-range card. `null` until loaded, on a decode failure, or in
     * import mode (no cached waveform yet) — the card then shows its fallback line.
     */
    val editorWaveform: MeditationWaveform? = null,
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
    val searchHistory: ImmutableList<String> = persistentListOf(),
    // MARK: - Dauer-Filter (shared-081)
    /** Aktive Dauer-Stufe. [DurationFilter.ALL] bedeutet: kein Filter, die Liste bleibt gruppiert. */
    val durationFilter: DurationFilter = DurationFilter.ALL
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
     * Der Suchbegriff ohne umgebende Leerzeichen — die Fassung, die tatsaechlich sucht
     * und die der „Kein Treffer"-Text zitiert.
     */
    val trimmedSearchQuery: String
        get() = searchQuery.trim()

    /** Ob eine Stufe ausser [DurationFilter.ALL] gewaehlt ist. */
    val isFilterActive: Boolean
        get() = durationFilter != DurationFilter.ALL

    /**
     * Ob der Header die kompakte Chip-Variante zeigt statt der vollen Filterzeile.
     *
     * Ein vorhandener Suchtext genuegt — beim Scrollen in der Trefferliste blendet
     * `SearchResultsList` die Tastatur aus, der Chip muss aber weiter erklaeren,
     * warum eine Meditation fehlt.
     */
    val isSearchModeActive: Boolean
        get() = isSearchFocused || trimmedSearchQuery.isNotEmpty()

    /**
     * Die Meditationen, die Suche **und** Filter gemeinsam erfuellen.
     *
     * Ohne Suchtext folgt die Reihenfolge der gruppierten Ansicht (Lehrer:in alphabetisch),
     * mit Suchtext der Relevanz-Rangfolge der Suche.
     */
    val visibleMeditations: ImmutableList<GuidedMeditation>
        get() = durationFilter.apply(searchScopedMeditations).toImmutableList()

    /**
     * Die Stufen, die mindestens eine Meditation der Bibliothek enthalten.
     *
     * Bewusst gegen den Gesamtbestand berechnet, nicht gegen [visibleMeditations] — sonst
     * wuerde eine gesetzte Stufe alle anderen blass schalten und der Filter waere eine
     * Einbahnstrasse. Der Suchtext spielt keine Rolle: sobald welcher im Feld steht, ist
     * die Stufenzeile ohnehin dem Chip gewichen.
     */
    val availableDurationSteps: ImmutableSet<DurationFilter>
        get() = DurationFilter.availableSteps(allMeditations).toImmutableSet()

    /**
     * Derived view state for the library body switch.
     */
    val searchState: LibrarySearchState
        get() {
            if (trimmedSearchQuery.isEmpty()) {
                if (isSearchFocused) {
                    return LibrarySearchState.History
                }
                if (!isFilterActive) {
                    return LibrarySearchState.Idle
                }
                return if (visibleMeditations.isEmpty()) LibrarySearchState.Empty else LibrarySearchState.Filtered
            }
            return if (visibleMeditations.isEmpty()) LibrarySearchState.Empty else LibrarySearchState.Results
        }

    /**
     * Die Menge, auf die **nur** der Suchtext wirkt — Basis fuer den Dauer-Filter.
     *
     * Ohne Suchtext ist das die Bibliothek in der Reihenfolge der gruppierten Ansicht,
     * damit die flache Liste dieselbe Ordnung zeigt wie die gruppierte darueber.
     */
    private val searchScopedMeditations: List<GuidedMeditation>
        get() = if (trimmedSearchQuery.isEmpty()) groups.flatMap { it.meditations } else searchResults
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
    private val praxisRepository: PraxisRepository,
    private val waveformProvider: WaveformProviderProtocol,
    private val logger: LoggerProtocol
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
            ).onSuccess { imported ->
                // Precompute the waveform in the background so the trim editor opens
                // without a decode wait (Phase C). Import itself stays fast.
                waveformProvider.precompute(imported)
            }.onFailure {
                // Repository failures during the save step are surfaced as the
                // generic "Import failed" message — the exact reason (IO,
                // metadata, copy) is not actionable for the user.
                _uiState.update { it.copy(error = LibraryError.ImportFailed) }
            }
            _uiState.update {
                it.copy(
                    pendingImport = null,
                    selectedMeditation = null,
                    showEditSheet = false,
                    editorWaveform = null
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
                showEditSheet = false,
                editorWaveform = null
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
            // Drop the cached waveform so a re-import of the same file regenerates it.
            waveformProvider.removeCached(meditation.id)
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
                pendingImport = null,
                editorWaveform = null
            )
        }
        loadEditorWaveform(meditation)
    }

    /**
     * Loads the cached waveform for the meditation under edit so the playback-range card can
     * draw real mini bars (shared-107). A cache hit is instant; a miss generates in the
     * background. Any decoding failure leaves [GuidedMeditationsListUiState.editorWaveform]
     * null, so the card falls back to its flat line and the sheet never blocks or crashes.
     */
    private fun loadEditorWaveform(meditation: GuidedMeditation) {
        viewModelScope.launch {
            try {
                val waveform = waveformProvider.waveform(meditation)
                // Ignore the result if the user already closed or switched the sheet.
                _uiState.update {
                    if (it.selectedMeditation?.id == meditation.id) it.copy(editorWaveform = waveform) else it
                }
            } catch (e: WaveformGenerationException) {
                logger.e(TAG, "Failed to load waveform for edit sheet", e)
            }
        }
    }

    /**
     * Hides the edit sheet (Edit mode — does not affect [pendingImport]).
     */
    fun hideEditSheet() {
        _uiState.update {
            it.copy(
                selectedMeditation = null,
                showEditSheet = false,
                editorWaveform = null
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

    /**
     * Bestaetigung via Return-Taste — fuegt den Begriff der Historie hinzu, wenn Treffer existieren.
     *
     * Massgeblich ist die **sichtbare** Liste: raeumt der Dauer-Filter alle Treffer weg,
     * sieht der User „Nichts gefunden" und soll den Begriff nicht in der Historie wiederfinden.
     */
    fun submitSearch() {
        val state = _uiState.value
        if (state.visibleMeditations.isEmpty()) {
            return
        }
        commitCurrentQueryToHistory(state.searchQuery)
    }

    fun recordSearchCommittedByOpening() {
        val state = _uiState.value
        if (state.visibleMeditations.isNotEmpty()) {
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

    // MARK: - Dauer-Filter (shared-081)

    /**
     * Waehlt eine Stufe. Erneutes Tippen auf die aktive Stufe kehrt zu [DurationFilter.ALL]
     * zurueck. Blasse (unbelegte) Stufen reagieren nicht.
     */
    fun selectDurationFilter(step: DurationFilter) {
        _uiState.update { state ->
            if (step !in state.availableDurationSteps) {
                return@update state
            }
            state.copy(durationFilter = if (state.durationFilter == step) DurationFilter.ALL else step)
        }
    }

    /** Entfernt den Dauer-Filter, laesst den Suchtext unberuehrt. */
    fun resetDurationFilter() {
        _uiState.update { it.copy(durationFilter = DurationFilter.ALL) }
    }

    /** Raeumt Suchtext und Filter gemeinsam ab — ein Tap im „Kein Treffer"-Zustand. */
    fun resetSearchAndFilter() {
        _uiState.update {
            it.copy(searchQuery = "", isSearchFocused = false, durationFilter = DurationFilter.ALL)
        }
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

        private const val TAG = "GuidedMeditationsList"
    }
}
