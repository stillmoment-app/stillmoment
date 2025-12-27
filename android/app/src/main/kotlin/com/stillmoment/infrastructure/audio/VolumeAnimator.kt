package com.stillmoment.infrastructure.audio

import android.animation.ValueAnimator
import android.view.animation.LinearInterpolator
import com.stillmoment.domain.services.VolumeAnimatorProtocol
import javax.inject.Inject

/**
 * ValueAnimator-based implementation of volume fading.
 *
 * Uses Android's ValueAnimator for smooth volume transitions.
 */
class VolumeAnimator
@Inject
constructor() : VolumeAnimatorProtocol {

    private var animator: ValueAnimator? = null

    override fun animate(from: Float, to: Float, durationMs: Long, onUpdate: (Float) -> Unit) {
        cancel()

        animator = ValueAnimator.ofFloat(from, to).apply {
            duration = durationMs
            interpolator = LinearInterpolator()
            addUpdateListener { valueAnimator ->
                val volume = valueAnimator.animatedValue as Float
                onUpdate(volume)
            }
            start()
        }
    }

    override fun cancel() {
        animator?.cancel()
        animator = null
    }
}
