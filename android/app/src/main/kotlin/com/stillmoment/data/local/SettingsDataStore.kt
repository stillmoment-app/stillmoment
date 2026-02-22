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
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.Introduction
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
@Suppress("TooManyFunctions") // 14 preference keys each need typed getter/setter/flow — collapsing into a generic
// set(key, value) would lose compile-time type safety and validation (e.g. validateVolume, validateInterval).
@Singleton
class SettingsDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context
) : SettingsRepository {
    private object Keys {
        val INTERVAL_GONGS_ENABLED = booleanPreferencesKey("interval_gongs_enabled")
        val INTERVAL_MINUTES = intPreferencesKey("interval_minutes")
        val INTERVAL_MODE = stringPreferencesKey("interval_mode")
        val INTERVAL_SOUND_ID = stringPreferencesKey("interval_sound_id")
        val INTERVAL_GONG_VOLUME = floatPreferencesKey("interval_gong_volume")
        val BACKGROUND_SOUND_ID = stringPreferencesKey("background_sound_id")
        val BACKGROUND_SOUND_VOLUME = floatPreferencesKey("background_sound_volume")
        val DURATION_MINUTES = intPreferencesKey("duration_minutes")
        val PREPARATION_TIME_ENABLED = booleanPreferencesKey("preparation_time_enabled")
        val PREPARATION_TIME_SECONDS = intPreferencesKey("preparation_time_seconds")
        val GONG_SOUND_ID = stringPreferencesKey("gong_sound_id")
        val GONG_VOLUME = floatPreferencesKey("gong_volume")
        val SELECTED_TAB = stringPreferencesKey("selected_tab")
        val SELECTED_THEME = stringPreferencesKey("selected_theme")
        val APPEARANCE_MODE = stringPreferencesKey("appearance_mode")
        val INTRODUCTION_ID = stringPreferencesKey("introduction_id")
        val HAS_SEEN_SETTINGS_HINT = booleanPreferencesKey("has_seen_settings_hint")

        // Legacy keys kept for migration
        val LEGACY_INTERVAL_REPEATING = booleanPreferencesKey("interval_repeating")
        val LEGACY_INTERVAL_FROM_END = booleanPreferencesKey("interval_from_end")
    }

    /**
     * Migrates legacy boolean pair (interval_repeating + interval_from_end) to IntervalMode string.
     * Returns the IntervalMode for the current preferences, handling migration transparently.
     */
    private fun migrateIntervalMode(preferences: Preferences): IntervalMode {
        // If new key exists, use it directly
        preferences[Keys.INTERVAL_MODE]?.let { return IntervalMode.fromString(it) }

        // Migrate from legacy boolean keys
        val repeating = preferences[Keys.LEGACY_INTERVAL_REPEATING]
        val fromEnd = preferences[Keys.LEGACY_INTERVAL_FROM_END]

        // No legacy keys either → use default
        if (repeating == null && fromEnd == null) return MeditationSettings.DEFAULT_INTERVAL_MODE

        // Migration logic:
        // repeating=true → REPEATING (fromEnd is ignored, "repeating from end" mode removed)
        // repeating=false → BEFORE_END
        return if (repeating != false) IntervalMode.REPEATING else IntervalMode.BEFORE_END
    }

    override val settingsFlow: Flow<MeditationSettings> =
        context.dataStore.data
            .map { preferences ->
                // If saved introductionId is not available for current language, fall back to null
                val savedIntroId = preferences[Keys.INTRODUCTION_ID]
                val introductionId = if (savedIntroId != null &&
                    Introduction.isAvailableForCurrentLanguage(savedIntroId)
                ) {
                    savedIntroId
                } else {
                    null
                }

                MeditationSettings.create(
                    intervalGongsEnabled =
                    preferences[Keys.INTERVAL_GONGS_ENABLED]
                        ?: MeditationSettings.Default.intervalGongsEnabled,
                    intervalMinutes =
                    preferences[Keys.INTERVAL_MINUTES]
                        ?: MeditationSettings.Default.intervalMinutes,
                    intervalMode = migrateIntervalMode(preferences),
                    intervalSoundId =
                    preferences[Keys.INTERVAL_SOUND_ID]
                        ?: MeditationSettings.Default.intervalSoundId,
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
                        ?: MeditationSettings.Default.gongVolume,
                    introductionId = introductionId
                )
            }

    override suspend fun getSettings(): MeditationSettings {
        return settingsFlow.first()
    }

    override suspend fun updateSettings(settings: MeditationSettings) {
        context.dataStore.edit { preferences ->
            preferences[Keys.INTERVAL_GONGS_ENABLED] = settings.intervalGongsEnabled
            preferences[Keys.INTERVAL_MINUTES] = settings.intervalMinutes
            preferences[Keys.INTERVAL_MODE] = settings.intervalMode.name
            preferences[Keys.INTERVAL_SOUND_ID] = settings.intervalSoundId
            preferences[Keys.INTERVAL_GONG_VOLUME] = settings.intervalGongVolume
            preferences[Keys.BACKGROUND_SOUND_ID] = settings.backgroundSoundId
            preferences[Keys.BACKGROUND_SOUND_VOLUME] = settings.backgroundSoundVolume
            preferences[Keys.DURATION_MINUTES] = settings.durationMinutes
            preferences[Keys.PREPARATION_TIME_ENABLED] = settings.preparationTimeEnabled
            preferences[Keys.PREPARATION_TIME_SECONDS] = settings.preparationTimeSeconds
            preferences[Keys.GONG_SOUND_ID] = settings.gongSoundId
            preferences[Keys.GONG_VOLUME] = settings.gongVolume
            if (settings.introductionId != null) {
                preferences[Keys.INTRODUCTION_ID] = settings.introductionId
            } else {
                preferences.remove(Keys.INTRODUCTION_ID)
            }
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
     * Flow for the selected color theme.
     * Emits the saved theme or ColorTheme.DEFAULT for new installations.
     */
    val selectedThemeFlow: Flow<ColorTheme> =
        context.dataStore.data
            .map { preferences ->
                ColorTheme.fromString(preferences[Keys.SELECTED_THEME])
            }

    /**
     * Get the selected color theme.
     */
    suspend fun getSelectedTheme(): ColorTheme {
        return selectedThemeFlow.first()
    }

    /**
     * Save the selected color theme.
     */
    suspend fun setSelectedTheme(theme: ColorTheme) {
        context.dataStore.edit { preferences ->
            preferences[Keys.SELECTED_THEME] = theme.name
        }
    }

    /**
     * Flow for the selected appearance mode.
     * Emits the saved mode or AppearanceMode.DEFAULT (SYSTEM) for new installations.
     */
    val appearanceModeFlow: Flow<AppearanceMode> =
        context.dataStore.data
            .map { preferences ->
                AppearanceMode.fromString(preferences[Keys.APPEARANCE_MODE])
            }

    /**
     * Get the selected appearance mode.
     */
    suspend fun getAppearanceMode(): AppearanceMode {
        return appearanceModeFlow.first()
    }

    /**
     * Save the selected appearance mode.
     */
    suspend fun setAppearanceMode(mode: AppearanceMode) {
        context.dataStore.edit { preferences ->
            preferences[Keys.APPEARANCE_MODE] = mode.name
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
    override suspend fun getHasSeenSettingsHint(): Boolean {
        return hasSeenSettingsHintFlow.first()
    }

    /**
     * Mark the settings hint as seen.
     */
    override suspend fun setHasSeenSettingsHint(seen: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.HAS_SEEN_SETTINGS_HINT] = seen
        }
    }
}
