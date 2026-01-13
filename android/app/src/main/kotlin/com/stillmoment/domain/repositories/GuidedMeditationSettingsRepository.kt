package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.GuidedMeditationSettings
import kotlinx.coroutines.flow.Flow

/**
 * Repository protocol for persisting guided meditation settings.
 *
 * Implementations handle the storage mechanism (DataStore, etc.)
 * while keeping the domain model free of infrastructure dependencies.
 */
interface GuidedMeditationSettingsRepository {
    /**
     * Flow of current settings, emitting updates on changes.
     */
    val settingsFlow: Flow<GuidedMeditationSettings>

    /**
     * Gets the current settings (suspending one-shot).
     */
    suspend fun getSettings(): GuidedMeditationSettings

    /**
     * Saves settings to persistent storage.
     */
    suspend fun updateSettings(settings: GuidedMeditationSettings)
}
