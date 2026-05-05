package com.stillmoment.data.migration

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.first
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Identical preferencesDataStore name as [com.stillmoment.data.local.CustomAudioDataStore].
 * Multiple `preferencesDataStore` calls with the same name share the same instance,
 * so the migration sees the same backing file as the production data store.
 */
private val Context.customAudioDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "custom_audio"
)

/**
 * Same backing file as [com.stillmoment.data.local.SettingsDataStore]. Used here for the
 * idempotency marker and to remove legacy attunement keys.
 */
private val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "settings"
)

/**
 * One-shot migration that removes the Einstimmung/Attunement feature data on first start
 * after upgrade.
 *
 * Why this is required: the [com.stillmoment.domain.models.CustomAudioType] enum no
 * longer contains an `ATTUNEMENT` entry. If the persisted custom-audio JSON list still
 * contains rows with `"type":"ATTUNEMENT"`, kotlinx.serialization fails to decode the
 * whole list — which would also lose every soundscape. The migration filters those rows
 * out at the raw-JSON level, before any code path tries to deserialize.
 *
 * Side effects:
 *  - Filters `"ATTUNEMENT"` rows out of the custom-audio DataStore JSON list.
 *  - Recursively deletes the local custom-attunement audio files.
 *  - Removes legacy `introductionId` / `introductionEnabled` keys from the settings store.
 *  - Sets a `migration_attunement_removed_v1` marker so subsequent starts skip the work.
 *
 * Failure mode: each step is wrapped in try/catch and logged. A partial failure does not
 * prevent the marker from being set — leftover files cannot be referenced anymore.
 */
@Singleton
class AttunementCleanupMigration @Inject constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) {
    /**
     * Runs the migration once. Subsequent calls are no-ops thanks to the marker.
     */
    suspend fun runIfNeeded() {
        val alreadyRun = context.settingsDataStore.data.first()[MARKER_KEY] == true
        if (alreadyRun) return

        val filteredCount = filterCustomAudioJson()
        val filesRemoved = deleteCustomAttunementDirectory()
        removeLegacySettingsKeys()
        setMarker()

        logger.d(
            TAG,
            "Attunement cleanup migration completed: filesRemoved=$filesRemoved, " +
                "audioEntriesFiltered=$filteredCount"
        )
    }

    @Suppress("TooGenericExceptionCaught") // intentional: any failure is logged, marker still set
    private suspend fun filterCustomAudioJson(): Int {
        return try {
            var removed = 0
            context.customAudioDataStore.edit { prefs ->
                val raw = prefs[CUSTOM_AUDIO_FILES_KEY] ?: return@edit
                val (filtered, removedCount) = filterAttunementEntries(raw)
                removed = removedCount
                if (removedCount > 0) {
                    prefs[CUSTOM_AUDIO_FILES_KEY] = filtered
                }
            }
            removed
        } catch (e: Exception) {
            logger.e(TAG, "Failed to filter custom audio JSON", e)
            0
        }
    }

    @Suppress("TooGenericExceptionCaught") // intentional: any failure is logged, marker still set
    private fun deleteCustomAttunementDirectory(): Int {
        return try {
            val dir = File(context.filesDir, "$CUSTOM_AUDIO_DIR/$ATTUNEMENT_SUBDIR")
            if (!dir.exists()) return 0
            val count = dir.walkTopDown().count { it.isFile }
            val deleted = dir.deleteRecursively()
            if (!deleted) {
                logger.w(TAG, "Failed to fully delete custom attunement directory: ${dir.absolutePath}")
            }
            count
        } catch (e: Exception) {
            logger.e(TAG, "Failed to delete custom attunement directory", e)
            0
        }
    }

    @Suppress("TooGenericExceptionCaught") // intentional: any failure is logged, marker still set
    private suspend fun removeLegacySettingsKeys() {
        try {
            context.settingsDataStore.edit { prefs ->
                prefs.remove(stringPreferencesKey("introductionId"))
                prefs.remove(booleanPreferencesKey("introductionEnabled"))
            }
        } catch (e: Exception) {
            logger.e(TAG, "Failed to remove legacy settings keys", e)
        }
    }

    private suspend fun setMarker() {
        context.settingsDataStore.edit { prefs ->
            prefs[MARKER_KEY] = true
        }
    }

    companion object {
        private const val TAG = "AttunementCleanupMigration"
        private const val CUSTOM_AUDIO_DIR = "custom_audio"
        private const val ATTUNEMENT_SUBDIR = "attunements"
        private val MARKER_KEY = booleanPreferencesKey("migration_attunement_removed_v1")
        private val CUSTOM_AUDIO_FILES_KEY = stringPreferencesKey("custom_audio_files")
        private val migrationJson = Json {
            ignoreUnknownKeys = true
            isLenient = true
        }

        /**
         * Pure helper: parses the custom-audio JSON list as a [JsonArray] (without using the
         * [com.stillmoment.domain.models.CustomAudioType] enum) and removes any element with
         * `"type":"ATTUNEMENT"`. Returns the re-encoded JSON and the number of removed rows.
         *
         * Exposed as `internal` so the unit test can lock in this behaviour without standing up
         * Android Context infrastructure.
         */
        internal fun filterAttunementEntries(rawJson: String): Pair<String, Int> {
            val parsed = migrationJson.parseToJsonElement(rawJson)
            if (parsed !is JsonArray) return rawJson to 0

            var removed = 0
            val kept = mutableListOf<JsonElement>()
            for (element in parsed) {
                val type = element.jsonObject["type"]?.jsonPrimitive?.content
                if (type == "ATTUNEMENT") {
                    removed++
                } else {
                    kept.add(element)
                }
            }
            if (removed == 0) return rawJson to 0

            val rebuilt = buildJsonArray { kept.forEach { add(it) } }
            return migrationJson.encodeToString(JsonArray.serializer(), rebuilt) to removed
        }
    }
}
