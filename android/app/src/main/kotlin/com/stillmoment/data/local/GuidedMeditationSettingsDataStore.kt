package com.stillmoment.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

// Extension property for DataStore (separate from timer settings)
private val Context.guidedMeditationSettingsDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "guided_meditation_settings"
)

/**
 * DataStore-based implementation of GuidedMeditationSettingsRepository.
 * Persists guided meditation settings using Jetpack DataStore.
 */
@Singleton
class GuidedMeditationSettingsDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context
) : GuidedMeditationSettingsRepository {

    private object Keys {
        val PREPARATION_TIME_ENABLED = booleanPreferencesKey("preparation_time_enabled")
        val PREPARATION_TIME_SECONDS = intPreferencesKey("preparation_time_seconds")
    }

    override val settingsFlow: Flow<GuidedMeditationSettings> =
        context.guidedMeditationSettingsDataStore.data
            .map { preferences ->
                GuidedMeditationSettings(
                    preparationTimeEnabled = preferences[Keys.PREPARATION_TIME_ENABLED]
                        ?: GuidedMeditationSettings.DEFAULT_PREPARATION_TIME_ENABLED,
                    preparationTimeSeconds = GuidedMeditationSettings.validatePreparationTime(
                        preferences[Keys.PREPARATION_TIME_SECONDS]
                            ?: GuidedMeditationSettings.DEFAULT_PREPARATION_TIME_SECONDS
                    )
                )
            }

    override suspend fun getSettings(): GuidedMeditationSettings {
        return settingsFlow.first()
    }

    override suspend fun updateSettings(settings: GuidedMeditationSettings) {
        context.guidedMeditationSettingsDataStore.edit { preferences ->
            preferences[Keys.PREPARATION_TIME_ENABLED] = settings.preparationTimeEnabled
            preferences[Keys.PREPARATION_TIME_SECONDS] = settings.preparationTimeSeconds
        }
    }
}
