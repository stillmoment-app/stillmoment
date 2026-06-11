//
//  MeditationGongPlayerProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Per-Meditation Gong Player (shared-106)
//

import Foundation

/// Plays the start/end gong for guided meditations.
///
/// A small, dedicated player: the timer's AudioService is not reused because a
/// second instance would register duplicate conflict handlers and keep-alive
/// players. Sound and volume follow the timer settings (Praxis).
protocol MeditationGongPlayerProtocol {
    /// Plays a gong sound and calls `completion` once it finished playing.
    ///
    /// The vibration option triggers a haptic signal and completes immediately.
    /// `completion` is always called — even when playback fails or is
    /// interrupted — so callers can rely on it to continue their flow.
    ///
    /// - Parameters:
    ///   - soundId: Gong sound ID from the timer settings (Praxis)
    ///   - volume: Gong volume from the timer settings (0.0–1.0)
    ///   - completion: Called on the main thread after the gong finished
    func play(soundId: String, volume: Float, completion: @escaping () -> Void)

    /// Stops a currently playing gong without firing its completion.
    func stop()
}
