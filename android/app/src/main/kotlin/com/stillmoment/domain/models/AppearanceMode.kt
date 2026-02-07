package com.stillmoment.domain.models

/**
 * Represents the user's preferred appearance mode.
 * Controls whether the app follows the system dark/light setting or forces one.
 *
 * @property isDark Resolved dark theme preference: null = follow system, false = light, true = dark
 */
enum class AppearanceMode(val isDark: Boolean?) {
    SYSTEM(isDark = null),
    LIGHT(isDark = false),
    DARK(isDark = true);

    companion object {
        /** Default appearance mode: follow system setting */
        val DEFAULT = SYSTEM

        /**
         * Parse a persisted string to AppearanceMode, returning DEFAULT for unknown values.
         */
        fun fromString(value: String?): AppearanceMode = entries.find { it.name == value } ?: DEFAULT
    }
}
