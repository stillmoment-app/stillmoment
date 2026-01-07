package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.MeditationTimer
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
     * Starts a new meditation session with the specified duration and preparation time.
     *
     * @param durationMinutes Duration in minutes (1-60)
     * @param preparationTimeSeconds Duration of preparation phase in seconds (0 to skip)
     */
    suspend fun start(durationMinutes: Int, preparationTimeSeconds: Int = 15)

    /**
     * Pauses the current meditation session.
     * Only valid when timer is running.
     */
    suspend fun pause()

    /**
     * Resumes a paused meditation session.
     * Only valid when timer is paused.
     */
    suspend fun resume()

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
     * Advances the timer by one second.
     *
     * Handles both countdown phase and regular timer phase.
     * Returns the updated timer or null if no timer exists.
     */
    fun tick(): MeditationTimer?

    /**
     * Marks that an interval gong was played at the current time.
     * Prevents duplicate gongs at the same interval.
     */
    fun markIntervalGongPlayed()
}
