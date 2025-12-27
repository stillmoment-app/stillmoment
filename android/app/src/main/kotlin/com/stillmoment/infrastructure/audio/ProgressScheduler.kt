package com.stillmoment.infrastructure.audio

import android.os.Handler
import android.os.Looper
import com.stillmoment.domain.services.ProgressSchedulerProtocol
import javax.inject.Inject

/**
 * Handler-based implementation of periodic progress updates.
 *
 * Uses Android's Handler for scheduling periodic callbacks on the main thread.
 */
class ProgressScheduler
@Inject
constructor() : ProgressSchedulerProtocol {

    private val handler = Handler(Looper.getMainLooper())
    private var runnable: Runnable? = null

    override fun start(intervalMs: Long, callback: () -> Unit) {
        stop()

        runnable = object : Runnable {
            override fun run() {
                callback()
                handler.postDelayed(this, intervalMs)
            }
        }
        handler.post(runnable!!)
    }

    override fun stop() {
        runnable?.let { handler.removeCallbacks(it) }
        runnable = null
    }
}
