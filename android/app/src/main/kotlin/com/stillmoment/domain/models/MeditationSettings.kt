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
 * @property attunementEnabled Whether attunement audio is enabled
 * @property customAttunementDurationSeconds Duration of custom attunement in seconds (sync resolution path).
 *   Populated by TimerViewModel from CustomAudioRepository when converting Praxis to MeditationSettings.
 *   Built-in attunements use [Attunement.find] instead (no need for this field).
 *   The async resolution path (Resolver) provides the duration for UI display independently.
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
    val attunementId: String? = null,
    val attunementEnabled: Boolean = DEFAULT_ATTUNEMENT_ENABLED,
    val customAttunementDurationSeconds: Int? = null
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
        const val DEFAULT_ATTUNEMENT_ENABLED = false

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
         * When an attunementId is provided and attunement is enabled,
         * enforces a minimum based on attunement duration.
         */
        fun validateDuration(
            minutes: Int,
            attunementId: String? = null,
            attunementEnabled: Boolean = false,
            customAttunementDurationSeconds: Int? = null,
        ): Int {
            val min = minimumDuration(attunementId, attunementEnabled, customAttunementDurationSeconds)
            return minutes.coerceIn(min, 60)
        }

        /**
         * Returns the minimum meditation duration in minutes for a given active attunement ID.
         * [activeAttunementId] is `null` when disabled or unset — callers use [MeditationSettings.activeAttunementId].
         * When [customAttunementDurationSeconds] is provided, it is used instead of looking up built-in attunements.
         * Formula: ceil(attunementDuration / 60)
         */
        fun minimumDuration(activeAttunementId: String?, customAttunementDurationSeconds: Int? = null): Int {
            if (activeAttunementId == null) return 1
            val durationSeconds = when {
                customAttunementDurationSeconds != null -> customAttunementDurationSeconds
                else -> Attunement.find(activeAttunementId)?.durationSeconds ?: return 1
            }
            if (durationSeconds <= 0) return 1
            return kotlin.math.ceil(durationSeconds / 60.0).toInt()
        }

        /**
         * Backward-compatible overload used during init/validation where enabled and id are separate.
         */
        fun minimumDuration(
            attunementId: String? = null,
            attunementEnabled: Boolean = false,
            customAttunementDurationSeconds: Int? = null,
        ): Int {
            val activeId = if (attunementEnabled) attunementId else null
            return minimumDuration(
                activeAttunementId = activeId,
                customAttunementDurationSeconds = customAttunementDurationSeconds,
            )
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
            attunementId: String? = null,
            attunementEnabled: Boolean = DEFAULT_ATTUNEMENT_ENABLED,
            customAttunementDurationSeconds: Int? = null
        ): MeditationSettings {
            return MeditationSettings(
                intervalGongsEnabled = intervalGongsEnabled,
                intervalMinutes = validateInterval(intervalMinutes),
                intervalMode = intervalMode,
                intervalSoundId = intervalSoundId,
                intervalGongVolume = validateVolume(intervalGongVolume),
                backgroundSoundId = backgroundSoundId,
                backgroundSoundVolume = validateVolume(backgroundSoundVolume),
                durationMinutes = validateDuration(
                    durationMinutes,
                    attunementId,
                    attunementEnabled,
                    customAttunementDurationSeconds,
                ),
                preparationTimeEnabled = preparationTimeEnabled,
                preparationTimeSeconds = validatePreparationTime(preparationTimeSeconds),
                gongSoundId = gongSoundId,
                gongVolume = validateVolume(gongVolume),
                attunementId = attunementId,
                attunementEnabled = attunementEnabled,
                customAttunementDurationSeconds = customAttunementDurationSeconds
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
     * The effective attunement ID. `null` when disabled or no attunement is selected.
     * Use this instead of checking [attunementEnabled] + [attunementId] manually.
     */
    val activeAttunementId: String?
        get() = if (attunementEnabled) attunementId else null

    /**
     * Whether an active attunement is configured and available.
     * Returns true for custom attunements (when [customAttunementDurationSeconds] is set)
     * AND for built-in attunements (when available for current language).
     */
    val hasActiveAttunement: Boolean
        get() {
            if (!attunementEnabled) return false
            attunementId ?: return false
            // Custom attunement: customAttunementDurationSeconds is set
            if (customAttunementDurationSeconds != null) return true
            // Built-in: check language availability
            return Attunement.isAvailableForCurrentLanguage(attunementId)
        }

    /**
     * The effective attunement duration in seconds.
     * Returns [customAttunementDurationSeconds] for custom attunements, or the built-in duration
     * for standard attunements. Returns 0 if no active attunement.
     */
    val effectiveAttunementDurationSeconds: Int
        get() {
            if (!hasActiveAttunement) return 0
            // Custom attunement duration
            customAttunementDurationSeconds?.let { return it }
            // Built-in duration
            val id = attunementId ?: return 0
            return Attunement.find(id)?.durationSeconds ?: 0
        }

    /**
     * Returns the minimum duration in minutes based on the current attunement setting.
     * Uses [customAttunementDurationSeconds] when set (for custom attunements).
     */
    val minimumDurationMinutes: Int
        get() = minimumDuration(
            activeAttunementId = activeAttunementId,
            customAttunementDurationSeconds = customAttunementDurationSeconds
        )

    /**
     * Returns a copy with validated duration minutes (respects attunement minimum).
     * Uses [customAttunementDurationSeconds] when set (for custom attunements).
     */
    fun withDurationMinutes(minutes: Int): MeditationSettings {
        return copy(
            durationMinutes = validateDuration(
                minutes,
                attunementId,
                attunementEnabled,
                customAttunementDurationSeconds,
            )
        )
    }

    /**
     * Returns a copy with the attunement enabled or disabled.
     */
    fun withAttunementEnabled(enabled: Boolean): MeditationSettings {
        return copy(attunementEnabled = enabled)
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
    const val ATTUNEMENT_ID = "introductionId"
    const val ATTUNEMENT_ENABLED = "introductionEnabled"

    // Legacy keys for migration
    const val LEGACY_BACKGROUND_AUDIO_MODE = "backgroundAudioMode"
    const val LEGACY_INTERVAL_REPEATING = "interval_repeating"
    const val LEGACY_INTERVAL_FROM_END = "interval_from_end"
}
