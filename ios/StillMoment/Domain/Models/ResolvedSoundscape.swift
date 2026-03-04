//
//  ResolvedSoundscape.swift
//  Still Moment
//
//  Domain - Resolved soundscape audio (built-in or custom)
//

import Foundation

/// A resolved soundscape audio entry, regardless of source (built-in or user-imported).
///
/// Consumers use this instead of checking BackgroundSoundRepository + CustomAudioRepository separately.
/// The resolver transparently handles both sources.
struct ResolvedSoundscape: Equatable {
    /// Unique identifier (BackgroundSound.id for built-in, UUID string for custom)
    let id: String

    /// Localized display name
    let displayName: String
}
