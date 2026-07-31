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
        /**
         * Appearance for installs without a stored selection.
         *
         * Dark on purpose (shared-122): the dark presentation carries the calm the app is
         * about and matches how the app is shown in the store. Users who never picked an
         * appearance themselves - including existing users updating the app - move to dark;
         * switching back is a single tap in the settings.
         *
         * This is the single source of truth: [fromString] falls back to it, and both
         * `collectAsState` call sites use it as their initial value.
         */
        val DEFAULT = DARK

        /**
         * Parse a persisted string to AppearanceMode, returning DEFAULT for unknown values.
         */
        fun fromString(value: String?): AppearanceMode = entries.find { it.name == value } ?: DEFAULT
    }
}
