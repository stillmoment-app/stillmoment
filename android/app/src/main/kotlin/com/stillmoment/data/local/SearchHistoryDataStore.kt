package com.stillmoment.data.local

import android.content.Context
import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.repositories.SearchHistoryRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.SerializationException
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json

// Eigenes DataStore-File `search_history`, getrennt von `settings.preferences_pb`.
//
// Begruendung — siehe `appSettingsDataStore` Doc-Kommentar in [SettingsDataStore]: zwei
// `preferencesDataStore(name = ...)`-Properties auf dem gleichen File crashen die App
// (`IllegalStateException: multiple DataStores active for the same file`). Eigenes File
// vermeidet diese Falle automatisch.
internal val Context.searchHistoryDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "search_history"
)

/**
 * DataStore-Implementierung fuer [SearchHistoryRepository] (shared-101).
 *
 * Persistiert die Suchhistorie als JSON-`List<String>` in einem einzigen
 * `stringPreferencesKey("history")`. `stringSetPreferencesKey` waere ungeeignet —
 * dort ist die Reihenfolge nicht garantiert, was den FIFO-Cap broeselt.
 *
 * Bei korruptem Storage (Manuelle Manipulation, App-Migrationsfehler) faellt der
 * Decode auf eine leere Liste zurueck statt zu crashen.
 */
@Singleton
class SearchHistoryDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context
) : SearchHistoryRepository {
    private object Keys {
        val HISTORY = stringPreferencesKey("history")
    }

    override val historyFlow: Flow<List<String>> = context.searchHistoryDataStore.data
        .map { preferences -> SearchHistoryCodec.decode(preferences[Keys.HISTORY]) }

    override suspend fun save(history: List<String>) {
        context.searchHistoryDataStore.edit { preferences ->
            preferences[Keys.HISTORY] = SearchHistoryCodec.encode(history)
        }
    }

    override suspend fun clear() {
        context.searchHistoryDataStore.edit { preferences ->
            preferences[Keys.HISTORY] = SearchHistoryCodec.encode(emptyList())
        }
    }
}

/**
 * Pure Encode/Decode-Helfer fuer die Suchhistorie.
 *
 * In einem internen Object extrahiert, damit die Persistenz-Logik (JSON-Roundtrip,
 * Fehlertoleranz bei korruptem Storage) ohne Android-Context unit-testbar bleibt.
 */
internal object SearchHistoryCodec {
    private const val TAG = "SearchHistoryDataStore"

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    private val serializer = ListSerializer(String.serializer())

    /**
     * Encodiert eine Historie als JSON-String fuer die Persistenz.
     */
    fun encode(history: List<String>): String = json.encodeToString(serializer, history)

    /**
     * Decodiert eine gespeicherte Historie aus dem JSON-String.
     *
     * - `null` oder leerer String → leere Liste.
     * - Korrupter JSON-String → leere Liste (Log-Warnung, kein Crash).
     */
    fun decode(raw: String?): List<String> {
        if (raw.isNullOrEmpty()) {
            return emptyList()
        }
        return try {
            json.decodeFromString(serializer, raw)
        } catch (e: SerializationException) {
            Log.w(TAG, "Failed to parse search history JSON, returning empty list", e)
            emptyList()
        }
    }
}
