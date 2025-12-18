package com.stillmoment.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.models.GuidedMeditation
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

// Extension property for DataStore - uses different name than settings
private val Context.meditationsDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "guided_meditations"
)

/**
 * DataStore for persisting guided meditation library.
 *
 * Stores a list of GuidedMeditation objects as JSON in Preferences DataStore.
 * This approach is suitable for the expected data size (dozens of meditations).
 */
@Singleton
class GuidedMeditationDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    private object Keys {
        val MEDITATIONS = stringPreferencesKey("meditations")
    }

    /**
     * Flow of all stored meditations.
     * Emits an empty list if no meditations are stored.
     */
    val meditationsFlow: Flow<List<GuidedMeditation>> = context.meditationsDataStore.data
        .map { preferences ->
            val jsonString = preferences[Keys.MEDITATIONS] ?: "[]"
            try {
                json.decodeFromString<List<GuidedMeditation>>(jsonString)
            } catch (e: Exception) {
                emptyList()
            }
        }

    /**
     * Adds a new meditation to the stored list.
     *
     * @param meditation The meditation to add
     */
    suspend fun addMeditation(meditation: GuidedMeditation) {
        context.meditationsDataStore.edit { preferences ->
            val current = getMeditations(preferences)
            val updated = current + meditation
            preferences[Keys.MEDITATIONS] = json.encodeToString(updated)
        }
    }

    /**
     * Removes a meditation from the stored list by ID.
     *
     * @param id The ID of the meditation to remove
     */
    suspend fun deleteMeditation(id: String) {
        context.meditationsDataStore.edit { preferences ->
            val current = getMeditations(preferences)
            val updated = current.filter { it.id != id }
            preferences[Keys.MEDITATIONS] = json.encodeToString(updated)
        }
    }

    /**
     * Updates an existing meditation in the stored list.
     *
     * @param meditation The updated meditation (matched by ID)
     */
    suspend fun updateMeditation(meditation: GuidedMeditation) {
        context.meditationsDataStore.edit { preferences ->
            val current = getMeditations(preferences)
            val updated = current.map {
                if (it.id == meditation.id) meditation else it
            }
            preferences[Keys.MEDITATIONS] = json.encodeToString(updated)
        }
    }

    /**
     * Retrieves a single meditation by ID.
     *
     * @param id The ID of the meditation
     * @return The meditation if found, null otherwise
     */
    suspend fun getMeditation(id: String): GuidedMeditation? {
        return meditationsFlow.first().find { it.id == id }
    }

    /**
     * Clears all stored meditations.
     * Useful for testing or data reset.
     */
    suspend fun clearAll() {
        context.meditationsDataStore.edit { preferences ->
            preferences.clear()
        }
    }

    private fun getMeditations(preferences: Preferences): List<GuidedMeditation> {
        val jsonString = preferences[Keys.MEDITATIONS] ?: "[]"
        return try {
            json.decodeFromString<List<GuidedMeditation>>(jsonString)
        } catch (e: Exception) {
            emptyList()
        }
    }
}
