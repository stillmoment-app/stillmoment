package com.stillmoment.domain.models

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
 * @property rawResourceName Raw resource name for the audio file (e.g., "gong_temple_bell")
 */
data class GongSound(
    val id: String,
    val nameEnglish: String,
    val nameGerman: String,
    val rawResourceName: String
) {
    companion object {
        /** Default gong sound ID */
        const val DEFAULT_SOUND_ID = "temple-bell"

        /** ID for the soft interval tone (uses existing interval.mp3) */
        const val SOFT_INTERVAL_SOUND_ID = "soft-interval"

        /** ID for vibration signal (no audio — device vibration) */
        const val VIBRATION_ID = "vibration"

        private val vibrationSound = GongSound(
            id = VIBRATION_ID,
            nameEnglish = "Vibration",
            nameGerman = "Vibration",
            rawResourceName = ""
        )

        /** All available gong sounds (for start/end gong selection) */
        val allSounds: List<GongSound> = listOf(
            GongSound(
                id = "temple-bell",
                nameEnglish = "Temple Bell",
                nameGerman = "Tempelglocke",
                rawResourceName = "gong_temple_bell"
            ),
            GongSound(
                id = "classic-bowl",
                nameEnglish = "Classic Bowl",
                nameGerman = "Klassisch",
                rawResourceName = "gong_classic_bowl"
            ),
            GongSound(
                id = "deep-resonance",
                nameEnglish = "Deep Resonance",
                nameGerman = "Tiefe Resonanz",
                rawResourceName = "gong_deep_resonance"
            ),
            GongSound(
                id = "clear-strike",
                nameEnglish = "Clear Strike",
                nameGerman = "Klarer Anschlag",
                rawResourceName = "gong_clear_strike"
            ),
            vibrationSound
        )

        /** All available interval sounds (soft interval tone first, then allSounds, vibration last) */
        val allIntervalSounds: List<GongSound> = listOf(
            GongSound(
                id = SOFT_INTERVAL_SOUND_ID,
                nameEnglish = "Soft Interval Tone",
                nameGerman = "Sanfter Intervallton",
                rawResourceName = "interval"
            ),
            GongSound(
                id = "temple-bell",
                nameEnglish = "Temple Bell",
                nameGerman = "Tempelglocke",
                rawResourceName = "gong_temple_bell"
            ),
            GongSound(
                id = "classic-bowl",
                nameEnglish = "Classic Bowl",
                nameGerman = "Klassisch",
                rawResourceName = "gong_classic_bowl"
            ),
            GongSound(
                id = "deep-resonance",
                nameEnglish = "Deep Resonance",
                nameGerman = "Tiefe Resonanz",
                rawResourceName = "gong_deep_resonance"
            ),
            GongSound(
                id = "clear-strike",
                nameEnglish = "Clear Strike",
                nameGerman = "Klarer Anschlag",
                rawResourceName = "gong_clear_strike"
            ),
            vibrationSound
        )

        /** Default gong sound (Temple Bell) */
        val defaultSound: GongSound = allSounds.first { it.id == DEFAULT_SOUND_ID }

        /**
         * Find a gong sound by ID (searches all sounds including interval-only sounds).
         *
         * @param id The sound ID to search for
         * @return The matching GongSound or null if not found
         */
        fun find(id: String): GongSound? = allIntervalSounds.find { it.id == id }

        /**
         * Find a gong sound by ID, returning default if not found.
         *
         * @param id The sound ID to search for
         * @return The matching GongSound or defaultSound if not found
         */
        fun findOrDefault(id: String): GongSound = find(id) ?: defaultSound
    }
}
