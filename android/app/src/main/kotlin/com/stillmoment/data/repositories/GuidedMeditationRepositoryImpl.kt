package com.stillmoment.data.repositories

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.domain.models.AudioMetadata
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.services.AudioMetadataService
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.io.IOException
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flatMapConcat
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerializationException
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Implementation of [GuidedMeditationRepository].
 *
 * Responsibilities:
 * 1. Persists library entries via [GuidedMeditationDataStore].
 * 2. Copies imported audio files into app-internal storage on save.
 * 3. Runs the shared-103 override-cleanup migration once per install
 *    ([migrateLegacyOverridesIfNeeded]) before the first flow emission.
 *
 * Metadata extraction is delegated to [AudioMetadataService] — this class no
 * longer touches `MediaMetadataRetriever` directly.
 */
@Singleton
class GuidedMeditationRepositoryImpl
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val dataStore: GuidedMeditationDataStore,
    private val settingsDataStore: SettingsDataStore,
    private val audioMetadataService: AudioMetadataService
) : GuidedMeditationRepository {
    private val migrationMutex = Mutex()

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    override val meditationsFlow: Flow<List<GuidedMeditation>> = flow {
        migrateLegacyOverridesIfNeeded()
        emit(Unit)
    }.flatMapConcat {
        dataStore.meditationsFlow
    }.flowOn(Dispatchers.IO)

    override suspend fun extractMetadata(uri: String): AudioMetadata {
        return audioMetadataService.extract(uri)
    }

    override suspend fun addMeditation(
        sourceUri: String,
        fileName: String,
        metadata: AudioMetadata,
        teacher: String,
        name: String
    ): Result<GuidedMeditation> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Adding meditation: $fileName from $sourceUri")
                val localFile = copyFileToInternalStorage(Uri.parse(sourceUri), fileName)
                val localUri = Uri.fromFile(localFile)
                val meditation = GuidedMeditation(
                    fileUri = localUri.toString(),
                    fileName = fileName,
                    duration = metadata.duration,
                    teacher = teacher,
                    name = name
                )
                dataStore.addMeditation(meditation)
                Result.success(meditation)
            } catch (e: SecurityException) {
                Log.e(TAG, "Permission denied for file access", e)
                Result.failure(ImportException("Permission denied for file access", e))
            } catch (e: IOException) {
                Log.e(TAG, "Failed to read/copy meditation file", e)
                Result.failure(ImportException("Failed to read file: ${e.message}", e))
            } catch (e: IllegalArgumentException) {
                Log.e(TAG, "Invalid file format or metadata", e)
                Result.failure(ImportException("Invalid file: ${e.message}", e))
            }
        }
    }

    override suspend fun deleteMeditation(id: String) {
        val meditation = dataStore.getMeditation(id)
        if (meditation != null) {
            deleteLocalFile(meditation, id)
        }
        dataStore.deleteMeditation(id)
    }

    /**
     * Deletes the local audio file for a meditation if it exists.
     * Logs warnings on failure but does not throw.
     */
    private fun deleteLocalFile(meditation: GuidedMeditation, id: String) {
        val uri = Uri.parse(meditation.fileUri)
        if (uri.scheme != "file") return

        val path = uri.path ?: return
        val file = File(path)

        try {
            if (file.exists() && file.delete()) {
                Log.d(TAG, "Deleted local file: ${file.absolutePath}")
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Permission denied when deleting file for meditation $id", e)
        } catch (e: IOException) {
            Log.w(TAG, "IO error when deleting file for meditation $id", e)
        }
    }

    override suspend fun updateMeditation(meditation: GuidedMeditation) {
        dataStore.updateMeditation(meditation)
    }

    override suspend fun getMeditation(id: String): GuidedMeditation? {
        return dataStore.getMeditation(id)
    }

    override suspend fun getFileName(uri: String): String {
        return getFileName(Uri.parse(uri))
    }

    /**
     * One-shot override-cleanup migration (shared-103).
     *
     * Reads the raw stored JSON, parses it against a permissive schema that
     * still understands `customTeacher` / `customName`, folds the override
     * values into `teacher` / `name`, and writes the canonical schema back.
     *
     * Idempotent — guarded by a flag in [SettingsDataStore]; subsequent app
     * starts skip the sweep entirely.
     */
    suspend fun migrateLegacyOverridesIfNeeded() {
        migrationMutex.withLock {
            if (settingsDataStore.isGuidedOverridesMigrated()) {
                return@withLock
            }
            try {
                val rawJson = dataStore.readRawJson()
                if (rawJson == null) {
                    settingsDataStore.markGuidedOverridesMigrated()
                    return@withLock
                }
                val migrated = foldLegacyOverrides(rawJson)
                if (migrated != null) {
                    dataStore.writeRawJson(migrated)
                }
                settingsDataStore.markGuidedOverridesMigrated()
            } catch (e: SerializationException) {
                Log.w(TAG, "Override-cleanup migration: failed to parse legacy JSON", e)
                settingsDataStore.markGuidedOverridesMigrated()
            }
        }
    }

    /**
     * Pure transformation: take a raw JSON list, fold legacy override fields,
     * return the canonical JSON. Returns `null` when no changes were necessary.
     */
    private fun foldLegacyOverrides(rawJson: String): String? {
        val parsed = MIGRATION_JSON.parseToJsonElement(rawJson)
        val list = parsed.jsonArray
        var didChange = false
        val rewritten = buildJsonArray {
            for (entry in list) {
                val obj = entry.jsonObject
                val hasLegacyKeys = obj.containsKey("customTeacher") || obj.containsKey("customName")
                if (!hasLegacyKeys) {
                    add(obj)
                    continue
                }
                didChange = true
                add(foldEntry(obj))
            }
        }
        return if (didChange) MIGRATION_JSON.encodeToString(JsonElement.serializer(), rewritten) else null
    }

    private fun foldEntry(obj: JsonObject): JsonObject {
        val customTeacher = obj["customTeacher"]?.jsonPrimitiveOrNull()
        val customName = obj["customName"]?.jsonPrimitiveOrNull()
        val newTeacher = customTeacher?.takeIf { it.isNotBlank() }
            ?: obj["teacher"]?.jsonPrimitiveOrNull()
            ?: ""
        val newName = customName?.takeIf { it.isNotBlank() }
            ?: obj["name"]?.jsonPrimitiveOrNull()
            ?: ""
        return buildJsonObject {
            obj.forEach { (key, value) ->
                when (key) {
                    "customTeacher", "customName" -> Unit
                    "teacher" -> put("teacher", JsonPrimitive(newTeacher))
                    "name" -> put("name", JsonPrimitive(newName))
                    else -> put(key, value)
                }
            }
        }
    }

    private fun JsonElement.jsonPrimitiveOrNull(): String? {
        return runCatching { jsonPrimitive.contentOrNull }.getOrNull()
    }

    private val JsonPrimitive.contentOrNull: String?
        get() = if (isString) content else null

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
     * Extracts the file name from a URI.
     *
     * For content:// URIs, queries the ContentResolver for DISPLAY_NAME.
     * For file:// URIs, reads the last path segment directly — Android 7+
     * returns null from ContentResolver.query() for file scheme.
     */
    private fun getFileName(uri: Uri): String {
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

    companion object {
        private const val TAG = "GuidedMeditationRepo"
        private const val MEDITATIONS_DIR = "meditations"

        /**
         * Lenient JSON config for the legacy-fold migration. Mirrors the
         * production config (`ignoreUnknownKeys`) so the parser tolerates extra
         * fields written by future versions.
         */
        private val MIGRATION_JSON = Json {
            ignoreUnknownKeys = true
            encodeDefaults = true
        }
    }
}

/**
 * Exception thrown when meditation import fails.
 */
class ImportException(message: String, cause: Throwable? = null) : Exception(message, cause)
