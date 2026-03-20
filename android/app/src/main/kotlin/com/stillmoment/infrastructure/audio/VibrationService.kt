package com.stillmoment.infrastructure.audio

import android.content.Context
import android.os.VibrationEffect
import android.os.Vibrator
import com.stillmoment.domain.services.VibrationServiceProtocol
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Vibration service implementation using Android Vibrator API.
 * Uses VibrationEffect.createOneShot (API 26+, matches minSdk).
 */
@Singleton
class VibrationService @Inject constructor(
    private val context: Context
) : VibrationServiceProtocol {

    private val vibrator: Vibrator by lazy {
        context.getSystemService(Vibrator::class.java)
    }

    /** Long vibration (400ms) for start/end gong. */
    override fun vibrate() {
        vibrator.vibrate(VibrationEffect.createOneShot(DURATION_LONG_MS, VibrationEffect.DEFAULT_AMPLITUDE))
    }

    /** Short vibration (150ms) for interval gong. */
    override fun vibrateShort() {
        vibrator.vibrate(VibrationEffect.createOneShot(DURATION_SHORT_MS, VibrationEffect.DEFAULT_AMPLITUDE))
    }

    private companion object {
        /** Duration in milliseconds for start/end gong vibration. */
        const val DURATION_LONG_MS = 400L

        /** Duration in milliseconds for interval gong vibration. */
        const val DURATION_SHORT_MS = 150L
    }
}
