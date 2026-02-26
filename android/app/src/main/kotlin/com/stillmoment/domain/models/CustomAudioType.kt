package com.stillmoment.domain.models

import kotlinx.serialization.Serializable

/**
 * Type of custom audio file.
 *
 * Soundscapes loop during meditation, attunements play once after the start gong.
 */
@Serializable
enum class CustomAudioType {
    /** Background sound that loops during meditation */
    SOUNDSCAPE,

    /** Introduction audio that plays once after the start gong */
    ATTUNEMENT
}
