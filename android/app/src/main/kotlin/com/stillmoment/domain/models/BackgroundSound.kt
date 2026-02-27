package com.stillmoment.domain.models

/**
 * Represents an available background ambient sound for meditation timer.
 *
 * @property id Unique identifier for the sound (used for persistence)
 * @property nameEnglish English display name
 * @property nameGerman German display name
 * @property descriptionEnglish English description
 * @property descriptionGerman German description
 * @property rawResourceName Raw resource name for the audio file (empty string for silent)
 */
data class BackgroundSound(
    val id: String,
    val nameEnglish: String,
    val nameGerman: String,
    val descriptionEnglish: String,
    val descriptionGerman: String,
    val rawResourceName: String
) {
    /** True if this sound produces no audio output. */
    val isSilent: Boolean
        get() = rawResourceName.isEmpty()

    companion object {
        /** ID for the silent option (no audio). */
        const val SILENT_ID = "silent"
    }
}
