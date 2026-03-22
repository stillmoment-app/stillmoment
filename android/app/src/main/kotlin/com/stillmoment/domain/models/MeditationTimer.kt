package com.stillmoment.domain.models

import java.util.Locale

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
 * @property attunementDurationSeconds Duration of attunement audio in seconds (0 = no attunement)
 * @property silentPhaseStartRemaining Remaining seconds when silent meditation phase started (after attunement)
 * @property lastIntervalGongAt Remaining seconds when last interval gong was played
 */
data class MeditationTimer(
    val durationMinutes: Int,
    val remainingSeconds: Int,
    val state: TimerState,
    val remainingPreparationSeconds: Int = 0,
    val preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME,
    val attunementDurationSeconds: Int = 0,
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

    // MARK: - Computed Properties (Display)

    /** Whether currently in preparation phase */
    val isPreparation: Boolean
        get() = state == TimerState.Preparation

    /** Whether the session is active (all states between Preparation and EndGong, inclusive) */
    val isActive: Boolean
        get() = state != TimerState.Idle && state != TimerState.Completed

    /** Whether the timer is in the main running phase */
    val isRunning: Boolean
        get() = state == TimerState.Running

    /** Whether the timer can be reset (not idle) */
    val canReset: Boolean
        get() = state != TimerState.Idle

    /** Whether the timer is in idle state (ready to start) */
    val canStart: Boolean
        get() = state == TimerState.Idle

    /** Formatted time string: preparation seconds as integer, or MM:SS for other phases */
    val formattedTime: String
        get() =
            if (isPreparation) {
                "$remainingPreparationSeconds"
            } else {
                val minutes = remainingSeconds / 60
                val seconds = remainingSeconds % 60
                String.format(Locale.ROOT, "%02d:%02d", minutes, seconds)
            }

    /**
     * Returns a copy with updated remaining seconds and any domain events that occurred.
     *
     * @param intervalSettings Optional interval gong configuration. When provided,
     *   `tick()` checks if an interval gong is due and emits [TimerEvent.IntervalGongDue].
     *   When `null`, no interval gong detection occurs.
     * @return Pair of (updated timer, events that occurred during this tick)
     */
    fun tick(intervalSettings: IntervalSettings? = null): Pair<MeditationTimer, List<TimerEvent>> {
        return when (state) {
            TimerState.Preparation -> {
                val newTimer = tickPreparation()
                val events = if (newTimer.state == TimerState.StartGong) {
                    listOf(TimerEvent.PreparationCompleted)
                } else {
                    emptyList()
                }
                newTimer to events
            }
            TimerState.StartGong -> {
                val newTimer = tickRunning()
                val events = if (newTimer.state == TimerState.EndGong) {
                    listOf(TimerEvent.MeditationCompleted)
                } else {
                    emptyList()
                }
                newTimer to events
            }
            TimerState.Attunement -> {
                val newTimer = tickAttunement()
                val events = if (newTimer.state == TimerState.EndGong) {
                    listOf(TimerEvent.MeditationCompleted)
                } else {
                    emptyList()
                }
                newTimer to events
            }
            TimerState.Running -> tickRunningWithEvents(intervalSettings)
            TimerState.Idle, TimerState.EndGong, TimerState.Completed -> this to emptyList()
        }
    }

    /** Ticks the running state with interval gong detection and event emission */
    private fun tickRunningWithEvents(intervalSettings: IntervalSettings?): Pair<MeditationTimer, List<TimerEvent>> {
        val ticked = tickRunning()

        if (ticked.state == TimerState.EndGong) {
            return ticked to listOf(TimerEvent.MeditationCompleted)
        }

        if (intervalSettings != null &&
            ticked.shouldPlayIntervalGong(intervalSettings.intervalMinutes, intervalSettings.mode)
        ) {
            return ticked.markIntervalGongPlayed() to listOf(TimerEvent.IntervalGongDue)
        }

        return ticked to emptyList()
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
     * Ticks the attunement phase (meditation timer decrements, never auto-transitions to running).
     * The transition to Running is event-driven via endAttunement().
     */
    private fun tickAttunement(): MeditationTimer {
        val newRemaining = maxOf(0, remainingSeconds - 1)
        val newState = if (newRemaining <= 0) TimerState.EndGong else TimerState.Attunement
        return copy(
            remainingSeconds = newRemaining,
            state = newState
        )
    }

    /** Ticks the main meditation timer (used for StartGong and Running states). */
    private fun tickRunning(): MeditationTimer {
        val newRemaining = maxOf(0, remainingSeconds - 1)
        val newState = if (newRemaining <= 0) TimerState.EndGong else state
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
     * Returns a copy transitioned to Attunement state.
     * Called when start gong finishes and an attunement is configured.
     */
    fun startAttunement(): MeditationTimer {
        return copy(state = TimerState.Attunement)
    }

    /**
     * Returns a copy transitioned from Attunement to Running.
     * Called when the attunement audio finishes playing (event-driven).
     * Sets silentPhaseStartRemaining to current remaining seconds for interval gong calculations.
     */
    fun endAttunement(): MeditationTimer {
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
     * Uses silentPhaseStartRemaining when attunement was played, otherwise totalSeconds.
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
         * @param attunementDurationSeconds Duration of attunement audio in seconds (default: 0 = no attunement)
         * @return A new MeditationTimer instance
         * @throws IllegalArgumentException if duration is not between 1 and 60 minutes
         */
        fun create(
            durationMinutes: Int,
            preparationTimeSeconds: Int = DEFAULT_PREPARATION_TIME,
            attunementDurationSeconds: Int = 0
        ): MeditationTimer {
            return MeditationTimer(
                durationMinutes = durationMinutes,
                remainingSeconds = durationMinutes * 60,
                state = TimerState.Idle,
                remainingPreparationSeconds = 0,
                preparationTimeSeconds = preparationTimeSeconds,
                attunementDurationSeconds = attunementDurationSeconds,
                silentPhaseStartRemaining = null,
                lastIntervalGongAt = null
            )
        }
    }
}
