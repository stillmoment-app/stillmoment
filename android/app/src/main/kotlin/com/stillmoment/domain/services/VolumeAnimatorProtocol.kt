package com.stillmoment.domain.services

/**
 * Protocol for animating volume changes.
 *
 * Abstracts ValueAnimator-based volume fading for testability.
 * Implementation can use ValueAnimator or test fakes.
 */
interface VolumeAnimatorProtocol {
    /**
     * Animates from the current value to the target over the specified duration.
     *
     * @param from Starting volume (0.0 to 1.0)
     * @param to Target volume (0.0 to 1.0)
     * @param durationMs Animation duration in milliseconds
     * @param onUpdate Called with current animated value during animation
     */
    fun animate(from: Float, to: Float, durationMs: Long, onUpdate: (Float) -> Unit)

    /**
     * Cancels any running animation.
     */
    fun cancel()
}
