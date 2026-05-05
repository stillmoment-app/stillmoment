package com.stillmoment.data.repositories

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import com.stillmoment.data.local.CustomAudioDataStore
import com.stillmoment.domain.models.CustomAudioError
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.repositories.CustomAudioRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.io.IOException
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext

/**
 * Implementation of CustomAudioRepository.
 *
 * Handles importing audio files via Storage Access Framework (SAF),
 * extracting duration metadata, and persisting to DataStore.
 * Files are copied to internal storage under type-specific subdirectories.
 */
@Singleton
class CustomAudioRepositoryImpl
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val dataStore: CustomAudioDataStore
) : CustomAudioRepository {

    override fun filesFlow(type: CustomAudioType): Flow<List<CustomAudioFile>> = dataStore.filesFlow(type)

    override suspend fun loadAll(type: CustomAudioType): List<CustomAudioFile> = dataStore.loadAll(type)

    override suspend fun importFile(uri: Uri, type: CustomAudioType): Result<CustomAudioFile> =
        withContext(Dispatchers.IO) {
            try {
                val originalFileName = getFileName(uri)
                val extension = originalFileName.substringAfterLast(".", "").lowercase()
                Log.d(TAG, "Importing custom audio: $originalFileName (type=$type)")

                if (extension !in SUPPORTED_EXTENSIONS) {
                    return@withContext Result.failure(
                        CustomAudioError.UnsupportedFormat(extension)
                    )
                }

                val durationMs = extractDuration(uri)
                val localFile = copyFileToInternalStorage(uri, originalFileName, type)
                val displayName = originalFileName.substringBeforeLast(".")

                val audioFile =
                    CustomAudioFile(
                        name = displayName,
                        filename = localFile.name,
                        durationMs = durationMs,
                        type = type
                    )

                dataStore.addFile(audioFile)
                Log.d(TAG, "Imported custom audio: ${audioFile.name} (${audioFile.type})")
                Result.success(audioFile)
            } catch (e: IOException) {
                Log.e(TAG, "Failed to import audio file", e)
                Result.failure(
                    CustomAudioError.FileCopyFailed("Failed to copy file: ${e.message}")
                )
            } catch (e: SecurityException) {
                Log.e(TAG, "Permission denied for file access", e)
                Result.failure(
                    CustomAudioError.FileCopyFailed("Permission denied: ${e.message}")
                )
            }
        }

    override suspend fun delete(id: String) {
        withContext(Dispatchers.IO) {
            val file = dataStore.findFile(id)
            if (file != null) {
                deleteLocalFile(file)
            }
            dataStore.deleteFile(id)
            Log.d(TAG, "Deleted custom audio file: $id")
        }
    }

    override suspend fun getFilePath(id: String): String? {
        val file = dataStore.findFile(id) ?: return null
        val dir = getDirectory(file.type)
        val localFile = File(dir, file.filename)
        return if (localFile.exists()) localFile.absolutePath else null
    }

    override suspend fun findFile(id: String): CustomAudioFile? = dataStore.findFile(id)

    override suspend fun rename(id: String, newName: String) {
        withContext(Dispatchers.IO) {
            dataStore.renameFile(id, newName)
            Log.d(TAG, "Renamed custom audio file: $id -> $newName")
        }
    }

    /**
     * Copies a file from a SAF content URI to app-internal storage.
     * Files are stored in type-specific subdirectories under custom_audio/.
     */
    private fun copyFileToInternalStorage(sourceUri: Uri, originalFileName: String, type: CustomAudioType): File {
        val dir = getDirectory(type)
        if (!dir.exists()) dir.mkdirs()

        val extension = originalFileName.substringAfterLast(".", "mp3")
        val uniqueFileName = "${UUID.randomUUID()}.$extension"
        val destFile = File(dir, uniqueFileName)

        context.contentResolver.openInputStream(sourceUri)?.use { input ->
            destFile.outputStream().use { output ->
                input.copyTo(output)
            }
        } ?: throw IOException("Could not open source file")

        return destFile
    }

    /**
     * Deletes the local audio file. Logs warnings on failure but does not throw.
     */
    private fun deleteLocalFile(file: CustomAudioFile) {
        val dir = getDirectory(file.type)
        val localFile = File(dir, file.filename)
        try {
            if (localFile.exists()) {
                localFile.delete()
                Log.d(TAG, "Deleted local file: ${localFile.absolutePath}")
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Permission denied when deleting file ${file.id}", e)
        }
    }

    private fun getDirectory(type: CustomAudioType): File {
        val subDir =
            when (type) {
                CustomAudioType.SOUNDSCAPE -> "soundscapes"
            }
        return File(context.filesDir, "$CUSTOM_AUDIO_DIR/$subDir")
    }

    /**
     * Extracts the file name from a content URI using ContentResolver.
     */
    private fun getFileName(uri: Uri): String {
        var fileName = "Unknown.mp3"
        context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    fileName = cursor.getString(nameIndex) ?: "Unknown.mp3"
                }
            }
        }
        return fileName
    }

    /**
     * Extracts audio duration using MediaMetadataRetriever.
     * Returns null if duration cannot be determined.
     */
    private fun extractDuration(uri: Uri): Long? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION
            )?.toLongOrNull()
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "Invalid data source for duration extraction", e)
            null
        } catch (e: IllegalStateException) {
            Log.w(TAG, "MediaMetadataRetriever in invalid state", e)
            null
        } finally {
            retriever.release()
        }
    }

    companion object {
        private const val TAG = "CustomAudioRepo"
        private const val CUSTOM_AUDIO_DIR = "custom_audio"
        private val SUPPORTED_EXTENSIONS = setOf("mp3", "m4a", "wav")
    }
}
