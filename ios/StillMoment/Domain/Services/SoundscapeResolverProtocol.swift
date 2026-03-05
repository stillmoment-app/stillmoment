//
//  SoundscapeResolverProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Soundscape Resolver
//

import Foundation

/// Resolves soundscape audio IDs transparently — regardless of whether
/// they refer to a built-in background sound or a user-imported custom soundscape.
///
/// Consumers never need to check BackgroundSoundRepository + CustomAudioRepository separately.
/// The resolver encapsulates the dual lookup logic in one place.
///
/// Protocol lives in Domain; implementation (with catalog + file system access) in Infrastructure.
protocol SoundscapeResolverProtocol {
    /// Resolves a soundscape by ID. Returns nil if the ID is unknown.
    /// The special "silent" ID returns nil (no sound to resolve).
    func resolve(id: String) -> ResolvedSoundscape?

    /// Resolves the playback URL for a soundscape by ID.
    /// - Throws: If the audio file cannot be located.
    func resolveAudioURL(id: String) throws -> URL

    /// Returns all available soundscapes (built-in + custom).
    func allAvailable() -> [ResolvedSoundscape]
}
