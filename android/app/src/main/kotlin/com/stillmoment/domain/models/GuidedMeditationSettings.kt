package com.stillmoment.domain.models

/**
 * Settings for guided meditation playback.
 *
 * Immutable Value Object following DDD principles.
 *
 * @property preparationTimeEnabled Whether preparation time before playback is enabled
 * @property preparationTimeSeconds Duration of preparation time in seconds (5, 10, 15, 20, 30, or 45)
 */
data class GuidedMeditationSettings(
    val preparationTimeEnabled: Boolean = DEFAULT_PREPARATION_TIME_ENABLED,
    val preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME_SECONDS
) {
    /**
     * Returns the effective preparation time in seconds, or null if disabled.
     * Use this to determine whether to show countdown before playback.
     */
    val effectivePreparationTimeSeconds: Int?
        get() = if (preparationTimeEnabled) preparationTimeSeconds else null

    /**
     * Returns a copy with the preparation time enabled/disabled.
     */
    fun withPreparationTimeEnabled(enabled: Boolean): GuidedMeditationSettings {
        return copy(preparationTimeEnabled = enabled)
    }

    /**
     * Returns a copy with validated preparation time seconds.
     */
    fun withPreparationTimeSeconds(seconds: Int): GuidedMeditationSettings {
        return copy(preparationTimeSeconds = validatePreparationTime(seconds))
    }

    companion object {
        const val DEFAULT_PREPARATION_TIME_ENABLED = false
        const val DEFAULT_PREPARATION_TIME_SECONDS = 15

        /** Valid preparation time options (in seconds) */
        val VALID_PREPARATION_TIMES = listOf(5, 10, 15, 20, 30, 45)

        /** Default settings with preparation time disabled */
        val Default = GuidedMeditationSettings()

        /**
         * Validates and clamps preparation time to nearest valid value.
         */
        fun validatePreparationTime(seconds: Int): Int {
            return VALID_PREPARATION_TIMES.minByOrNull { kotlin.math.abs(it - seconds) }
                ?: DEFAULT_PREPARATION_TIME_SECONDS
        }
    }
}
