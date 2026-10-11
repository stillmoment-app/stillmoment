package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.util.Log
import com.stillmoment.domain.services.AudioFocusManagerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of AudioFocusManagerProtocol using Android's AudioManager.
 *
 * Manages system audio focus for meditation and timer audio playback.
 * When focus is lost (phone call, other app), the registered loss callback is invoked;
 * when the system gives it back after a temporary loss, the gain callback (shared-146).
 */
@Singleton
class AudioFocusManager
@Inject
constructor(
    @ApplicationContext private val context: Context
) : AudioFocusManagerProtocol {
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var currentFocusRequest: AudioFocusRequest? = null
    private var onFocusLostCallback: (() -> Unit)? = null
    private var onFocusGainedCallback: (() -> Unit)? = null

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // Pause on any focus loss (no ducking)
                Log.d(TAG, "Audio focus lost ($focusChange), invoking callback")
                onFocusLostCallback?.invoke()
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Only follows a temporary loss; after AUDIOFOCUS_LOSS it never comes
                Log.d(TAG, "Audio focus gained, invoking callback")
                onFocusGainedCallback?.invoke()
            }
        }
    }

    override fun requestFocus(onFocusLost: () -> Unit, onFocusGained: () -> Unit): Boolean {
        // Reuse the existing request: it is the one the system holds on to
        val focusRequest = currentFocusRequest ?: buildFocusRequest()

        val result = audioManager.requestAudioFocus(focusRequest)
        val granted = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED

        if (granted) {
            Log.d(TAG, "Audio focus granted")
            currentFocusRequest = focusRequest
            onFocusLostCallback = onFocusLost
            onFocusGainedCallback = onFocusGained
        } else {
            // Keep an earlier request (e.g. paused by a phone call): its focus gain must still
            // arrive, and releaseFocus() must still abandon it.
            Log.w(TAG, "Audio focus request denied (result: $result)")
        }

        return granted
    }

    private fun buildFocusRequest(): AudioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
        )
        .setOnAudioFocusChangeListener(audioFocusChangeListener)
        .build()

    override fun releaseFocus() {
        currentFocusRequest?.let { request ->
            audioManager.abandonAudioFocusRequest(request)
            Log.d(TAG, "Audio focus released")
        }
        currentFocusRequest = null
        onFocusLostCallback = null
        onFocusGainedCallback = null
    }

    companion object {
        private const val TAG = "AudioFocusManager"
    }
}
