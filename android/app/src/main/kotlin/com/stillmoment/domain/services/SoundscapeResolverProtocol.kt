package com.stillmoment.domain.services

import com.stillmoment.domain.models.ResolvedSoundscape

/**
 * Resolves soundscape audio IDs transparently -- regardless of whether
 * they refer to a built-in background sound or a user-imported custom soundscape.
 *
 * Consumers never need to check SoundCatalogRepository + CustomAudioRepository separately.
 * The resolver encapsulates the dual lookup logic in one place.
 *
 * Protocol lives in Domain; implementation (with catalog + file system access) in Infrastructure.
 */
interface SoundscapeResolverProtocol {
    /**
     * Resolves a soundscape by ID. Returns null if the ID is unknown.
     * The special "silent" ID returns null (no sound to resolve).
     */
    fun resolve(id: String): ResolvedSoundscape?

    /**
     * Returns all available soundscapes (built-in + custom).
     */
    fun allAvailable(): List<ResolvedSoundscape>
}
