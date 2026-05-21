package com.stillmoment.domain.repositories

import kotlinx.coroutines.flow.Flow

/**
 * Persistenz fuer die Bibliotheks-Suchhistorie (shared-101).
 *
 * Implementierungen leben in der Data-Schicht (`SearchHistoryDataStore`).
 */
interface SearchHistoryRepository {
    /**
     * Flow der aktuellen Historie; emittiert bei jeder Aenderung.
     *
     * Neueste Eintraege zuerst. Eintraege sind getrimmt und nicht-leer.
     */
    val historyFlow: Flow<List<String>>

    /**
     * Speichert die uebergebene Historie atomar.
     */
    suspend fun save(history: List<String>)

    /**
     * Loescht die gesamte Historie.
     */
    suspend fun clear()
}
