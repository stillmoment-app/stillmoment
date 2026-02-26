package com.stillmoment.domain.repositories

import android.net.Uri
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for managing custom audio files.
 *
 * Implementations copy imported files to local app storage, persist metadata,
 * and provide lookup by ID or type. Supports both soundscapes (background loops)
 * and attunements (one-shot introduction audio).
 */
interface CustomAudioRepository {
    /**
     * Flow of all custom audio files for the given type, sorted by dateAdded descending.
     * Emits updates whenever the list changes.
     */
    fun filesFlow(type: CustomAudioType): Flow<List<CustomAudioFile>>

    /**
     * Returns all stored custom audio files of the given type, sorted by dateAdded descending.
     */
    suspend fun loadAll(type: CustomAudioType): List<CustomAudioFile>

    /**
     * Imports an audio file from the given URI.
     *
     * Copies the file to local storage, detects duration, creates metadata record.
     * Supported formats: mp3, m4a, wav.
     *
     * @param uri Content URI from Storage Access Framework
     * @param type Whether this is a soundscape or attunement
     * @return Result with the imported CustomAudioFile or a CustomAudioError
     */
    suspend fun importFile(uri: Uri, type: CustomAudioType): Result<CustomAudioFile>

    /**
     * Deletes the custom audio file with the given ID.
     *
     * Removes the file from local storage and deletes the metadata record.
     *
     * @param id The ID of the audio file to delete
     */
    suspend fun delete(id: String)

    /**
     * Returns the local file path for the given custom audio file ID, or null if not found.
     */
    suspend fun getFilePath(id: String): String?

    /**
     * Finds a custom audio file by ID across all types, or null if not found.
     */
    suspend fun findFile(id: String): CustomAudioFile?
}
