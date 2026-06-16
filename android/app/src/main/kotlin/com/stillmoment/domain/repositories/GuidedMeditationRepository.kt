package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.AudioMetadata
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.GuidedMeditation
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for managing guided meditation files.
 *
 * Persists library entries to local storage, copies imported audio into the
 * app container on save, and exposes a flow of the current library.
 *
 * Persistence happens explicitly via [addMeditation] — the caller (typically
 * the ViewModel after the user confirms the import edit sheet) decides when a
 * pending import becomes a library entry. Metadata extraction is delegated to
 * a separate service via [extractMetadata].
 */
interface GuidedMeditationRepository {
    /**
     * Flow of all guided meditations in the library.
     * Emits updates whenever the meditation list changes.
     */
    val meditationsFlow: Flow<List<GuidedMeditation>>

    /**
     * Reads metadata (duration, artist, title) for the given URI.
     *
     * Used by the import flow to drive the prefill cascade before the user
     * confirms the save.
     *
     * @param uri URI string of the source audio file
     */
    suspend fun extractMetadata(uri: String): AudioMetadata

    /**
     * Resolves the file name behind a content URI (`DISPLAY_NAME` for SAF URIs,
     * last path segment for file URIs).
     */
    suspend fun getFileName(uri: String): String

    /**
     * Adds a meditation to the library.
     *
     * Copies the source file into app-internal storage and persists the entry
     * with the caller-provided teacher and name (already prefilled or edited).
     *
     * The gong settings (shared-106) are persisted together with the entry in the
     * same operation, so an import can never leave a gong-less entry behind.
     *
     * @param sourceUri URI string of the source audio file (will be copied)
     * @param fileName Original file name to preserve for display
     * @param metadata Previously extracted metadata for the file (duration etc.)
     * @param teacher Teacher name to persist
     * @param name Meditation title to persist
     * @param startGongEnabled Whether a start gong rings when playback begins
     * @param endGongEnabled Whether an end gong rings when playback finishes
     * @param gongSoundId Identifier of the gong sound used for both gongs
     */
    suspend fun addMeditation(
        sourceUri: String,
        fileName: String,
        metadata: AudioMetadata,
        teacher: String,
        name: String,
        startGongEnabled: Boolean = false,
        endGongEnabled: Boolean = false,
        gongSoundId: String = GongSound.DEFAULT_SOUND_ID
    ): Result<GuidedMeditation>

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
