package com.stillmoment.domain.models

/**
 * A resolved soundscape audio, agnostic to its source (built-in catalog or custom import).
 *
 * Produced by [com.stillmoment.domain.services.SoundscapeResolverProtocol] to provide
 * a uniform representation that consumers can use without knowing the underlying source.
 *
 * @property id Unique identifier (built-in ID like "forest" or custom UUID)
 * @property name Localized display name
 * @property isBuiltIn True if from built-in catalog, false if user-imported
 * @property isSilent True if this represents the "no audio" option
 */
data class ResolvedSoundscape(
    val id: String,
    val name: String,
    val isBuiltIn: Boolean,
    val isSilent: Boolean
)
