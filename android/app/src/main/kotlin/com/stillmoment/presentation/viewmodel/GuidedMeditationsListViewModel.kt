package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.domain.models.groupByTeacher
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.repositories.MeditationSourceRepository
import com.stillmoment.domain.services.AudioServiceProtocol
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
    /** Whether the Content Guide sheet is shown */
    val showGuideSheet: Boolean = false,
    /** Curated sources for the current locale (Content Guide) */
    val guideSources: ImmutableList<MeditationSource> = persistentListOf(),
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
}

/**
 * ViewModel for the Guided Meditations Library screen.
 *
 * Manages the list of guided meditations, import functionality,
 * and edit/delete operations.
 */
@HiltViewModel
class GuidedMeditationsListViewModel
@Inject
constructor(
    private val repository: GuidedMeditationRepository,
    private val audioService: AudioServiceProtocol,
    private val meditationSourceRepository: MeditationSourceRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(GuidedMeditationsListUiState())
    val uiState: StateFlow<GuidedMeditationsListUiState> = _uiState.asStateFlow()

    init {
        observeMeditations()
    }

    /**
     * Observes meditation list changes and updates UI state.
     */
    private fun observeMeditations() {
        viewModelScope.launch {
            repository.meditationsFlow
                .map { meditations -> meditations.groupByTeacher().toImmutableList() }
                .collect { groups ->
                    _uiState.update {
                        it.copy(
                            groups = groups,
                            isLoading = false
                        )
                    }
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
}
