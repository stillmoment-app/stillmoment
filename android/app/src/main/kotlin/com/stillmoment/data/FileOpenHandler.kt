package com.stillmoment.data

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.first

/**
 * Handles importing audio files received via "Open with" file association.
 *
 * This handler is triggered when the user opens an MP3 or M4A file
 * from a file manager and chooses Still Moment.
 *
 * Flow:
 * 1. Validate file format (MP3/M4A only via MIME type)
 * 2. Check for duplicates (same filename + file size)
 * 3. Import via GuidedMeditationRepository
 */
@Singleton
class FileOpenHandler
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val repository: GuidedMeditationRepository
) {
    companion object {
        /** Supported MIME types for audio import */
        val SUPPORTED_MIME_TYPES = setOf(
            "audio/mpeg",
            "audio/mp4",
            "audio/x-m4a"
        )

        /** Supported file extensions (fallback when MIME type is unavailable) */
        val SUPPORTED_EXTENSIONS = setOf("mp3", "m4a")
    }

    /**
     * Checks whether the given URI points to a supported audio file.
     */
    fun canHandle(uri: Uri): Boolean {
        val mimeType = context.contentResolver.getType(uri)
        if (mimeType != null && mimeType in SUPPORTED_MIME_TYPES) {
            return true
        }
        // Fallback: check file extension from display name
        val fileName = getFileName(uri)
        val extension = fileName.substringAfterLast(".", "").lowercase()
        return extension in SUPPORTED_EXTENSIONS
    }

    /**
     * Handles a file open request from the system.
     *
     * Validates the format, checks for duplicates, and imports the file
     * into the meditation library.
     *
     * @param uri Content URI to the audio file
     * @return Result with the imported GuidedMeditation or a FileOpenError
     */
    suspend fun handleFileOpen(uri: Uri): Result<GuidedMeditation> {
        if (!canHandle(uri)) {
            return Result.failure(FileOpenException(FileOpenError.UNSUPPORTED_FORMAT))
        }

        if (isDuplicate(uri)) {
            return Result.failure(FileOpenException(FileOpenError.ALREADY_IMPORTED))
        }

        val importResult = repository.importMeditation(uri)
        return importResult.fold(
            onSuccess = { Result.success(it) },
            onFailure = { Result.failure(FileOpenException(FileOpenError.IMPORT_FAILED, it)) }
        )
    }

    /**
     * Checks whether a file with the same name and size is already in the library.
     */
    private suspend fun isDuplicate(uri: Uri): Boolean {
        val incomingFileName = getFileName(uri)
        val incomingSize = getFileSize(uri)

        val existing = repository.meditationsFlow.first()
        return existing.any { meditation ->
            if (meditation.fileName != incomingFileName) return@any false
            // If we can't determine incoming size, fall back to name-only check
            if (incomingSize == null) return@any true
            // Compare file sizes for name matches
            val existingSize = getFileSizeFromUri(Uri.parse(meditation.fileUri))
            existingSize == incomingSize
        }
    }

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

    private fun getFileSize(uri: Uri): Long? {
        return try {
            queryFileSize(uri)
        } catch (_: Exception) {
            null
        }
    }

    private fun queryFileSize(uri: Uri): Long? {
        val cursor = context.contentResolver.query(uri, null, null, null, null) ?: return null
        return cursor.use {
            if (!it.moveToFirst()) return@use null
            val sizeIndex = it.getColumnIndex(OpenableColumns.SIZE)
            if (sizeIndex >= 0 && !it.isNull(sizeIndex)) it.getLong(sizeIndex) else null
        }
    }

    private fun getFileSizeFromUri(uri: Uri): Long? {
        if (uri.scheme == "file") {
            val path = uri.path ?: return null
            val file = java.io.File(path)
            return if (file.exists()) file.length() else null
        }
        return getFileSize(uri)
    }
}

/**
 * Exception wrapping a FileOpenError for use with Result<T>.
 */
class FileOpenException(
    val error: FileOpenError,
    cause: Throwable? = null
) : Exception("File open failed: ${error.name}", cause)
