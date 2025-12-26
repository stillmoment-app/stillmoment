package com.stillmoment.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.repositories.SettingsRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

// Extension property for DataStore
private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "settings"
)

/**
 * DataStore-based implementation of SettingsRepository.
 * Persists meditation settings using Jetpack DataStore.
 */
@Singleton
class SettingsDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context
) : SettingsRepository {
    private object Keys {
        val INTERVAL_GONGS_ENABLED = booleanPreferencesKey("interval_gongs_enabled")
        val INTERVAL_MINUTES = intPreferencesKey("interval_minutes")
        val BACKGROUND_SOUND_ID = stringPreferencesKey("background_sound_id")
        val DURATION_MINUTES = intPreferencesKey("duration_minutes")
        val SELECTED_TAB = stringPreferencesKey("selected_tab")
    }

    companion object {
        const val TAB_TIMER = "timer"
        const val TAB_LIBRARY = "library"
    }

    override val settingsFlow: Flow<MeditationSettings> =
        context.dataStore.data
            .map { preferences ->
                MeditationSettings.create(
                    intervalGongsEnabled =
                    preferences[Keys.INTERVAL_GONGS_ENABLED]
                        ?: MeditationSettings.Default.intervalGongsEnabled,
                    intervalMinutes =
                    preferences[Keys.INTERVAL_MINUTES]
                        ?: MeditationSettings.Default.intervalMinutes,
                    backgroundSoundId =
                    preferences[Keys.BACKGROUND_SOUND_ID]
                        ?: MeditationSettings.Default.backgroundSoundId,
                    durationMinutes =
                    preferences[Keys.DURATION_MINUTES]
                        ?: MeditationSettings.Default.durationMinutes
                )
            }

    override suspend fun getSettings(): MeditationSettings {
        return settingsFlow.first()
    }

    override suspend fun updateSettings(settings: MeditationSettings) {
        context.dataStore.edit { preferences ->
            preferences[Keys.INTERVAL_GONGS_ENABLED] = settings.intervalGongsEnabled
            preferences[Keys.INTERVAL_MINUTES] = settings.intervalMinutes
            preferences[Keys.BACKGROUND_SOUND_ID] = settings.backgroundSoundId
            preferences[Keys.DURATION_MINUTES] = settings.durationMinutes
        }
    }

    /**
     * Update a single setting - intervalGongsEnabled.
     */
    suspend fun setIntervalGongsEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.INTERVAL_GONGS_ENABLED] = enabled
        }
    }

    /**
     * Update a single setting - intervalMinutes.
     */
    suspend fun setIntervalMinutes(minutes: Int) {
        context.dataStore.edit { preferences ->
            preferences[Keys.INTERVAL_MINUTES] = MeditationSettings.validateInterval(minutes)
        }
    }

    /**
     * Update a single setting - backgroundSoundId.
     */
    suspend fun setBackgroundSoundId(soundId: String) {
        context.dataStore.edit { preferences ->
            preferences[Keys.BACKGROUND_SOUND_ID] = soundId
        }
    }

    /**
     * Update a single setting - durationMinutes.
     */
    suspend fun setDurationMinutes(minutes: Int) {
        context.dataStore.edit { preferences ->
            preferences[Keys.DURATION_MINUTES] = MeditationSettings.validateDuration(minutes)
        }
    }

    /**
     * Clear all settings and reset to defaults.
     */
    suspend fun clearSettings() {
        context.dataStore.edit { preferences ->
            preferences.clear()
        }
    }

    /**
     * Flow for the selected tab route.
     * Emits the saved tab or timer as default.
     */
    val selectedTabFlow: Flow<String> =
        context.dataStore.data
            .map { preferences ->
                preferences[Keys.SELECTED_TAB] ?: TAB_TIMER
            }

    /**
     * Get the selected tab synchronously (blocking).
     * Use only during app initialization.
     */
    suspend fun getSelectedTab(): String {
        return selectedTabFlow.first()
    }

    /**
     * Save the selected tab.
     */
    suspend fun setSelectedTab(tab: String) {
        context.dataStore.edit { preferences ->
            preferences[Keys.SELECTED_TAB] = tab
        }
    }
}
