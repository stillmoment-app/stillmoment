package com.stillmoment.domain.models

import kotlinx.serialization.Serializable

/**
 * Defines how interval gongs are triggered during meditation.
 *
 * Replaces the boolean pair (intervalRepeating + intervalFromEnd) with
 * three self-documenting modes.
 */
@Serializable
enum class IntervalMode {
    /** Gongs at every full interval from start (5:00, 10:00, 15:00...) */
    REPEATING,

    /** Single gong X minutes after start */
    AFTER_START,

    /** Single gong X minutes before end */
    BEFORE_END;

    val isRepeating: Boolean get() = this == REPEATING

    companion object {
        val DEFAULT = REPEATING

        fun fromString(value: String?): IntervalMode = entries.find { it.name == value } ?: DEFAULT
    }
}
