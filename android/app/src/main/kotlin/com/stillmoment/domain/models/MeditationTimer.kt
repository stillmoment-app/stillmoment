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
 * @property countdownSeconds Countdown seconds (countdownDuration→0 before timer starts)
 * @property countdownDuration Duration of countdown in seconds (configured at initialization)
 * @property lastIntervalGongAt Remaining seconds when last interval gong was played
 */
data class MeditationTimer(
    val durationMinutes: Int,
    val remainingSeconds: Int,
    val state: TimerState,
    val countdownSeconds: Int = 0,
    val countdownDuration: Int = DEFAULT_COUNTDOWN_DURATION,
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
     * Handles both countdown phase and regular timer phase.
     */
    fun tick(): MeditationTimer {
        // Handle countdown phase
        if (state == TimerState.Countdown) {
            val newCountdown = maxOf(0, countdownSeconds - 1)
            val newState = if (newCountdown <= 0) TimerState.Running else TimerState.Countdown
            return copy(
                countdownSeconds = newCountdown,
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

    /** Returns a copy ready for countdown (uses configured countdownDuration) */
    fun startCountdown(): MeditationTimer {
        return copy(
            state = TimerState.Countdown,
            countdownSeconds = countdownDuration,
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
     * @param intervalMinutes Interval in minutes (e.g., 5 for every 5 minutes)
     * @return True if enough time has passed since last interval gong
     */
    fun shouldPlayIntervalGong(intervalMinutes: Int): Boolean {
        if (state != TimerState.Running) return false
        if (intervalMinutes <= 0) return false

        val intervalSeconds = intervalMinutes * 60

        // Never played before - play if we've passed first interval
        val lastGongAt = lastIntervalGongAt
        if (lastGongAt == null) {
            val elapsed = totalSeconds - remainingSeconds
            return elapsed >= intervalSeconds && remainingSeconds > 0
        }

        // Check if enough time passed since last gong
        val timeSinceLastGong = lastGongAt - remainingSeconds
        return timeSinceLastGong >= intervalSeconds && remainingSeconds > 0
    }

    /** Returns a reset timer with original duration */
    fun reset(): MeditationTimer {
        return copy(
            remainingSeconds = durationMinutes * 60,
            state = TimerState.Idle,
            countdownSeconds = 0,
            lastIntervalGongAt = null
        )
    }

    companion object {
        const val DEFAULT_COUNTDOWN_DURATION = 15
        const val MIN_DURATION_MINUTES = 1
        const val MAX_DURATION_MINUTES = 60

        /**
         * Creates a new meditation timer with validated duration.
         *
         * @param durationMinutes Duration in minutes (1-60)
         * @param countdownDuration Duration of countdown in seconds (default: 15). Use 0 to skip countdown.
         * @return A new MeditationTimer instance
         * @throws IllegalArgumentException if duration is not between 1 and 60 minutes
         */
        fun create(durationMinutes: Int, countdownDuration: Int = DEFAULT_COUNTDOWN_DURATION): MeditationTimer {
            return MeditationTimer(
                durationMinutes = durationMinutes,
                remainingSeconds = durationMinutes * 60,
                state = TimerState.Idle,
                countdownSeconds = 0,
                countdownDuration = countdownDuration,
                lastIntervalGongAt = null
            )
        }
    }
}
