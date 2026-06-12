//
//  WaveformCacheServiceProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Waveform Cache
//

import Foundation

/// Persists precomputed waveforms per meditation so they only need to be generated once.
///
/// Cache entries are small and never need invalidation because audio files are never
/// modified (non-destructive invariant).
protocol WaveformCacheServiceProtocol {
    /// Returns the cached waveform for a meditation, or `nil` if none is stored.
    func load(id: UUID) -> MeditationWaveform?

    /// Stores the waveform for a meditation.
    ///
    /// - Throws: If the waveform cannot be encoded or written.
    func save(id: UUID, waveform: MeditationWaveform) throws

    /// Removes the cached waveform for a meditation, if present.
    func delete(id: UUID)
}
