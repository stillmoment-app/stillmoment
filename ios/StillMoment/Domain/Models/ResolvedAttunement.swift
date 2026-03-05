//
//  ResolvedAttunement.swift
//  Still Moment
//
//  Domain - Resolved attunement audio (built-in or custom)
//

import Foundation

/// A resolved attunement audio entry, regardless of source (built-in or user-imported).
///
/// Consumers use this instead of checking Introduction + CustomAudioRepository separately.
/// The resolver transparently handles both sources.
struct ResolvedAttunement: Equatable {
    /// Unique identifier (Introduction.id for built-in, UUID string for custom)
    let id: String

    /// Localized display name
    let displayName: String

    /// Audio duration in seconds
    let durationSeconds: Int
}
