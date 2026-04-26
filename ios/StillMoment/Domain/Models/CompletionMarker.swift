//
//  CompletionMarker.swift
//  Still Moment
//
//  Domain Layer - Completion marker expiry logic
//

import Foundation

/// Pure value logic for the guided meditation completion marker.
///
/// The marker survives app termination via `@SceneStorage` and is valid for a
/// fixed TTL. After the TTL expires the marker is stale and must not be shown.
enum CompletionMarker {
    /// Default time-to-live: 8 hours.
    static let defaultTTL: TimeInterval = 8 * 3600

    /// Returns `true` when the marker is absent or older than `ttl`.
    ///
    /// - Parameters:
    ///   - completedAt: Unix timestamp written when the meditation finished.
    ///                  `0` means no marker is set.
    ///   - now: Current date (injected for deterministic testing).
    ///   - ttl: Maximum age before the marker is discarded.
    static func isExpired(
        completedAt: TimeInterval,
        now: Date,
        ttl: TimeInterval = defaultTTL
    ) -> Bool {
        guard completedAt > 0 else {
            return true
        }
        return now.timeIntervalSince1970 - completedAt >= ttl
    }
}
