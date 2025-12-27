package com.stillmoment.domain.services

/**
 * Protocol for managing system audio focus.
 *
 * Abstracts Android's AudioManager.requestAudioFocus/abandonAudioFocusRequest
 * for testability. The implementation handles the platform-specific details.
 */
interface AudioFocusManagerProtocol {
    /**
     * Request audio focus from the system.
     *
     * @param onFocusLost Callback invoked when audio focus is lost
     * @return true if focus was granted, false otherwise
     */
    fun requestFocus(onFocusLost: () -> Unit): Boolean

    /**
     * Release audio focus back to the system.
     */
    fun releaseFocus()
}
