package com.stillmoment.domain.repositories

import android.net.Uri
import com.stillmoment.domain.models.GuidedMeditation
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for managing guided meditation files.
 *
 * This interface defines the contract for importing, storing, and managing
 * guided meditation audio files. Implementation handles SAF (Storage Access
 * Framework) for file access and DataStore for persistence.
 */
interface GuidedMeditationRepository {
    /**
     * Flow of all guided meditations in the library.
     * Emits updates whenever the meditation list changes.
     */
    val meditationsFlow: Flow<List<GuidedMeditation>>

    /**
     * Imports a meditation from an audio file.
     *
     * Takes a Content URI from the file picker, extracts metadata (duration,
     * artist, title from ID3 tags), and persists the meditation.
     *
     * @param uri Content URI from Storage Access Framework
     * @return Result containing the imported GuidedMeditation or an error
     */
    suspend fun importMeditation(uri: Uri): Result<GuidedMeditation>

    /**
     * Deletes a meditation from the library.
     *
     * Removes the meditation from persistence. The underlying file is not deleted
     * as it remains in the user's file system.
     *
     * @param id Unique identifier of the meditation to delete
     */
    suspend fun deleteMeditation(id: String)

    /**
     * Updates a meditation's metadata.
     *
     * Used for updating custom teacher/name fields set by the user.
     *
     * @param meditation Updated meditation object
     */
    suspend fun updateMeditation(meditation: GuidedMeditation)

    /**
     * Retrieves a single meditation by ID.
     *
     * @param id Unique identifier of the meditation
     * @return The meditation if found, null otherwise
     */
    suspend fun getMeditation(id: String): GuidedMeditation?
}
