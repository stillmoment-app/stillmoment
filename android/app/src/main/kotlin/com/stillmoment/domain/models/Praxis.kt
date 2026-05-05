package com.stillmoment.domain.models

import java.util.UUID
import kotlin.math.abs
import kotlinx.serialization.Serializable

/**
 * A saveable timer configuration.
 *
 * "Praxis" (practice) represents a complete set of meditation timer settings
 * that can be stored and recalled. There is exactly one active Praxis at a time.
 *
 * Praxis is an immutable value object -- all state changes produce new instances.
 *
 * @property id Unique identifier (UUID as String)
 * @property durationMinutes Duration of meditation in minutes (1-60)
 * @property preparationTimeEnabled Whether preparation time before meditation is enabled
 * @property preparationTimeSeconds Duration of preparation in seconds (5, 10, 15, 20, 30, or 45)
 * @property gongSoundId ID of the gong sound for start/end (references GongSound.id)
 * @property gongVolume Volume for start/end gong sounds (0.0 to 1.0)
 * @property intervalGongsEnabled Whether interval gongs are enabled during meditation
 * @property intervalMinutes Interval in minutes between gongs (1-60)
 * @property intervalMode How interval gongs are triggered (REPEATING, AFTER_START, BEFORE_END)
 * @property intervalSoundId ID of the sound for interval gongs (references GongSound.id)
 * @property intervalGongVolume Volume for interval gong sounds (0.0 to 1.0)
 * @property backgroundSoundId Background sound ID (references BackgroundSound.id)
 * @property backgroundSoundVolume Volume for background sound (0.0 to 1.0)
 */
@Serializable
data class Praxis(
    val id: String = UUID.randomUUID().toString(),
    val durationMinutes: Int = DEFAULT_DURATION_MINUTES,
    val preparationTimeEnabled: Boolean = DEFAULT_PREPARATION_TIME_ENABLED,
    val preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME_SECONDS,
    val gongSoundId: String = DEFAULT_GONG_SOUND_ID,
    val gongVolume: Float = DEFAULT_GONG_VOLUME,
    val intervalGongsEnabled: Boolean = false,
    val intervalMinutes: Int = DEFAULT_INTERVAL_MINUTES,
    val intervalMode: IntervalMode = DEFAULT_INTERVAL_MODE,
    val intervalSoundId: String = DEFAULT_INTERVAL_SOUND_ID,
    val intervalGongVolume: Float = DEFAULT_INTERVAL_GONG_VOLUME,
    val backgroundSoundId: String = DEFAULT_BACKGROUND_SOUND_ID,
    val backgroundSoundVolume: Float = DEFAULT_BACKGROUND_SOUND_VOLUME
) {
    companion object {
        const val DEFAULT_DURATION_MINUTES = 10
        const val DEFAULT_PREPARATION_TIME_ENABLED = true
        const val DEFAULT_PREPARATION_TIME_SECONDS = 15
        const val DEFAULT_GONG_SOUND_ID = GongSound.DEFAULT_SOUND_ID
        const val DEFAULT_GONG_VOLUME = 1.0f
        const val DEFAULT_INTERVAL_MINUTES = 5
        val DEFAULT_INTERVAL_MODE = IntervalMode.REPEATING
        const val DEFAULT_INTERVAL_SOUND_ID = GongSound.SOFT_INTERVAL_SOUND_ID
        const val DEFAULT_INTERVAL_GONG_VOLUME = 0.75f
        const val DEFAULT_BACKGROUND_SOUND_ID = "silent"
        const val DEFAULT_BACKGROUND_SOUND_VOLUME = 0.15f

        /** Valid preparation time options (in seconds) */
        val VALID_PREPARATION_TIMES = listOf(5, 10, 15, 20, 30, 45)

        /** Default Praxis with factory defaults. */
        val Default = create()

        /**
         * Validates and clamps duration to valid range (1-60 minutes).
         */
        fun validateDuration(minutes: Int): Int = minutes.coerceIn(1, 60)

        /**
         * Validates and clamps interval to valid range (1-60 minutes).
         */
        fun validateInterval(minutes: Int): Int = minutes.coerceIn(1, 60)

        /**
         * Validates and clamps preparation time to nearest valid value.
         */
        fun validatePreparationTime(seconds: Int): Int {
            return VALID_PREPARATION_TIMES.minByOrNull { abs(it - seconds) }
                ?: DEFAULT_PREPARATION_TIME_SECONDS
        }

        /**
         * Validates and clamps volume to valid range (0.0-1.0).
         */
        fun validateVolume(volume: Float): Float = volume.coerceIn(0f, 1f)

        /**
         * Creates a Praxis with validated values.
         */
        fun create(
            id: String = UUID.randomUUID().toString(),
            durationMinutes: Int = DEFAULT_DURATION_MINUTES,
            preparationTimeEnabled: Boolean = DEFAULT_PREPARATION_TIME_ENABLED,
            preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME_SECONDS,
            gongSoundId: String = DEFAULT_GONG_SOUND_ID,
            gongVolume: Float = DEFAULT_GONG_VOLUME,
            intervalGongsEnabled: Boolean = false,
            intervalMinutes: Int = DEFAULT_INTERVAL_MINUTES,
            intervalMode: IntervalMode = DEFAULT_INTERVAL_MODE,
            intervalSoundId: String = DEFAULT_INTERVAL_SOUND_ID,
            intervalGongVolume: Float = DEFAULT_INTERVAL_GONG_VOLUME,
            backgroundSoundId: String = DEFAULT_BACKGROUND_SOUND_ID,
            backgroundSoundVolume: Float = DEFAULT_BACKGROUND_SOUND_VOLUME
        ): Praxis {
            return Praxis(
                id = id,
                durationMinutes = validateDuration(durationMinutes),
                preparationTimeEnabled = preparationTimeEnabled,
                preparationTimeSeconds = validatePreparationTime(preparationTimeSeconds),
                gongSoundId = gongSoundId,
                gongVolume = validateVolume(gongVolume),
                intervalGongsEnabled = intervalGongsEnabled,
                intervalMinutes = validateInterval(intervalMinutes),
                intervalMode = intervalMode,
                intervalSoundId = intervalSoundId,
                intervalGongVolume = validateVolume(intervalGongVolume),
                backgroundSoundId = backgroundSoundId,
                backgroundSoundVolume = validateVolume(backgroundSoundVolume)
            )
        }

        /**
         * Creates a Praxis from existing MeditationSettings (for migration).
         *
         * @param settings The MeditationSettings to migrate from
         * @param id Optional ID for the new Praxis (generates UUID if not provided)
         */
        fun fromMeditationSettings(settings: MeditationSettings, id: String = UUID.randomUUID().toString()): Praxis {
            return create(
                id = id,
                durationMinutes = settings.durationMinutes,
                preparationTimeEnabled = settings.preparationTimeEnabled,
                preparationTimeSeconds = settings.preparationTimeSeconds,
                gongSoundId = settings.gongSoundId,
                gongVolume = settings.gongVolume,
                intervalGongsEnabled = settings.intervalGongsEnabled,
                intervalMinutes = settings.intervalMinutes,
                intervalMode = settings.intervalMode,
                intervalSoundId = settings.intervalSoundId,
                intervalGongVolume = settings.intervalGongVolume,
                backgroundSoundId = settings.backgroundSoundId,
                backgroundSoundVolume = settings.backgroundSoundVolume
            )
        }
    }

    // region Builder Methods

    /**
     * Returns a new Praxis with the background sound replaced.
     */
    fun withBackgroundSoundId(id: String): Praxis = copy(backgroundSoundId = id)

    /**
     * Returns a new Praxis with the duration replaced (validated).
     */
    fun withDurationMinutes(minutes: Int): Praxis = copy(durationMinutes = validateDuration(minutes))

    // endregion

    // region Conversion

    /**
     * Converts this Praxis to a MeditationSettings instance.
     * Used when a Praxis is selected and its configuration is applied to the timer.
     */
    fun toMeditationSettings(): MeditationSettings {
        return MeditationSettings(
            intervalGongsEnabled = intervalGongsEnabled,
            intervalMinutes = intervalMinutes,
            intervalMode = intervalMode,
            intervalSoundId = intervalSoundId,
            intervalGongVolume = intervalGongVolume,
            backgroundSoundId = backgroundSoundId,
            backgroundSoundVolume = backgroundSoundVolume,
            durationMinutes = durationMinutes,
            preparationTimeEnabled = preparationTimeEnabled,
            preparationTimeSeconds = preparationTimeSeconds,
            gongSoundId = gongSoundId,
            gongVolume = gongVolume,
        )
    }

    // endregion
}
