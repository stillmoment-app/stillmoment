package com.stillmoment.domain.models

/**
 * Settings for meditation sessions.
 *
 * @property intervalGongsEnabled Whether interval gongs are enabled during meditation
 * @property intervalMinutes Interval in minutes between gongs (3, 5, or 10)
 * @property backgroundSoundId Background sound ID (references BackgroundSound.id)
 * @property durationMinutes Duration of meditation in minutes (1-60)
 */
data class MeditationSettings(
    val intervalGongsEnabled: Boolean = false,
    val intervalMinutes: Int = DEFAULT_INTERVAL_MINUTES,
    val backgroundSoundId: String = DEFAULT_BACKGROUND_SOUND_ID,
    val durationMinutes: Int = DEFAULT_DURATION_MINUTES
) {
    init {
        // Validation is applied through copy() and create() methods
        // Direct construction allows any values for flexibility in deserialization
    }

    companion object {
        const val DEFAULT_INTERVAL_MINUTES = 5
        const val DEFAULT_BACKGROUND_SOUND_ID = "silent"
        const val DEFAULT_DURATION_MINUTES = 10

        // Valid interval options
        val VALID_INTERVALS = listOf(3, 5, 10)

        /** Default settings with interval gongs disabled and silent background audio */
        val Default = MeditationSettings()

        /**
         * Validates and clamps interval to valid values (3, 5, or 10).
         */
        fun validateInterval(minutes: Int): Int {
            return when {
                minutes <= 3 -> 3
                minutes <= 7 -> 5
                else -> 10
            }
        }

        /**
         * Validates and clamps duration to valid range (1-60 minutes).
         */
        fun validateDuration(minutes: Int): Int {
            return minutes.coerceIn(1, 60)
        }

        /**
         * Migrates legacy BackgroundAudioMode enum to sound ID.
         *
         * @param mode Legacy enum value
         * @return Corresponding sound ID
         */
        fun migrateLegacyMode(mode: String): String {
            return when (mode) {
                "Silent" -> "silent"
                "White Noise" -> "silent" // WhiteNoise removed, fallback to silent
                else -> "silent"
            }
        }

        /**
         * Creates settings with validated values.
         */
        fun create(
            intervalGongsEnabled: Boolean = false,
            intervalMinutes: Int = DEFAULT_INTERVAL_MINUTES,
            backgroundSoundId: String = DEFAULT_BACKGROUND_SOUND_ID,
            durationMinutes: Int = DEFAULT_DURATION_MINUTES
        ): MeditationSettings {
            return MeditationSettings(
                intervalGongsEnabled = intervalGongsEnabled,
                intervalMinutes = validateInterval(intervalMinutes),
                backgroundSoundId = backgroundSoundId,
                durationMinutes = validateDuration(durationMinutes)
            )
        }
    }

    /**
     * Returns a copy with validated interval minutes.
     */
    fun withIntervalMinutes(minutes: Int): MeditationSettings {
        return copy(intervalMinutes = validateInterval(minutes))
    }

    /**
     * Returns a copy with validated duration minutes.
     */
    fun withDurationMinutes(minutes: Int): MeditationSettings {
        return copy(durationMinutes = validateDuration(minutes))
    }
}

/**
 * Persistence keys for MeditationSettings.
 * Used with DataStore for storing settings.
 */
object MeditationSettingsKeys {
    const val INTERVAL_GONGS_ENABLED = "intervalGongsEnabled"
    const val INTERVAL_MINUTES = "intervalMinutes"
    const val BACKGROUND_SOUND_ID = "backgroundSoundId"
    const val DURATION_MINUTES = "durationMinutes"

    // Legacy key for migration
    const val LEGACY_BACKGROUND_AUDIO_MODE = "backgroundAudioMode"
}
