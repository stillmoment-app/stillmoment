package com.stillmoment.domain.models

/**
 * Configuration for interval gong detection during [MeditationTimer.tick].
 *
 * Passed to `tick(intervalSettings)` when interval gongs are enabled.
 * When `null` is passed, no interval gong detection occurs.
 *
 * @property intervalMinutes Interval in minutes between gongs (e.g., 5 for every 5 minutes)
 * @property mode The interval mode (REPEATING, AFTER_START, BEFORE_END)
 */
data class IntervalSettings(
    val intervalMinutes: Int,
    val mode: IntervalMode
)
