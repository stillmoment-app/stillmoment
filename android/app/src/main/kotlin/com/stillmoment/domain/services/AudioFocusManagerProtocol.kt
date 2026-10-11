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
     * A refused request leaves an earlier, still valid request and its callbacks in place.
     *
     * @param onFocusLost Callback invoked when audio focus is lost (temporarily or for good)
     * @param onFocusGained Callback invoked when the system gives focus back. Only follows a
     *   temporary loss (phone call, voice assistant, alarm); after a permanent loss (another
     *   app plays music) it never comes.
     * @return true if focus was granted, false otherwise
     */
    fun requestFocus(onFocusLost: () -> Unit, onFocusGained: () -> Unit): Boolean

    /**
     * Release audio focus back to the system.
     */
    fun releaseFocus()
}
