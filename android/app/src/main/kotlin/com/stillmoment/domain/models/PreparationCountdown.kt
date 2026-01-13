package com.stillmoment.domain.models

/**
 * Immutable Value Object representing a preparation countdown.
 *
 * Used before guided meditation playback to give the user time
 * to put down the phone and settle into position.
 *
 * Pattern: Same as iOS - immutable with tick() returning new instance.
 *
 * @property totalSeconds Total countdown duration in seconds (configured value)
 * @property remainingSeconds Current remaining seconds in the countdown
 */
data class PreparationCountdown(
    val totalSeconds: Int,
    val remainingSeconds: Int = totalSeconds
) {
    /**
     * Whether the countdown has finished (remaining <= 0).
     */
    val isFinished: Boolean
        get() = remainingSeconds <= 0

    /**
     * Progress as a value between 0.0 (start) and 1.0 (finished).
     */
    val progress: Double
        get() = if (totalSeconds > 0) {
            (totalSeconds - remainingSeconds).toDouble() / totalSeconds
        } else {
            0.0
        }

    /**
     * Returns a new countdown with remaining seconds decremented by 1.
     * Does not go below 0.
     */
    fun tick(): PreparationCountdown {
        return copy(remainingSeconds = maxOf(0, remainingSeconds - 1))
    }
}
