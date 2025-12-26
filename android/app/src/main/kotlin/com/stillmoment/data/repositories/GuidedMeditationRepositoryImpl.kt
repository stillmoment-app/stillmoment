package com.stillmoment.data.repositories

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext

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
class GuidedMeditationRepositoryImpl
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val dataStore: GuidedMeditationDataStore
) : GuidedMeditationRepository {
    override val meditationsFlow: Flow<List<GuidedMeditation>> = dataStore.meditationsFlow

    override suspend fun importMeditation(uri: Uri): Result<GuidedMeditation> {
        return withContext(Dispatchers.IO) {
            try {
                // 1. Get file name from URI
                val originalFileName = getFileName(uri)
                Log.d(TAG, "Importing meditation: $originalFileName from $uri")

                // 2. Extract metadata from audio file (while we still have access)
                val metadata = extractMetadata(uri)

                // 3. Copy file to app-internal storage (ensures persistent access)
                val localFile = copyFileToInternalStorage(uri, originalFileName)
                val localUri = Uri.fromFile(localFile)
                Log.d(TAG, "Copied to internal storage: ${localFile.absolutePath}")

                // 4. Create meditation object with local file URI
                val meditation =
                    GuidedMeditation(
                        fileUri = localUri.toString(),
                        fileName = originalFileName,
                        duration = metadata.duration,
                        teacher = metadata.artist ?: DEFAULT_TEACHER,
                        name = metadata.title ?: fileNameWithoutExtension(originalFileName)
                    )

                // 5. Persist to DataStore
                dataStore.addMeditation(meditation)

                Result.success(meditation)
            } catch (e: SecurityException) {
                Log.e(TAG, "Permission denied for file access", e)
                Result.failure(ImportException("Permission denied for file access", e))
            } catch (e: Exception) {
                Log.e(TAG, "Failed to import meditation", e)
                Result.failure(ImportException("Failed to import meditation: ${e.message}", e))
            }
        }
    }

    override suspend fun deleteMeditation(id: String) {
        // Delete local file if it exists
        val meditation = dataStore.getMeditation(id)
        meditation?.let {
            try {
                val uri = Uri.parse(it.fileUri)
                if (uri.scheme == "file") {
                    val file = File(uri.path ?: return@let)
                    if (file.exists()) {
                        file.delete()
                        Log.d(TAG, "Deleted local file: ${file.absolutePath}")
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not delete local file for meditation $id", e)
            }
        }
        dataStore.deleteMeditation(id)
    }

    override suspend fun updateMeditation(meditation: GuidedMeditation) {
        dataStore.updateMeditation(meditation)
    }

    override suspend fun getMeditation(id: String): GuidedMeditation? {
        return dataStore.getMeditation(id)
    }

    /**
     * Copies a file from a SAF content URI to app-internal storage.
     * This ensures the file remains accessible after app restart regardless of
     * whether the original URI supports persistable permissions.
     *
     * @param sourceUri The content URI from the file picker
     * @param originalFileName The original file name for extension detection
     * @return The local File in app storage
     */
    private fun copyFileToInternalStorage(sourceUri: Uri, originalFileName: String): File {
        // Create meditations directory if it doesn't exist
        val meditationsDir = File(context.filesDir, MEDITATIONS_DIR)
        if (!meditationsDir.exists()) {
            meditationsDir.mkdirs()
        }

        // Generate unique filename to avoid collisions
        val extension = originalFileName.substringAfterLast(".", "mp3")
        val uniqueFileName = "${UUID.randomUUID()}.$extension"
        val destFile = File(meditationsDir, uniqueFileName)

        // Copy the file
        context.contentResolver.openInputStream(sourceUri)?.use { input ->
            destFile.outputStream().use { output ->
                input.copyTo(output)
            }
        } ?: throw ImportException("Could not open source file")

        return destFile
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
                duration =
                retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_DURATION
                )?.toLongOrNull() ?: 0L,
                artist =
                retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_ARTIST
                )?.takeIf { it.isNotBlank() },
                title =
                retriever.extractMetadata(
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
        private const val TAG = "GuidedMeditationRepo"
        private const val DEFAULT_TEACHER = "Unknown"
        private const val MEDITATIONS_DIR = "meditations"
    }
}

/**
 * Exception thrown when meditation import fails.
 */
class ImportException(message: String, cause: Throwable? = null) : Exception(message, cause)
