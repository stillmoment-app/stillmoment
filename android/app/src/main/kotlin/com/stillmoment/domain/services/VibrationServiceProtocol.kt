package com.stillmoment.domain.services

/**
 * Protocol for triggering device vibration as a meditation signal.
 * Vibration is an alternative to audio gong sounds for silent environments.
 */
interface VibrationServiceProtocol {
    /** Trigger a long vibration (400ms) for start/end gong. */
    fun vibrate()

    /** Trigger a short vibration (150ms) for interval gong. */
    fun vibrateShort()
}
