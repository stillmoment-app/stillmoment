package com.stillmoment.domain.models

/**
 * Settings for meditation sessions.
 *
 * @property intervalGongsEnabled Whether interval gongs are enabled during meditation
 * @property intervalMinutes Interval in minutes between gongs (3, 5, or 10)
 * @property backgroundSoundId Background sound ID (references BackgroundSound.id)
 * @property durationMinutes Duration of meditation in minutes (1-60)
 * @property preparationTimeEnabled Whether preparation time before meditation is enabled
 * @property preparationTimeSeconds Duration of preparation in seconds (5, 10, 15, 20, 30, or 45)
 * @property gongSoundId ID of the gong sound for start/end (references GongSound.id)
 */
data class MeditationSettings(
    val intervalGongsEnabled: Boolean = false,
    val intervalMinutes: Int = DEFAULT_INTERVAL_MINUTES,
    val backgroundSoundId: String = DEFAULT_BACKGROUND_SOUND_ID,
    val durationMinutes: Int = DEFAULT_DURATION_MINUTES,
    val preparationTimeEnabled: Boolean = DEFAULT_PREPARATION_TIME_ENABLED,
    val preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME_SECONDS,
    val gongSoundId: String = DEFAULT_GONG_SOUND_ID
) {
    init {
        // Validation is applied through copy() and create() methods
        // Direct construction allows any values for flexibility in deserialization
    }

    companion object {
        const val DEFAULT_INTERVAL_MINUTES = 5
        const val DEFAULT_BACKGROUND_SOUND_ID = "silent"
        const val DEFAULT_DURATION_MINUTES = 10
        const val DEFAULT_PREPARATION_TIME_ENABLED = true
        const val DEFAULT_PREPARATION_TIME_SECONDS = 15
        const val DEFAULT_GONG_SOUND_ID = GongSound.DEFAULT_SOUND_ID

        // Valid interval options
        private const val INTERVAL_SHORT = 3
        private const val INTERVAL_MEDIUM = 5
        private const val INTERVAL_LONG = 10

        // Thresholds for interval validation
        private const val INTERVAL_THRESHOLD_SHORT = 3
        private const val INTERVAL_THRESHOLD_MEDIUM = 7

        val VALID_INTERVALS = listOf(INTERVAL_SHORT, INTERVAL_MEDIUM, INTERVAL_LONG)

        // Valid preparation time options (in seconds)
        val VALID_PREPARATION_TIMES = listOf(5, 10, 15, 20, 30, 45)

        /** Default settings with interval gongs disabled and silent background audio */
        val Default = MeditationSettings()

        /**
         * Validates and clamps interval to valid values (3, 5, or 10).
         */
        fun validateInterval(minutes: Int): Int {
            return when {
                minutes <= INTERVAL_THRESHOLD_SHORT -> INTERVAL_SHORT
                minutes <= INTERVAL_THRESHOLD_MEDIUM -> INTERVAL_MEDIUM
                else -> INTERVAL_LONG
            }
        }

        /**
         * Validates and clamps duration to valid range (1-60 minutes).
         */
        fun validateDuration(minutes: Int): Int {
            return minutes.coerceIn(1, 60)
        }

        /**
         * Validates and clamps preparation time to nearest valid value (5, 10, 15, 20, 30, or 45).
         */
        fun validatePreparationTime(seconds: Int): Int {
            return VALID_PREPARATION_TIMES.minByOrNull { kotlin.math.abs(it - seconds) }
                ?: DEFAULT_PREPARATION_TIME_SECONDS
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
            durationMinutes: Int = DEFAULT_DURATION_MINUTES,
            preparationTimeEnabled: Boolean = DEFAULT_PREPARATION_TIME_ENABLED,
            preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME_SECONDS,
            gongSoundId: String = DEFAULT_GONG_SOUND_ID
        ): MeditationSettings {
            return MeditationSettings(
                intervalGongsEnabled = intervalGongsEnabled,
                intervalMinutes = validateInterval(intervalMinutes),
                backgroundSoundId = backgroundSoundId,
                durationMinutes = validateDuration(durationMinutes),
                preparationTimeEnabled = preparationTimeEnabled,
                preparationTimeSeconds = validatePreparationTime(preparationTimeSeconds),
                gongSoundId = gongSoundId
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

    /**
     * Returns a copy with validated preparation time seconds.
     */
    fun withPreparationTimeSeconds(seconds: Int): MeditationSettings {
        return copy(preparationTimeSeconds = validatePreparationTime(seconds))
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
    const val PREPARATION_TIME_ENABLED = "preparationTimeEnabled"
    const val PREPARATION_TIME_SECONDS = "preparationTimeSeconds"
    const val GONG_SOUND_ID = "gongSoundId"

    // Legacy key for migration
    const val LEGACY_BACKGROUND_AUDIO_MODE = "backgroundAudioMode"
}
