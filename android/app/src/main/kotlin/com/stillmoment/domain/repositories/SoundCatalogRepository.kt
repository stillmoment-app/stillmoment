package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.BackgroundSound

/**
 * Repository for the background sound catalog.
 * Provides access to all available built-in background sounds.
 */
interface SoundCatalogRepository {
    /** Returns all available background sounds. */
    fun getAllSounds(): List<BackgroundSound>

    /** Finds a background sound by ID, or null if not found. */
    fun findById(id: String): BackgroundSound?

    /** Finds a background sound by ID, returning the silent option if not found. */
    fun findByIdOrDefault(id: String): BackgroundSound
}
