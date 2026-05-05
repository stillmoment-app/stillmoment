package com.stillmoment.domain.models

import kotlinx.serialization.Serializable

/**
 * Type of custom audio file. Currently only soundscapes are supported —
 * the legacy ATTUNEMENT entry was removed in shared-088. The enum is preserved
 * (rather than collapsed to a flag) so future custom-audio types can extend it
 * and so the persistence format keeps a stable, self-describing `"type"` field.
 */
@Serializable
enum class CustomAudioType {
    /** Background sound that loops during meditation */
    SOUNDSCAPE
}
