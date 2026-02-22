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
 * @property introductionDurationSeconds Duration of introduction audio in seconds (0 = no introduction)
 * @property silentPhaseStartRemaining Remaining seconds when silent meditation phase started (after introduction)
 * @property lastIntervalGongAt Remaining seconds when last interval gong was played
 */
data class MeditationTimer(
    val durationMinutes: Int,
    val remainingSeconds: Int,
    val state: TimerState,
    val remainingPreparationSeconds: Int = 0,
    val preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME,
    val introductionDurationSeconds: Int = 0,
    val silentPhaseStartRemaining: Int? = null,
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
     * Handles preparation, start gong, introduction, and running phases.
     */
    fun tick(): MeditationTimer {
        return when (state) {
            TimerState.Preparation -> tickPreparation()
            TimerState.StartGong -> tickRunning()
            TimerState.Introduction -> tickIntroduction()
            TimerState.Running -> tickRunning()
            TimerState.Idle, TimerState.Completed -> this
        }
    }

    /** Ticks the preparation countdown. Transitions to StartGong when preparation finishes. */
    private fun tickPreparation(): MeditationTimer {
        val newPreparation = maxOf(0, remainingPreparationSeconds - 1)
        val newState = if (newPreparation <= 0) TimerState.StartGong else TimerState.Preparation
        return copy(
            remainingPreparationSeconds = newPreparation,
            state = newState
        )
    }

    /**
     * Ticks the introduction phase (meditation timer decrements, never auto-transitions to running).
     * The transition to Running is event-driven via endIntroduction().
     */
    private fun tickIntroduction(): MeditationTimer {
        val newRemaining = maxOf(0, remainingSeconds - 1)
        val newState = if (newRemaining <= 0) TimerState.Completed else TimerState.Introduction
        return copy(
            remainingSeconds = newRemaining,
            state = newState
        )
    }

    /** Ticks the main meditation timer (used for StartGong and Running states). */
    private fun tickRunning(): MeditationTimer {
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

    /**
     * Returns a copy transitioned to Introduction state.
     * Called when start gong finishes and an introduction is configured.
     */
    fun startIntroduction(): MeditationTimer {
        return copy(state = TimerState.Introduction)
    }

    /**
     * Returns a copy transitioned from Introduction to Running.
     * Called when the introduction audio finishes playing (event-driven).
     * Sets silentPhaseStartRemaining to current remaining seconds for interval gong calculations.
     */
    fun endIntroduction(): MeditationTimer {
        return copy(
            state = TimerState.Running,
            silentPhaseStartRemaining = remainingSeconds
        )
    }

    /** Returns a copy with updated interval gong timestamp */
    fun markIntervalGongPlayed(): MeditationTimer {
        return copy(lastIntervalGongAt = remainingSeconds)
    }

    /**
     * Checks if an interval gong should be played.
     *
     * Supports 3 modes via [IntervalMode]:
     * - REPEATING: Gongs at every full interval from elapsed time (5:00, 10:00, 15:00...)
     * - AFTER_START: Single gong X minutes after start
     * - BEFORE_END: Single gong X minutes before end
     *
     * The 5-second protection prevents collision with the end gong.
     *
     * @param intervalMinutes Interval in minutes (1-60)
     * @param mode How interval gongs are triggered
     * @return True if a gong should be played at the current remaining time
     */
    @Suppress("ReturnCount") // Multiple guard clauses for clarity
    fun shouldPlayIntervalGong(intervalMinutes: Int, mode: IntervalMode = IntervalMode.REPEATING): Boolean {
        if (state != TimerState.Running) return false
        if (intervalMinutes <= 0) return false

        val intervalSeconds = intervalMinutes * SECONDS_PER_MINUTE

        // No gong if interval >= total duration
        if (intervalSeconds >= totalSeconds) return false

        // 5-second protection: no gong in final 5 seconds to avoid collision with end gong
        if (remainingSeconds <= END_GONG_PROTECTION_SECONDS) return false

        return when (mode) {
            IntervalMode.REPEATING -> shouldPlayRepeatingFromStart(intervalSeconds)
            IntervalMode.AFTER_START -> shouldPlaySingleFromStart(intervalSeconds)
            IntervalMode.BEFORE_END -> shouldPlaySingleFromEnd(intervalSeconds)
        }
    }

    /**
     * The effective start point for interval calculations.
     * Uses silentPhaseStartRemaining when introduction was played, otherwise totalSeconds.
     */
    private val effectiveStartRemaining: Int
        get() = silentPhaseStartRemaining ?: totalSeconds

    private fun shouldPlaySingleFromEnd(intervalSeconds: Int): Boolean {
        // Already played?
        if (lastIntervalGongAt != null) return false

        return remainingSeconds <= intervalSeconds
    }

    private fun shouldPlaySingleFromStart(intervalSeconds: Int): Boolean {
        // Already played?
        if (lastIntervalGongAt != null) return false

        val elapsed = effectiveStartRemaining - remainingSeconds
        return elapsed >= intervalSeconds
    }

    private fun shouldPlayRepeatingFromStart(intervalSeconds: Int): Boolean {
        // First gong not yet played
        if (lastIntervalGongAt == null) {
            val elapsed = effectiveStartRemaining - remainingSeconds
            return elapsed >= intervalSeconds
        }

        // Check if enough time passed since last gong
        val timeSinceLastGong = lastIntervalGongAt - remainingSeconds
        return timeSinceLastGong >= intervalSeconds
    }

    /** Returns a reset timer with original duration */
    fun reset(): MeditationTimer {
        return copy(
            remainingSeconds = durationMinutes * 60,
            state = TimerState.Idle,
            remainingPreparationSeconds = 0,
            silentPhaseStartRemaining = null,
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
         * @param introductionDurationSeconds Duration of introduction audio in seconds (default: 0 = no introduction)
         * @return A new MeditationTimer instance
         * @throws IllegalArgumentException if duration is not between 1 and 60 minutes
         */
        fun create(
            durationMinutes: Int,
            preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME,
            introductionDurationSeconds: Int = 0
        ): MeditationTimer {
            return MeditationTimer(
                durationMinutes = durationMinutes,
                remainingSeconds = durationMinutes * 60,
                state = TimerState.Idle,
                remainingPreparationSeconds = 0,
                preparationTimeSeconds = preparationTimeSeconds,
                introductionDurationSeconds = introductionDurationSeconds,
                silentPhaseStartRemaining = null,
                lastIntervalGongAt = null
            )
        }
    }
}
