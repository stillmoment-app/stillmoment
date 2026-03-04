//
//  AttunementResolverProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Attunement Resolver
//

import Foundation

/// Resolves attunement audio IDs transparently — regardless of whether
/// they refer to a built-in introduction or a user-imported custom attunement.
///
/// Consumers never need to check Introduction + CustomAudioRepository separately.
/// The resolver encapsulates the dual lookup logic in one place.
///
/// Protocol lives in Domain; implementation (with catalog + file system access) in Infrastructure.
protocol AttunementResolverProtocol {
    /// Resolves an attunement by ID. Returns nil if the ID is unknown or unavailable.
    func resolve(id: String) -> ResolvedAttunement?

    /// Resolves the playback URL for an attunement by ID.
    /// - Throws: If the audio file cannot be located.
    func resolveAudioURL(id: String) throws -> URL

    /// Returns all attunements available for the current language (built-in + custom).
    func allAvailable() -> [ResolvedAttunement]
}
