package com.stillmoment.domain.services

/**
 * Protocol for scheduling periodic progress updates.
 *
 * Abstracts Handler-based periodic callbacks for testability.
 * Implementation can use Handler, CoroutineScope, or test fakes.
 */
interface ProgressSchedulerProtocol {
    /**
     * Starts periodic execution of the callback.
     *
     * @param intervalMs Interval between executions in milliseconds
     * @param callback Function to execute periodically
     */
    fun start(intervalMs: Long, callback: () -> Unit)

    /**
     * Stops the periodic execution.
     */
    fun stop()
}
