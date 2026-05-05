package com.stillmoment.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Extension property for the Praxis DataStore.
 * Uses a separate "praxis" file, distinct from the "settings" DataStore.
 */
private val Context.praxisDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "praxis"
)

/**
 * DataStore-based implementation of PraxisRepository.
 *
 * Stores the current Praxis as a JSON string in Jetpack DataStore.
 * Handles migration from existing MeditationSettings on first launch after upgrade.
 *
 * Migration strategy (tried in order):
 * 1. Load from stored JSON in praxis DataStore
 * 2. Migrate from existing MeditationSettings in SettingsDataStore
 * 3. Fresh install: use Praxis.Default
 */
@Singleton
class PraxisDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) : PraxisRepository {
    private val _praxisState = MutableStateFlow<Praxis?>(null)
    override val praxisFlow: Flow<Praxis> = _praxisState.filterNotNull()

    private object Keys {
        val CURRENT_PRAXIS = stringPreferencesKey("current_praxis")
    }

    override suspend fun load(): Praxis {
        val prefs = context.praxisDataStore.data.first()
        val json = prefs[Keys.CURRENT_PRAXIS]

        if (json != null) {
            val decoded = decodeOrNull(json)
            if (decoded != null) {
                _praxisState.value = decoded
                return decoded
            }
            logger.e(TAG, "Failed to decode stored praxis, re-migrating")
        }

        return migrateOrDefault()
    }

    override suspend fun save(praxis: Praxis) {
        val json = praxisJson.encodeToString(praxis)
        context.praxisDataStore.edit { prefs ->
            prefs[Keys.CURRENT_PRAXIS] = json
        }
        _praxisState.value = praxis
        logger.d(TAG, "Saved praxis id=${praxis.id}")
    }

    /**
     * Creates a fresh default Praxis.
     * The result is saved to the praxis DataStore.
     */
    private suspend fun migrateOrDefault(): Praxis {
        val praxis = Praxis.Default.also {
            logger.d(TAG, "Created default Praxis for fresh install")
        }
        save(praxis)
        return praxis
    }

    /**
     * Safely decodes a JSON string to a Praxis, returning null on failure.
     *
     * Uses [praxisJson] with `ignoreUnknownKeys = true` so legacy fields removed in
     * later versions (e.g. `introductionId` / `introductionEnabled` from the
     * Einstimmung feature) do not cause the decode to fail.
     */
    @Suppress("TooGenericExceptionCaught") // Intentional: catch any deserialization failure
    private fun decodeOrNull(json: String): Praxis? {
        return try {
            praxisJson.decodeFromString<Praxis>(json)
        } catch (e: Exception) {
            logger.e(TAG, "JSON decode failed", e)
            null
        }
    }

    companion object {
        private const val TAG = "PraxisDataStore"
        private val praxisJson = Json { ignoreUnknownKeys = true }
    }
}
