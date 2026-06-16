package com.stillmoment.domain.services

/**
 * Plays the start/end gong for guided meditations (shared-106).
 *
 * A small, dedicated player: the timer's [AudioServiceProtocol] is not reused
 * because it registers conflict/pause handlers and keep-alive players for the
 * timer's audio sources. This player only rings the gong and reports completion
 * — it never requests or releases the GUIDED_MEDITATION audio session, so the
 * session lifecycle stays with [AudioPlayerServiceProtocol] and the gong remains
 * audible on the lock screen.
 *
 * Sound and volume follow the timer settings (Praxis), mirroring iOS.
 */
interface MeditationGongPlayerProtocol {
    /**
     * Plays a gong sound and calls [onComplete] once it has finished playing.
     *
     * [onComplete] is always called — even when playback fails — so callers can
     * rely on it to continue their flow (breath pause, session release).
     *
     * @param soundId Gong sound ID from the timer settings (Praxis)
     * @param volume Gong volume from the timer settings (0.0–1.0)
     * @param onComplete Called after the gong finished (or failed to start)
     */
    fun play(soundId: String, volume: Float, onComplete: () -> Unit)

    /**
     * Stops a currently playing gong without firing its completion callback.
     */
    fun stop()
}
