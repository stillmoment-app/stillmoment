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
     * Starts a new meditation session with the specified duration.
     *
     * @param durationMinutes Duration in minutes (1-60)
     */
    suspend fun start(durationMinutes: Int)

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
}
