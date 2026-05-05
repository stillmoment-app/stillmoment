package com.stillmoment.data.local

import android.content.Context
import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.SerializationException
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

// Extension property for the "custom_audio" DataStore. Shared with
// [com.stillmoment.data.migration.AttunementCleanupMigration]; see the
// `appSettingsDataStore` doc comment for the multi-instance crash this prevents.
internal val Context.customAudioDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "custom_audio"
)

/**
 * DataStore for persisting custom audio file metadata.
 *
 * Stores a single JSON list of all CustomAudioFile objects. Filtering by type happens
 * at query time, which keeps the data model flat and leaves room for future custom-audio
 * kinds without a schema change.
 */
@Singleton
class CustomAudioDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context
) {
    private val json =
        Json {
            ignoreUnknownKeys = true
            encodeDefaults = true
        }

    private object Keys {
        val FILES = stringPreferencesKey("custom_audio_files")
    }

    /**
     * Flow of custom audio files filtered by type, sorted by dateAdded descending.
     * Emits updates whenever the stored list changes.
     */
    fun filesFlow(type: CustomAudioType): Flow<List<CustomAudioFile>> =
        context.customAudioDataStore.data.map { preferences ->
            getAllFiles(preferences)
                .filter { it.type == type }
                .sortedByDescending { it.dateAdded }
        }

    /**
     * Returns all stored custom audio files of the given type, sorted by dateAdded descending.
     */
    suspend fun loadAll(type: CustomAudioType): List<CustomAudioFile> = filesFlow(type).first()

    /**
     * Adds a new custom audio file to the stored list.
     *
     * @param file The custom audio file to add
     */
    suspend fun addFile(file: CustomAudioFile) {
        context.customAudioDataStore.edit { preferences ->
            val current = getAllFiles(preferences)
            val updated = current + file
            preferences[Keys.FILES] = json.encodeToString(updated)
        }
    }

    /**
     * Removes a custom audio file from the stored list by ID.
     *
     * @param id The ID of the file to remove
     */
    suspend fun deleteFile(id: String) {
        context.customAudioDataStore.edit { preferences ->
            val current = getAllFiles(preferences)
            val updated = current.filter { it.id != id }
            preferences[Keys.FILES] = json.encodeToString(updated)
        }
    }

    /**
     * Finds a custom audio file by ID across all types.
     *
     * @param id The ID of the file
     * @return The file if found, null otherwise
     */
    suspend fun findFile(id: String): CustomAudioFile? = context.customAudioDataStore.data.first().let { preferences ->
        getAllFiles(preferences).find { it.id == id }
    }

    /**
     * Renames a custom audio file by updating its display name.
     *
     * @param id The ID of the file to rename
     * @param newName The new display name
     */
    suspend fun renameFile(id: String, newName: String) {
        context.customAudioDataStore.edit { preferences ->
            val current = getAllFiles(preferences)
            val updated = current.map { file ->
                if (file.id == id) file.copy(name = newName) else file
            }
            preferences[Keys.FILES] = json.encodeToString(updated)
        }
    }

    private fun getAllFiles(preferences: Preferences): List<CustomAudioFile> {
        val jsonString = preferences[Keys.FILES] ?: "[]"
        return try {
            json.decodeFromString<List<CustomAudioFile>>(jsonString)
        } catch (e: SerializationException) {
            Log.w(TAG, "Failed to parse custom audio JSON, returning empty list", e)
            emptyList()
        }
    }

    companion object {
        private const val TAG = "CustomAudioDataStore"
    }
}
