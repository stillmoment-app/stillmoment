package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.Praxis

/**
 * Repository interface for managing the user's Praxis (timer configuration).
 *
 * Currently supports a single-praxis model: one active Praxis at a time.
 * Future tickets (shared-063/064) will extend this to multi-praxis CRUD.
 */
interface PraxisRepository {
    /**
     * Loads the current Praxis.
     * Returns a default Praxis if none has been saved yet.
     *
     * @return The current Praxis
     */
    suspend fun load(): Praxis

    /**
     * Saves the given Praxis, replacing any previously stored one.
     *
     * @param praxis The Praxis to persist
     */
    suspend fun save(praxis: Praxis)
}
