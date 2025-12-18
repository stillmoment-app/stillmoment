package com.stillmoment.data.repositories

import android.content.Context
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.OpenableColumns
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Holds extracted metadata from an audio file.
 */
private data class MediaMetadata(
    val duration: Long,
    val artist: String?,
    val title: String?
)

/**
 * Implementation of GuidedMeditationRepository.
 *
 * Handles importing audio files via Storage Access Framework (SAF),
 * extracting metadata from ID3 tags, and persisting to DataStore.
 */
@Singleton
class GuidedMeditationRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val dataStore: GuidedMeditationDataStore
) : GuidedMeditationRepository {

    override val meditationsFlow: Flow<List<GuidedMeditation>> = dataStore.meditationsFlow

    override suspend fun importMeditation(uri: Uri): Result<GuidedMeditation> {
        return try {
            // 1. Take persistable URI permission for app restart survival
            takePersistablePermission(uri)

            // 2. Get file name from URI
            val fileName = getFileName(uri)

            // 3. Extract metadata from audio file
            val metadata = extractMetadata(uri)

            // 4. Create meditation object
            val meditation = GuidedMeditation(
                fileUri = uri.toString(),
                fileName = fileName,
                duration = metadata.duration,
                teacher = metadata.artist ?: DEFAULT_TEACHER,
                name = metadata.title ?: fileNameWithoutExtension(fileName)
            )

            // 5. Persist to DataStore
            dataStore.addMeditation(meditation)

            Result.success(meditation)
        } catch (e: SecurityException) {
            Result.failure(ImportException("Permission denied for file access", e))
        } catch (e: Exception) {
            Result.failure(ImportException("Failed to import meditation: ${e.message}", e))
        }
    }

    override suspend fun deleteMeditation(id: String) {
        dataStore.deleteMeditation(id)
    }

    override suspend fun updateMeditation(meditation: GuidedMeditation) {
        dataStore.updateMeditation(meditation)
    }

    override suspend fun getMeditation(id: String): GuidedMeditation? {
        return dataStore.getMeditation(id)
    }

    /**
     * Takes persistable URI permission so the file remains accessible after app restart.
     * This is required by SAF for long-term file access.
     */
    private fun takePersistablePermission(uri: Uri) {
        try {
            context.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (e: SecurityException) {
            // Permission might already be granted or not available
            // Continue anyway as the file might still be accessible
        }
    }

    /**
     * Extracts the file name from a content URI using ContentResolver.
     */
    private fun getFileName(uri: Uri): String {
        var fileName = "Unknown"

        context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    fileName = cursor.getString(nameIndex) ?: "Unknown"
                }
            }
        }

        return fileName
    }

    /**
     * Extracts metadata from an audio file using MediaMetadataRetriever.
     * Reads duration, artist (ID3: ARTIST), and title (ID3: TITLE).
     */
    private fun extractMetadata(uri: Uri): MediaMetadata {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)

            MediaMetadata(
                duration = retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_DURATION
                )?.toLongOrNull() ?: 0L,
                artist = retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_ARTIST
                )?.takeIf { it.isNotBlank() },
                title = retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_TITLE
                )?.takeIf { it.isNotBlank() }
            )
        } catch (e: Exception) {
            // Return default metadata if extraction fails
            MediaMetadata(
                duration = 0L,
                artist = null,
                title = null
            )
        } finally {
            retriever.release()
        }
    }

    /**
     * Removes file extension from filename for use as default name.
     */
    private fun fileNameWithoutExtension(fileName: String): String {
        return fileName.substringBeforeLast(".")
    }

    companion object {
        private const val DEFAULT_TEACHER = "Unknown"
    }
}

/**
 * Exception thrown when meditation import fails.
 */
class ImportException(message: String, cause: Throwable? = null) : Exception(message, cause)
