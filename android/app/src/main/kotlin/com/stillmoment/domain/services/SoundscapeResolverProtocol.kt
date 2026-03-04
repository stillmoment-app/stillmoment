package com.stillmoment.domain.services

import com.stillmoment.domain.models.ResolvedSoundscape

/**
 * Resolves soundscape audio IDs transparently across built-in catalog and custom imports.
 *
 * Consumers should use this interface instead of directly checking [SoundCatalogRepository.findById]
 * or [CustomAudioRepository.findFile] to ensure both sources are always considered.
 */
interface SoundscapeResolverProtocol {
    /**
     * Resolves a soundscape by ID -- checks built-in catalog first, then custom audio.
     *
     * Suspend because [CustomAudioRepository.findFile] is suspend.
     *
     * @param id Built-in ID (e.g. "forest") or custom audio UUID
     * @return Resolved soundscape or null if not found in either source
     */
    suspend fun resolve(id: String): ResolvedSoundscape?

    /**
     * Synchronous resolve -- only checks the built-in catalog.
     *
     * Safe for pure Reducer functions that cannot call suspend functions.
     *
     * @param id Built-in ID to look up
     * @return Resolved soundscape or null if not found in built-in catalog
     */
    fun resolveBuiltIn(id: String): ResolvedSoundscape?
}
