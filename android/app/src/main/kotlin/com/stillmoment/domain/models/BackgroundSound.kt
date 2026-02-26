package com.stillmoment.domain.models

import java.util.Locale

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
    /** Returns the localized name based on current device locale. */
    val localizedName: String
        get() = when (Locale.getDefault().language) {
            "de" -> nameGerman
            else -> nameEnglish
        }

    /** Returns the localized description based on current device locale. */
    val localizedDescription: String
        get() = when (Locale.getDefault().language) {
            "de" -> descriptionGerman
            else -> descriptionEnglish
        }

    /** True if this sound produces no audio output. */
    val isSilent: Boolean
        get() = rawResourceName.isEmpty()

    companion object {
        /** ID for the silent option (no audio). */
        const val SILENT_ID = "silent"

        /** All available background sounds. */
        val allSounds: List<BackgroundSound> = listOf(
            BackgroundSound(
                id = SILENT_ID,
                nameEnglish = "Silence",
                nameGerman = "Stille",
                descriptionEnglish = "Meditate in silence.",
                descriptionGerman = "Meditiere in Stille.",
                rawResourceName = ""
            ),
            BackgroundSound(
                id = "forest",
                nameEnglish = "Forest Ambience",
                nameGerman = "Waldatmosphäre",
                descriptionEnglish = "Natural forest sounds",
                descriptionGerman = "Natürliche Waldgeräusche",
                rawResourceName = "forest_ambience"
            )
        )

        /**
         * Find a background sound by ID.
         * @return The matching BackgroundSound or null if not found
         */
        fun find(id: String): BackgroundSound? = allSounds.find { it.id == id }

        /**
         * Find a background sound by ID, returning silent if not found.
         * @return The matching BackgroundSound or the silent option if not found
         */
        fun findOrDefault(id: String): BackgroundSound = find(id) ?: allSounds.first()
    }
}
