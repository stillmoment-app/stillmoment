package com.stillmoment.domain.models

import com.stillmoment.R
import java.util.Locale

/**
 * Represents a configurable gong sound for meditation timer.
 *
 * This model defines a gong sound that can be selected for start/end gong
 * or interval gong. Sounds include:
 * - Unique identifier for persistence
 * - Audio resource reference
 * - Localized name (German + English)
 *
 * @property id Unique identifier for the sound (used for persistence)
 * @property nameEnglish English display name
 * @property nameGerman German display name
 * @property rawResId Raw resource ID for the audio file
 */
data class GongSound(
    val id: String,
    val nameEnglish: String,
    val nameGerman: String,
    val rawResId: Int
) {
    /**
     * Returns the localized name based on current device locale.
     */
    val localizedName: String
        get() = when (Locale.getDefault().language) {
            "de" -> nameGerman
            else -> nameEnglish
        }

    companion object {
        /** Default gong sound ID */
        const val DEFAULT_SOUND_ID = "temple-bell"

        /** All available gong sounds */
        val allSounds: List<GongSound> = listOf(
            GongSound(
                id = "classic-bowl",
                nameEnglish = "Classic Bowl",
                nameGerman = "Klassisch",
                rawResId = R.raw.gong_classic_bowl
            ),
            GongSound(
                id = "deep-resonance",
                nameEnglish = "Deep Resonance",
                nameGerman = "Tiefe Resonanz",
                rawResId = R.raw.gong_deep_resonance
            ),
            GongSound(
                id = "clear-strike",
                nameEnglish = "Clear Strike",
                nameGerman = "Klarer Anschlag",
                rawResId = R.raw.gong_clear_strike
            ),
            GongSound(
                id = "temple-bell",
                nameEnglish = "Temple Bell",
                nameGerman = "Tempelglocke",
                rawResId = R.raw.gong_temple_bell
            )
        )

        /** Default gong sound (Temple Bell) */
        val defaultSound: GongSound = allSounds.first { it.id == DEFAULT_SOUND_ID }

        /**
         * Find a gong sound by ID.
         *
         * @param id The sound ID to search for
         * @return The matching GongSound or null if not found
         */
        fun find(id: String): GongSound? = allSounds.find { it.id == id }

        /**
         * Find a gong sound by ID, returning default if not found.
         *
         * @param id The sound ID to search for
         * @return The matching GongSound or defaultSound if not found
         */
        fun findOrDefault(id: String): GongSound = find(id) ?: defaultSound
    }
}
