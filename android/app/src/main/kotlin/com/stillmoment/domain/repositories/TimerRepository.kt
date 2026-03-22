package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.IntervalSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerEvent
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for managing meditation timer state.
 *
 * This interface defines the contract for timer operations,
 * following the Clean Architecture pattern where the domain
 * layer defines interfaces that are implemented in the data layer.
 */
interface TimerRepository {
    /**
     * Flow of the current meditation timer state.
     * Emits updates whenever the timer state changes.
     */
    val timerFlow: Flow<MeditationTimer>

    /**
     * The current timer instance, or null when no timer is active.
     * Read-only snapshot; use [tick] or other methods to advance state.
     */
    val currentTimer: MeditationTimer?

    /**
     * Starts a new meditation session with the specified duration and preparation time.
     *
     * @param durationMinutes Duration in minutes (1-60)
     * @param preparationTimeSeconds Duration of preparation phase in seconds (0 to skip)
     * @param attunementDurationSeconds Duration of attunement audio in seconds (0 = no attunement)
     */
    suspend fun start(
        durationMinutes: Int,
        preparationTimeSeconds: Int = 15,
        attunementDurationSeconds: Int = 0
    ): List<TimerEvent>

    /**
     * Resets the timer to idle state.
     * Can be called from any state.
     */
    suspend fun reset()

    /**
     * Updates the timer duration without starting.
     * Only valid when timer is idle.
     *
     * @param durationMinutes Duration in minutes (1-60)
     */
    suspend fun setDuration(durationMinutes: Int)

    /**
     * Advances the timer by one second and returns the updated timer with any domain events.
     *
     * @param intervalSettings Optional interval gong configuration. When provided,
     *   tick() checks if an interval gong is due and emits [TimerEvent.IntervalGongDue].
     * @return Pair of (updated timer, events) or null if no timer exists.
     */
    fun tick(intervalSettings: IntervalSettings? = null): Pair<MeditationTimer, List<TimerEvent>>?

    /**
     * Transitions the timer from StartGong to Attunement state.
     * Called when the start gong finishes and an attunement is configured.
     */
    fun startAttunement()

    /**
     * Ends the attunement phase, transitioning from Attunement to Running.
     * Sets silentPhaseStartRemaining for interval gong calculations.
     */
    fun endAttunement()

    /**
     * Transitions the timer from StartGong to Running state.
     * Called when start gong finishes and no attunement is configured.
     */
    fun startRunning()

    /**
     * Transitions the timer from EndGong to Completed state.
     * Called when the completion gong finishes playing.
     */
    fun completeTimer()
}
