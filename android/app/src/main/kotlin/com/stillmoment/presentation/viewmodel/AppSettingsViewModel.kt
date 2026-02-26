package com.stillmoment.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * ViewModel for the App Settings screen.
 * Manages guided meditation settings displayed in the global settings tab.
 */
@HiltViewModel
class AppSettingsViewModel
@Inject
constructor(
    private val guidedSettingsRepository: GuidedMeditationSettingsRepository
) : ViewModel() {

    data class UiState(
        val guidedSettings: GuidedMeditationSettings = GuidedMeditationSettings.Default
    )

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    init {
        observeGuidedSettings()
    }

    private fun observeGuidedSettings() {
        viewModelScope.launch {
            guidedSettingsRepository.settingsFlow.collect { settings ->
                _uiState.update { it.copy(guidedSettings = settings) }
            }
        }
    }

    fun updateGuidedSettings(settings: GuidedMeditationSettings) {
        viewModelScope.launch {
            guidedSettingsRepository.updateSettings(settings)
        }
    }
}
