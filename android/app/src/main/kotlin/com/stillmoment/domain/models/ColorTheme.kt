package com.stillmoment.domain.models

/**
 * Represents the available color themes in the app.
 * Single source of truth for theme names used by both UI and persistence.
 *
 * @property name The stable enum name used for DataStore persistence
 */
enum class ColorTheme {
    CANDLELIGHT,
    FOREST,
    MOON;

    companion object {
        /** Default theme shown on first app launch */
        val DEFAULT = CANDLELIGHT

        /**
         * Parse a persisted string to ColorTheme, returning DEFAULT for unknown values.
         */
        fun fromString(value: String?): ColorTheme = entries.find { it.name == value } ?: DEFAULT
    }
}
