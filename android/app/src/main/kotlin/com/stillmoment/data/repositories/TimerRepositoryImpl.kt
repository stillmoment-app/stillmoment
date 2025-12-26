package com.stillmoment.data.repositories

import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerState
import com.stillmoment.domain.repositories.TimerRepository
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filterNotNull

/**
 * Implementation of TimerRepository managing meditation timer state.
 *
 * Provides reactive timer state via StateFlow and handles all timer operations.
 * Enables future features like timer history and state persistence.
 *
 * Thread-safe: All state mutations go through MutableStateFlow.
 */
@Singleton
class TimerRepositoryImpl
@Inject
constructor() : TimerRepository {
    private val _timer = MutableStateFlow<MeditationTimer?>(null)

    override val timerFlow: Flow<MeditationTimer> = _timer.filterNotNull()

    /**
     * Current timer instance. Exposed for tick operations.
     * Null when no timer is active.
     */
    var currentTimer: MeditationTimer? = null
        private set

    override suspend fun start(durationMinutes: Int) {
        val timer =
            MeditationTimer.create(
                durationMinutes = durationMinutes,
                countdownDuration = DEFAULT_COUNTDOWN_DURATION
            ).startCountdown()

        currentTimer = timer
        _timer.value = timer
    }

    override suspend fun pause() {
        currentTimer = currentTimer?.withState(TimerState.Paused)
        _timer.value = currentTimer
    }

    override suspend fun resume() {
        currentTimer = currentTimer?.withState(TimerState.Running)
        _timer.value = currentTimer
    }

    override suspend fun reset() {
        currentTimer = null
        _timer.value = null
    }

    override suspend fun setDuration(durationMinutes: Int) {
        // Only allow when idle or no timer exists
        if (currentTimer?.state == TimerState.Idle || currentTimer == null) {
            currentTimer = MeditationTimer.create(durationMinutes = durationMinutes)
            _timer.value = currentTimer
        }
    }

    /**
     * Advances the timer by one second.
     *
     * Handles both countdown phase and regular timer phase.
     * Returns the updated timer or null if no timer exists.
     */
    fun tick(): MeditationTimer? {
        currentTimer = currentTimer?.tick()
        _timer.value = currentTimer
        return currentTimer
    }

    /**
     * Marks that an interval gong was played at the current time.
     * Prevents duplicate gongs at the same interval.
     */
    fun markIntervalGongPlayed() {
        currentTimer = currentTimer?.markIntervalGongPlayed()
        _timer.value = currentTimer
    }

    companion object {
        private const val DEFAULT_COUNTDOWN_DURATION = 15
    }
}
