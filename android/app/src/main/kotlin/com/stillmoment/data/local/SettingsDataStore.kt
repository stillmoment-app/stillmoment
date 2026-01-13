package com.stillmoment.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.models.AppTab
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
@Suppress("TooManyFunctions") // DataStore requires individual setters for each preference
@Singleton
class SettingsDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context
) : SettingsRepository {
    private object Keys {
        val INTERVAL_GONGS_ENABLED = booleanPreferencesKey("interval_gongs_enabled")
        val INTERVAL_MINUTES = intPreferencesKey("interval_minutes")
        val INTERVAL_GONG_VOLUME = floatPreferencesKey("interval_gong_volume")
        val BACKGROUND_SOUND_ID = stringPreferencesKey("background_sound_id")
        val BACKGROUND_SOUND_VOLUME = floatPreferencesKey("background_sound_volume")
        val DURATION_MINUTES = intPreferencesKey("duration_minutes")
        val PREPARATION_TIME_ENABLED = booleanPreferencesKey("preparation_time_enabled")
        val PREPARATION_TIME_SECONDS = intPreferencesKey("preparation_time_seconds")
        val GONG_SOUND_ID = stringPreferencesKey("gong_sound_id")
        val GONG_VOLUME = floatPreferencesKey("gong_volume")
        val SELECTED_TAB = stringPreferencesKey("selected_tab")
        val HAS_SEEN_SETTINGS_HINT = booleanPreferencesKey("has_seen_settings_hint")
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
                    intervalGongVolume =
                    preferences[Keys.INTERVAL_GONG_VOLUME]
                        ?: MeditationSettings.Default.intervalGongVolume,
                    backgroundSoundId =
                    preferences[Keys.BACKGROUND_SOUND_ID]
                        ?: MeditationSettings.Default.backgroundSoundId,
                    backgroundSoundVolume =
                    preferences[Keys.BACKGROUND_SOUND_VOLUME]
                        ?: MeditationSettings.Default.backgroundSoundVolume,
                    durationMinutes =
                    preferences[Keys.DURATION_MINUTES]
                        ?: MeditationSettings.Default.durationMinutes,
                    preparationTimeEnabled =
                    preferences[Keys.PREPARATION_TIME_ENABLED]
                        ?: MeditationSettings.Default.preparationTimeEnabled,
                    preparationTimeSeconds =
                    preferences[Keys.PREPARATION_TIME_SECONDS]
                        ?: MeditationSettings.Default.preparationTimeSeconds,
                    gongSoundId =
                    preferences[Keys.GONG_SOUND_ID]
                        ?: MeditationSettings.Default.gongSoundId,
                    gongVolume =
                    preferences[Keys.GONG_VOLUME]
                        ?: MeditationSettings.Default.gongVolume
                )
            }

    override suspend fun getSettings(): MeditationSettings {
        return settingsFlow.first()
    }

    override suspend fun updateSettings(settings: MeditationSettings) {
        context.dataStore.edit { preferences ->
            preferences[Keys.INTERVAL_GONGS_ENABLED] = settings.intervalGongsEnabled
            preferences[Keys.INTERVAL_MINUTES] = settings.intervalMinutes
            preferences[Keys.INTERVAL_GONG_VOLUME] = settings.intervalGongVolume
            preferences[Keys.BACKGROUND_SOUND_ID] = settings.backgroundSoundId
            preferences[Keys.BACKGROUND_SOUND_VOLUME] = settings.backgroundSoundVolume
            preferences[Keys.DURATION_MINUTES] = settings.durationMinutes
            preferences[Keys.PREPARATION_TIME_ENABLED] = settings.preparationTimeEnabled
            preferences[Keys.PREPARATION_TIME_SECONDS] = settings.preparationTimeSeconds
            preferences[Keys.GONG_SOUND_ID] = settings.gongSoundId
            preferences[Keys.GONG_VOLUME] = settings.gongVolume
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
     * Update a single setting - intervalGongVolume.
     */
    suspend fun setIntervalGongVolume(volume: Float) {
        context.dataStore.edit { preferences ->
            preferences[Keys.INTERVAL_GONG_VOLUME] = MeditationSettings.validateVolume(volume)
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
     * Update a single setting - backgroundSoundVolume.
     */
    suspend fun setBackgroundSoundVolume(volume: Float) {
        context.dataStore.edit { preferences ->
            preferences[Keys.BACKGROUND_SOUND_VOLUME] = MeditationSettings.validateVolume(volume)
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
     * Update a single setting - gongSoundId.
     */
    suspend fun setGongSoundId(soundId: String) {
        context.dataStore.edit { preferences ->
            preferences[Keys.GONG_SOUND_ID] = soundId
        }
    }

    /**
     * Update a single setting - gongVolume.
     */
    suspend fun setGongVolume(volume: Float) {
        context.dataStore.edit { preferences ->
            preferences[Keys.GONG_VOLUME] = MeditationSettings.validateVolume(volume)
        }
    }

    /**
     * Update a single setting - preparationTimeEnabled.
     */
    suspend fun setPreparationTimeEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.PREPARATION_TIME_ENABLED] = enabled
        }
    }

    /**
     * Update a single setting - preparationTimeSeconds.
     */
    suspend fun setPreparationTimeSeconds(seconds: Int) {
        context.dataStore.edit { preferences ->
            preferences[Keys.PREPARATION_TIME_SECONDS] = MeditationSettings.validatePreparationTime(seconds)
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
     * Flow for the selected tab.
     * Emits the saved tab or AppTab.DEFAULT for new installations.
     */
    val selectedTabFlow: Flow<AppTab> =
        context.dataStore.data
            .map { preferences ->
                AppTab.fromRoute(preferences[Keys.SELECTED_TAB])
            }

    /**
     * Get the selected tab.
     * Use only during app initialization.
     */
    suspend fun getSelectedTab(): AppTab {
        return selectedTabFlow.first()
    }

    /**
     * Save the selected tab.
     */
    suspend fun setSelectedTab(tab: AppTab) {
        context.dataStore.edit { preferences ->
            preferences[Keys.SELECTED_TAB] = tab.route
        }
    }

    /**
     * Flow for whether the user has seen the settings hint.
     * Returns false for new installations.
     */
    val hasSeenSettingsHintFlow: Flow<Boolean> =
        context.dataStore.data
            .map { preferences ->
                preferences[Keys.HAS_SEEN_SETTINGS_HINT] ?: false
            }

    /**
     * Get whether the user has seen the settings hint.
     */
    suspend fun getHasSeenSettingsHint(): Boolean {
        return hasSeenSettingsHintFlow.first()
    }

    /**
     * Mark the settings hint as seen.
     */
    suspend fun setHasSeenSettingsHint(seen: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.HAS_SEEN_SETTINGS_HINT] = seen
        }
    }
}
