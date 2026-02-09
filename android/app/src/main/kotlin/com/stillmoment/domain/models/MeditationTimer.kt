package com.stillmoment.domain.models

/**
 * Domain model representing a meditation timer session.
 *
 * This is an immutable data class. All mutations return new instances.
 * Equivalent to the Swift struct MeditationTimer.
 *
 * @property durationMinutes Duration of the timer in minutes (1-60)
 * @property remainingSeconds Remaining time in seconds
 * @property state Current state of the timer
 * @property remainingPreparationSeconds Remaining preparation seconds (preparationTimeSeconds→0 before timer starts)
 * @property preparationTimeSeconds Duration of preparation in seconds (configured at initialization)
 * @property lastIntervalGongAt Remaining seconds when last interval gong was played
 */
data class MeditationTimer(
    val durationMinutes: Int,
    val remainingSeconds: Int,
    val state: TimerState,
    val remainingPreparationSeconds: Int = 0,
    val preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME,
    val lastIntervalGongAt: Int? = null
) {
    init {
        require(durationMinutes in 1..60) {
            "Invalid duration: $durationMinutes minutes. Duration must be between 1 and 60 minutes."
        }
    }

    /** Returns total duration in seconds */
    val totalSeconds: Int
        get() = durationMinutes * 60

    /** Returns progress as a value between 0.0 and 1.0 */
    val progress: Float
        get() =
            if (totalSeconds > 0) {
                1.0f - (remainingSeconds.toFloat() / totalSeconds.toFloat())
            } else {
                0.0f
            }

    /** Checks if timer has completed */
    val isCompleted: Boolean
        get() = remainingSeconds <= 0

    /**
     * Returns a copy with updated remaining seconds (tick).
     * Handles both preparation phase and regular timer phase.
     */
    fun tick(): MeditationTimer {
        // Handle preparation phase
        if (state == TimerState.Preparation) {
            val newPreparation = maxOf(0, remainingPreparationSeconds - 1)
            val newState = if (newPreparation <= 0) TimerState.Running else TimerState.Preparation
            return copy(
                remainingPreparationSeconds = newPreparation,
                state = newState
            )
        }

        // Handle regular timer
        val newRemaining = maxOf(0, remainingSeconds - 1)
        val newState = if (newRemaining <= 0) TimerState.Completed else state
        return copy(
            remainingSeconds = newRemaining,
            state = newState
        )
    }

    /** Returns a copy with updated state */
    fun withState(newState: TimerState): MeditationTimer {
        return copy(state = newState)
    }

    /** Returns a copy ready for preparation phase (uses configured preparationTimeSeconds) */
    fun startPreparation(): MeditationTimer {
        return copy(
            state = TimerState.Preparation,
            remainingPreparationSeconds = preparationTimeSeconds,
            lastIntervalGongAt = null
        )
    }

    /** Returns a copy with updated interval gong timestamp */
    fun markIntervalGongPlayed(): MeditationTimer {
        return copy(lastIntervalGongAt = remainingSeconds)
    }

    /**
     * Checks if an interval gong should be played.
     *
     * Supports 3 modes:
     * - Repeating from start: Gongs at every full interval from elapsed time (5:00, 10:00, 15:00...)
     * - Repeating from end: Gongs at intervals counted backward from end (remainder first, then regular)
     * - Single (not repeating): Exactly 1 gong X minutes before end
     *
     * The 5-second protection prevents collision with the end gong.
     *
     * @param intervalMinutes Interval in minutes (1-60)
     * @param repeating Whether to repeat the gong at every interval
     * @param fromEnd Whether to count intervals from the end of meditation
     * @return True if a gong should be played at the current remaining time
     */
    @Suppress("ReturnCount") // Multiple guard clauses for clarity
    fun shouldPlayIntervalGong(intervalMinutes: Int, repeating: Boolean = true, fromEnd: Boolean = false): Boolean {
        if (state != TimerState.Running) return false
        if (intervalMinutes <= 0) return false

        val intervalSeconds = intervalMinutes * SECONDS_PER_MINUTE

        // No gong if interval >= total duration
        if (intervalSeconds >= totalSeconds) return false

        // 5-second protection: no gong in final 5 seconds to avoid collision with end gong
        if (remainingSeconds <= END_GONG_PROTECTION_SECONDS) return false

        val elapsed = totalSeconds - remainingSeconds

        // Effective fromEnd: single gong is always "from end"
        val effectiveFromEnd = if (!repeating) true else fromEnd

        return if (!repeating) {
            // Single mode: exactly 1 gong at (totalSeconds - intervalSeconds) elapsed
            shouldPlaySingleGong(elapsed, intervalSeconds)
        } else if (effectiveFromEnd) {
            // Repeating from end
            shouldPlayRepeatingFromEnd(elapsed, intervalSeconds)
        } else {
            // Repeating from start
            shouldPlayRepeatingFromStart(elapsed, intervalSeconds)
        }
    }

    private fun shouldPlaySingleGong(elapsed: Int, intervalSeconds: Int): Boolean {
        val targetElapsed = totalSeconds - intervalSeconds
        if (targetElapsed <= 0) return false

        // Already played?
        if (lastIntervalGongAt != null) return false

        return elapsed >= targetElapsed
    }

    private fun shouldPlayRepeatingFromStart(elapsed: Int, intervalSeconds: Int): Boolean {
        // First gong not yet played
        if (lastIntervalGongAt == null) {
            return elapsed >= intervalSeconds
        }

        // Check if enough time passed since last gong
        val timeSinceLastGong = lastIntervalGongAt - remainingSeconds
        return timeSinceLastGong >= intervalSeconds
    }

    private fun shouldPlayRepeatingFromEnd(elapsed: Int, intervalSeconds: Int): Boolean {
        // Calculate gong times from the end:
        // For 23 min, 5 min interval: gongs at 3:00, 8:00, 13:00, 18:00 elapsed
        // First offset = totalSeconds % intervalSeconds (remainder)
        val remainder = totalSeconds % intervalSeconds
        val firstGongElapsed = if (remainder > 0) remainder else intervalSeconds

        if (lastIntervalGongAt == null) {
            return elapsed >= firstGongElapsed
        }

        val timeSinceLastGong = lastIntervalGongAt - remainingSeconds
        return timeSinceLastGong >= intervalSeconds
    }

    /** Returns a reset timer with original duration */
    fun reset(): MeditationTimer {
        return copy(
            remainingSeconds = durationMinutes * 60,
            state = TimerState.Idle,
            remainingPreparationSeconds = 0,
            lastIntervalGongAt = null
        )
    }

    companion object {
        const val DEFAULT_PREPARATION_TIME = 15
        const val MIN_DURATION_MINUTES = 1
        const val MAX_DURATION_MINUTES = 60
        private const val SECONDS_PER_MINUTE = 60

        /** Protection zone: no interval gong in last 5 seconds to avoid collision with end gong */
        const val END_GONG_PROTECTION_SECONDS = 5

        /**
         * Creates a new meditation timer with validated duration.
         *
         * @param durationMinutes Duration in minutes (1-60)
         * @param preparationTimeSeconds Duration of preparation in seconds (default: 15). Use 0 to skip preparation.
         * @return A new MeditationTimer instance
         * @throws IllegalArgumentException if duration is not between 1 and 60 minutes
         */
        fun create(durationMinutes: Int, preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME): MeditationTimer {
            return MeditationTimer(
                durationMinutes = durationMinutes,
                remainingSeconds = durationMinutes * 60,
                state = TimerState.Idle,
                remainingPreparationSeconds = 0,
                preparationTimeSeconds = preparationTimeSeconds,
                lastIntervalGongAt = null
            )
        }
    }
}
