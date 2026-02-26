package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.Praxis
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for managing the user's Praxis (timer configuration).
 *
 * Supports a single-praxis model: one active Praxis at a time.
 */
interface PraxisRepository {
    /**
     * Observable flow of the current Praxis.
     * Emits whenever the Praxis is loaded or saved.
     * Only emits non-null values (skips the initial unloaded state).
     */
    val praxisFlow: Flow<Praxis>

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
