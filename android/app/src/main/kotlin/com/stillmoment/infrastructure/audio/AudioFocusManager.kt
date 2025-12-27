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
 * When focus is lost (phone call, other app), the registered callback is invoked.
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

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // Pause on any focus loss (no ducking, no auto-resume)
                Log.d(TAG, "Audio focus lost ($focusChange), invoking callback")
                onFocusLostCallback?.invoke()
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                // No auto-resume - user must manually resume
                Log.d(TAG, "Audio focus gained (no auto-resume)")
            }
        }
    }

    override fun requestFocus(onFocusLost: () -> Unit): Boolean {
        onFocusLostCallback = onFocusLost

        val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setOnAudioFocusChangeListener(audioFocusChangeListener)
            .build()

        currentFocusRequest = focusRequest

        val result = audioManager.requestAudioFocus(focusRequest)
        val granted = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED

        if (!granted) {
            Log.w(TAG, "Audio focus request denied (result: $result)")
            currentFocusRequest = null
            onFocusLostCallback = null
        } else {
            Log.d(TAG, "Audio focus granted")
        }

        return granted
    }

    override fun releaseFocus() {
        currentFocusRequest?.let { request ->
            audioManager.abandonAudioFocusRequest(request)
            Log.d(TAG, "Audio focus released")
        }
        currentFocusRequest = null
        onFocusLostCallback = null
    }

    companion object {
        private const val TAG = "AudioFocusManager"
    }
}
