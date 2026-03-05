package com.stillmoment.domain.models

/**
 * A resolved attunement audio entry, regardless of source (built-in or user-imported).
 *
 * Consumers use this instead of checking Introduction + CustomAudioRepository separately.
 * The resolver transparently handles both sources.
 *
 * @property id Unique identifier (Introduction.id for built-in, UUID string for custom)
 * @property displayName Localized display name
 * @property durationSeconds Audio duration in seconds
 */
data class ResolvedAttunement(
    val id: String,
    val displayName: String,
    val durationSeconds: Int
)
