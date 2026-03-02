package com.stillmoment.domain.models

/**
 * Settings for meditation sessions.
 *
 * @property intervalGongsEnabled Whether interval gongs are enabled during meditation
 * @property intervalMinutes Interval in minutes between gongs (1-60)
 * @property intervalMode How interval gongs are triggered (REPEATING, AFTER_START, BEFORE_END)
 * @property intervalSoundId ID of the sound for interval gongs (references GongSound.id, including "soft-interval")
 * @property intervalGongVolume Volume for interval gong sounds (0.0 to 1.0)
 * @property backgroundSoundId Background sound ID (references BackgroundSound.id)
 * @property durationMinutes Duration of meditation in minutes (1-60)
 * @property preparationTimeEnabled Whether preparation time before meditation is enabled
 * @property preparationTimeSeconds Duration of preparation in seconds (5, 10, 15, 20, 30, or 45)
 * @property gongSoundId ID of the gong sound for start/end (references GongSound.id)
 * @property gongVolume Volume for start/end gong sounds (0.0 to 1.0)
 * @property introductionEnabled Whether introduction audio is enabled
 */
data class MeditationSettings(
    val intervalGongsEnabled: Boolean = false,
    val intervalMinutes: Int = DEFAULT_INTERVAL_MINUTES,
    val intervalMode: IntervalMode = DEFAULT_INTERVAL_MODE,
    val intervalSoundId: String = DEFAULT_INTERVAL_SOUND_ID,
    val intervalGongVolume: Float = DEFAULT_INTERVAL_GONG_VOLUME,
    val backgroundSoundId: String = DEFAULT_BACKGROUND_SOUND_ID,
    val backgroundSoundVolume: Float = DEFAULT_BACKGROUND_SOUND_VOLUME,
    val durationMinutes: Int = DEFAULT_DURATION_MINUTES,
    val preparationTimeEnabled: Boolean = DEFAULT_PREPARATION_TIME_ENABLED,
    val preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME_SECONDS,
    val gongSoundId: String = DEFAULT_GONG_SOUND_ID,
    val gongVolume: Float = DEFAULT_GONG_VOLUME,
    val introductionId: String? = null,
    val introductionEnabled: Boolean = DEFAULT_INTRODUCTION_ENABLED
) {
    init {
        // Validation is applied through copy() and create() methods
        // Direct construction allows any values for flexibility in deserialization
    }

    companion object {
        const val DEFAULT_INTERVAL_MINUTES = 5
        val DEFAULT_INTERVAL_MODE = IntervalMode.REPEATING
        const val DEFAULT_INTERVAL_SOUND_ID = GongSound.SOFT_INTERVAL_SOUND_ID
        const val DEFAULT_INTERVAL_GONG_VOLUME = 0.75f
        const val DEFAULT_BACKGROUND_SOUND_ID = "silent"
        const val DEFAULT_BACKGROUND_SOUND_VOLUME = 0.15f
        const val DEFAULT_DURATION_MINUTES = 10
        const val DEFAULT_PREPARATION_TIME_ENABLED = true
        const val DEFAULT_PREPARATION_TIME_SECONDS = 15
        const val DEFAULT_GONG_SOUND_ID = GongSound.DEFAULT_SOUND_ID
        const val DEFAULT_GONG_VOLUME = 1.0f
        const val DEFAULT_INTRODUCTION_ENABLED = false

        /** Minimum interval in minutes */
        const val MIN_INTERVAL_MINUTES = 1

        /** Maximum interval in minutes */
        const val MAX_INTERVAL_MINUTES = 60

        // Valid preparation time options (in seconds)
        val VALID_PREPARATION_TIMES = listOf(5, 10, 15, 20, 30, 45)

        /** Default settings with interval gongs disabled and silent background audio */
        val Default = MeditationSettings()

        /**
         * Validates and clamps interval to valid range (1-60 minutes).
         */
        fun validateInterval(minutes: Int): Int {
            return minutes.coerceIn(MIN_INTERVAL_MINUTES, MAX_INTERVAL_MINUTES)
        }

        /**
         * Validates and clamps duration to valid range (1-60 minutes).
         * When an introductionId is provided and introduction is enabled,
         * enforces a minimum based on introduction duration.
         */
        fun validateDuration(minutes: Int, introductionId: String? = null, introductionEnabled: Boolean = false): Int {
            val min = minimumDuration(introductionId, introductionEnabled)
            return minutes.coerceIn(min, 60)
        }

        /**
         * Returns the minimum meditation duration in minutes for a given active introduction ID.
         * [activeIntroductionId] is `null` when disabled or unset — callers use [MeditationSettings.activeIntroductionId].
         * Formula: ceil(introDuration / 60) + 1 — ensures at least 1 minute of silent meditation.
         */
        fun minimumDuration(activeIntroductionId: String?): Int {
            val intro = activeIntroductionId?.let { Introduction.find(it) } ?: return 1
            return kotlin.math.ceil(intro.durationSeconds / 60.0).toInt() + 1
        }

        /**
         * Backward-compatible overload used during init/validation where enabled and id are separate.
         */
        fun minimumDuration(introductionId: String? = null, introductionEnabled: Boolean = false): Int {
            val activeId = if (introductionEnabled) introductionId else null
            return minimumDuration(activeIntroductionId = activeId)
        }

        /**
         * Validates and clamps preparation time to nearest valid value (5, 10, 15, 20, 30, or 45).
         */
        fun validatePreparationTime(seconds: Int): Int {
            return VALID_PREPARATION_TIMES.minByOrNull { kotlin.math.abs(it - seconds) }
                ?: DEFAULT_PREPARATION_TIME_SECONDS
        }

        /**
         * Validates and clamps volume to valid range (0.0-1.0).
         */
        fun validateVolume(volume: Float): Float {
            return volume.coerceIn(0f, 1f)
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
            intervalMode: IntervalMode = DEFAULT_INTERVAL_MODE,
            intervalSoundId: String = DEFAULT_INTERVAL_SOUND_ID,
            intervalGongVolume: Float = DEFAULT_INTERVAL_GONG_VOLUME,
            backgroundSoundId: String = DEFAULT_BACKGROUND_SOUND_ID,
            backgroundSoundVolume: Float = DEFAULT_BACKGROUND_SOUND_VOLUME,
            durationMinutes: Int = DEFAULT_DURATION_MINUTES,
            preparationTimeEnabled: Boolean = DEFAULT_PREPARATION_TIME_ENABLED,
            preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME_SECONDS,
            gongSoundId: String = DEFAULT_GONG_SOUND_ID,
            gongVolume: Float = DEFAULT_GONG_VOLUME,
            introductionId: String? = null,
            introductionEnabled: Boolean = DEFAULT_INTRODUCTION_ENABLED
        ): MeditationSettings {
            return MeditationSettings(
                intervalGongsEnabled = intervalGongsEnabled,
                intervalMinutes = validateInterval(intervalMinutes),
                intervalMode = intervalMode,
                intervalSoundId = intervalSoundId,
                intervalGongVolume = validateVolume(intervalGongVolume),
                backgroundSoundId = backgroundSoundId,
                backgroundSoundVolume = validateVolume(backgroundSoundVolume),
                durationMinutes = validateDuration(durationMinutes, introductionId, introductionEnabled),
                preparationTimeEnabled = preparationTimeEnabled,
                preparationTimeSeconds = validatePreparationTime(preparationTimeSeconds),
                gongSoundId = gongSoundId,
                gongVolume = validateVolume(gongVolume),
                introductionId = introductionId,
                introductionEnabled = introductionEnabled
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
     * The effective introduction ID. `null` when disabled or no introduction is selected.
     * Use this instead of checking [introductionEnabled] + [introductionId] manually.
     */
    val activeIntroductionId: String?
        get() = if (introductionEnabled) introductionId else null

    /**
     * Returns the minimum duration in minutes based on the current introduction setting.
     */
    val minimumDurationMinutes: Int
        get() = minimumDuration(activeIntroductionId = activeIntroductionId)

    /**
     * Returns a copy with validated duration minutes (respects introduction minimum).
     */
    fun withDurationMinutes(minutes: Int): MeditationSettings {
        return copy(durationMinutes = validateDuration(minutes, introductionId, introductionEnabled))
    }

    /**
     * Returns a copy with the introduction enabled or disabled.
     */
    fun withIntroductionEnabled(enabled: Boolean): MeditationSettings {
        return copy(introductionEnabled = enabled)
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
    const val INTERVAL_MODE = "intervalMode"
    const val INTERVAL_SOUND_ID = "intervalSoundId"
    const val INTERVAL_GONG_VOLUME = "intervalGongVolume"
    const val BACKGROUND_SOUND_ID = "backgroundSoundId"
    const val BACKGROUND_SOUND_VOLUME = "backgroundSoundVolume"
    const val DURATION_MINUTES = "durationMinutes"
    const val PREPARATION_TIME_ENABLED = "preparationTimeEnabled"
    const val PREPARATION_TIME_SECONDS = "preparationTimeSeconds"
    const val GONG_SOUND_ID = "gongSoundId"
    const val GONG_VOLUME = "gongVolume"
    const val INTRODUCTION_ID = "introductionId"
    const val INTRODUCTION_ENABLED = "introductionEnabled"

    // Legacy keys for migration
    const val LEGACY_BACKGROUND_AUDIO_MODE = "backgroundAudioMode"
    const val LEGACY_INTERVAL_REPEATING = "interval_repeating"
    const val LEGACY_INTERVAL_FROM_END = "interval_from_end"
}
