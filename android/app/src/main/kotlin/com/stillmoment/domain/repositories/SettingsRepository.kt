package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.MeditationSettings
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for managing meditation settings.
 *
 * This interface defines the contract for settings persistence,
 * following the Clean Architecture pattern.
 */
interface SettingsRepository {
    /**
     * Flow of the current meditation settings.
     * Emits updates whenever settings change.
     */
    val settingsFlow: Flow<MeditationSettings>

    /**
     * Updates the meditation settings.
     *
     * @param settings The new settings to persist
     */
    suspend fun updateSettings(settings: MeditationSettings)

    /**
     * Loads the current settings synchronously.
     * Use settingsFlow for reactive updates.
     *
     * @return The current MeditationSettings
     */
    suspend fun getSettings(): MeditationSettings
}
