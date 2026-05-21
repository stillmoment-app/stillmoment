package com.stillmoment.data

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.models.PendingImport
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.first

/**
 * Handles importing audio files received via "Open with" file association.
 *
 * Triggered when the user opens an MP3 or M4A file from a file manager and
 * chooses Still Moment, or when the user shares an audio file with the app.
 *
 * Flow (shared-103):
 * 1. Validate file format (MP3/M4A only via MIME type)
 * 2. Check for duplicates (same filename + file size)
 * 3. Extract metadata + return [PendingImport] — persistence is the caller's
 *    responsibility (typically the ViewModel after the user confirms the
 *    import edit sheet).
 *
 * Note: this handler no longer persists library entries directly. That
 * responsibility moved into the ViewModel so the import can be cancelled
 * without leaving file leftovers or stub entries behind.
 */
@Singleton
class FileOpenHandler
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val repository: GuidedMeditationRepository,
    private val logger: LoggerProtocol
) {
    companion object {
        private const val TAG = "FileOpen"

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
     * Validates that the given URI points to a supported audio format.
     * Does NOT check for duplicates or import the file.
     */
    fun validateFileFormat(uri: Uri): Result<Unit> {
        if (!canHandle(uri)) {
            logger.w(TAG, "Rejected file with unsupported format: $uri")
            return Result.failure(FileOpenException(FileOpenError.UNSUPPORTED_FORMAT))
        }
        return Result.success(Unit)
    }

    /**
     * Validates the file and prepares the data the import edit sheet needs.
     *
     * Performs format validation, duplicate detection, and metadata extraction;
     * persistence happens only after the user confirms the edit sheet via the
     * ViewModel.
     *
     * @param uri Content URI to the audio file
     * @return [PendingImport] on success; [FileOpenException] with the relevant
     *         [FileOpenError] on failure.
     */
    suspend fun validateAndPrepareImport(uri: Uri): Result<PendingImport> {
        logger.d(TAG, "Validating file URI: $uri")

        if (!canHandle(uri)) {
            logger.w(TAG, "Rejected file with unsupported format: $uri")
            return Result.failure(FileOpenException(FileOpenError.UNSUPPORTED_FORMAT))
        }

        val fileName = getFileName(uri)
        if (isDuplicate(uri, fileName)) {
            logger.d(TAG, "File already imported: $fileName")
            return Result.failure(FileOpenException(FileOpenError.ALREADY_IMPORTED))
        }

        return try {
            val metadata = repository.extractMetadata(uri.toString())
            val prefill = com.stillmoment.domain.models.ImportPrefill.compute(
                metadata = metadata,
                fileName = fileName,
                knownTeachers = emptyList()
            )
            // knownTeachers stays empty here — the ViewModel re-computes the
            // prefill once it has access to the current library to seed
            // teacher autocomplete. That keeps the handler free of library
            // state.
            Result.success(
                PendingImport(
                    uri = uri.toString(),
                    fileName = fileName,
                    metadata = metadata,
                    prefill = prefill
                )
            )
        } catch (e: SecurityException) {
            logger.e(TAG, "Permission denied while extracting metadata for $uri", e)
            Result.failure(FileOpenException(FileOpenError.IMPORT_FAILED, e))
        } catch (e: IllegalArgumentException) {
            logger.e(TAG, "Invalid file format while extracting metadata for $uri", e)
            Result.failure(FileOpenException(FileOpenError.IMPORT_FAILED, e))
        }
    }

    /**
     * Checks whether a file with the same name and size is already in the library.
     */
    private suspend fun isDuplicate(uri: Uri, incomingFileName: String): Boolean {
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
        // Android 7+: ContentResolver.query() returns null for file:// URIs.
        // Read the filename directly from the path instead.
        if (uri.scheme == "file") {
            return uri.lastPathSegment ?: "Unknown"
        }
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
        } catch (e: SecurityException) {
            logger.w(TAG, "Could not query file size for $uri: ${e.message}")
            null
        }
    }

    private fun queryFileSize(uri: Uri): Long? {
        // Android 7+: ContentResolver.query() returns null for file:// URIs.
        // Read the size directly from the file instead.
        if (uri.scheme == "file") {
            val path = uri.path ?: return null
            val file = java.io.File(path)
            return if (file.exists()) file.length() else null
        }
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
