package com.stillmoment.data.repositories

import com.stillmoment.domain.models.IntervalSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerEvent
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
    override var currentTimer: MeditationTimer? = null
        private set

    override suspend fun start(
        durationMinutes: Int,
        preparationTimeSeconds: Int,
        attunementDurationSeconds: Int
    ): List<TimerEvent> {
        val timer =
            MeditationTimer.create(
                durationMinutes = durationMinutes,
                preparationTimeSeconds = preparationTimeSeconds,
                attunementDurationSeconds = attunementDurationSeconds
            ).let { created ->
                // If preparation time is 0, start directly in StartGong state (gong plays immediately)
                if (preparationTimeSeconds <= 0) {
                    created.withState(TimerState.StartGong)
                } else {
                    created.startPreparation()
                }
            }

        currentTimer = timer
        _timer.value = timer
        return if (preparationTimeSeconds <= 0) listOf(TimerEvent.PreparationCompleted) else emptyList()
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
     * Advances the timer by one second and returns the updated timer with any domain events.
     *
     * @param intervalSettings Optional interval gong configuration for interval gong detection.
     * @return Pair of (updated timer, events) or null if no timer exists.
     */
    override fun tick(intervalSettings: IntervalSettings?): Pair<MeditationTimer, List<TimerEvent>>? {
        val timer = currentTimer ?: return null
        val (updatedTimer, events) = timer.tick(intervalSettings)
        currentTimer = updatedTimer
        _timer.value = updatedTimer
        return updatedTimer to events
    }

    override fun startAttunement() {
        currentTimer = currentTimer?.startAttunement()
        _timer.value = currentTimer
    }

    override fun endAttunement() {
        currentTimer = currentTimer?.endAttunement()
        _timer.value = currentTimer
    }

    override fun startRunning() {
        currentTimer = currentTimer?.withState(TimerState.Running)
        _timer.value = currentTimer
    }

    override fun completeTimer() {
        currentTimer = currentTimer?.withState(TimerState.Completed)
        _timer.value = currentTimer
    }
}
