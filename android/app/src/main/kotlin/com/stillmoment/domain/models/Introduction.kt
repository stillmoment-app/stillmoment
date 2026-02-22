package com.stillmoment.domain.models

import java.util.Locale

/**
 * Represents an optional introduction audio that plays at the beginning of a meditation session.
 *
 * Introductions are bundled audio files (e.g., guided breathing exercises) that play
 * after the start gong and before the silent meditation phase. They are language-specific
 * and can be configured in the timer settings.
 *
 * @property id Unique, language-independent identifier (e.g., "breath")
 * @property nameEnglish English display name
 * @property nameGerman German display name
 * @property durationSeconds Duration of the introduction audio in seconds
 * @property availableLanguages Languages for which audio files are available
 * @property filenamePattern Pattern with {lang} placeholder for language-specific audio files
 */
data class Introduction(
    val id: String,
    val nameEnglish: String,
    val nameGerman: String,
    val durationSeconds: Int,
    val availableLanguages: List<String>,
    val filenamePattern: String
) {
    /**
     * Returns the localized name based on current device locale.
     */
    val localizedName: String
        get() = when (currentLanguage) {
            "de" -> nameGerman
            else -> nameEnglish
        }

    /**
     * Returns the audio resource filename for the given language.
     *
     * @param language Language code (e.g., "de")
     * @return Resource filename or null if language not available
     */
    fun audioFilename(language: String): String? {
        if (!availableLanguages.contains(language)) return null
        return filenamePattern.replace("{lang}", language)
    }

    /**
     * Formatted duration string (e.g., "1:35").
     */
    val formattedDuration: String
        get() {
            val minutes = durationSeconds / 60
            val seconds = durationSeconds % 60
            return String.format(Locale.ROOT, "%d:%02d", minutes, seconds)
        }

    companion object {
        /** Override for testing — set to a language code to bypass Locale.getDefault(). */
        var languageOverride: String? = null

        /** Returns the current device language code (or test override). */
        val currentLanguage: String
            get() = languageOverride ?: Locale.getDefault().language

        /** All registered introductions. */
        val allIntroductions: List<Introduction> = listOf(
            Introduction(
                id = "breath",
                nameEnglish = "Breathing Exercise",
                nameGerman = "Atemübung",
                durationSeconds = 95,
                availableLanguages = listOf("de"),
                filenamePattern = "intro_breath_{lang}"
            )
        )

        /**
         * Returns introductions available for the current device language.
         */
        fun availableForCurrentLanguage(): List<Introduction> {
            val lang = currentLanguage
            return allIntroductions.filter { it.availableLanguages.contains(lang) }
        }

        /**
         * Checks if any introductions are available for the current device language.
         */
        val hasAvailableIntroductions: Boolean
            get() = availableForCurrentLanguage().isNotEmpty()

        /**
         * Finds an introduction by ID.
         *
         * @param id The introduction ID to search for
         * @return The matching Introduction or null
         */
        fun find(id: String): Introduction? = allIntroductions.find { it.id == id }

        /**
         * Checks if an introduction is available for the current device language.
         *
         * @param id The introduction ID to check
         * @return true if the introduction exists and has audio for the current language
         */
        fun isAvailableForCurrentLanguage(id: String): Boolean {
            val intro = find(id) ?: return false
            return intro.availableLanguages.contains(currentLanguage)
        }

        /**
         * Returns the audio resource filename for an introduction in the current device language.
         *
         * @param id The introduction ID
         * @return Resource filename or null if not available
         */
        fun audioFilenameForCurrentLanguage(id: String): String? {
            val intro = find(id) ?: return null
            return intro.audioFilename(currentLanguage)
        }
    }
}
