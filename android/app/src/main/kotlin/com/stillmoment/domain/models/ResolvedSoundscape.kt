package com.stillmoment.domain.models

/**
 * A resolved soundscape audio entry, regardless of source (built-in or user-imported).
 *
 * Consumers use this instead of checking BackgroundSoundRepository + CustomAudioRepository separately.
 * The resolver transparently handles both sources.
 *
 * @property id Unique identifier (BackgroundSound.id for built-in, UUID string for custom)
 * @property displayName Localized display name
 */
data class ResolvedSoundscape(
    val id: String,
    val displayName: String
)
