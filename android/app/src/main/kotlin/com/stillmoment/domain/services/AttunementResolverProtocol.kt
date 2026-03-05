package com.stillmoment.domain.services

import com.stillmoment.domain.models.ResolvedAttunement

/**
 * Resolves attunement audio IDs transparently across built-in catalog and custom imports.
 *
 * Consumers should use this interface instead of directly checking [Introduction.find]
 * or [CustomAudioRepository.findFile] to ensure both sources are always considered.
 */
interface AttunementResolverProtocol {
    /**
     * Resolves an attunement by ID -- checks built-in catalog first, then custom audio.
     *
     * Suspend because [CustomAudioRepository.findFile] is suspend.
     *
     * @param id Built-in ID (e.g. "breath") or custom audio UUID
     * @return Resolved attunement or null if not found in either source
     */
    suspend fun resolve(id: String): ResolvedAttunement?

    /**
     * Synchronous resolve -- only checks the built-in catalog.
     *
     * Safe for pure Reducer functions that cannot call suspend functions.
     *
     * @param id Built-in ID to look up
     * @return Resolved attunement or null if not found in built-in catalog
     */
    fun resolveBuiltIn(id: String): ResolvedAttunement?

    /**
     * Checks if a built-in attunement is available for the current device language.
     *
     * @param id Built-in ID to check
     * @return True if the attunement exists and has audio for the current language
     */
    fun isBuiltInAvailableForCurrentLanguage(id: String): Boolean
}
