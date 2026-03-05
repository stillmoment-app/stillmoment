package com.stillmoment.domain.services

import com.stillmoment.domain.models.ResolvedAttunement

/**
 * Resolves attunement audio IDs transparently -- regardless of whether
 * they refer to a built-in introduction or a user-imported custom attunement.
 *
 * Consumers never need to check Introduction + CustomAudioRepository separately.
 * The resolver encapsulates the dual lookup logic in one place.
 *
 * Protocol lives in Domain; implementation (with catalog + file system access) in Infrastructure.
 */
interface AttunementResolverProtocol {
    /**
     * Resolves an attunement by ID. Returns null if the ID is unknown or unavailable.
     */
    fun resolve(id: String): ResolvedAttunement?

    /**
     * Returns all attunements available for the current language (built-in + custom).
     */
    fun allAvailable(): List<ResolvedAttunement>
}
