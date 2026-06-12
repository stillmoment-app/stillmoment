//
//  WaveformProviderProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Waveform Provider
//

import Foundation

/// Orchestrates waveform access for a meditation: serves a cached waveform when present,
/// otherwise generates and caches it.
///
/// Concurrent requests for the same meditation share a single in-flight generation so the
/// background precompute (after import) and an editor opening never decode the file twice.
@MainActor
protocol WaveformProviderProtocol {
    /// Returns the waveform for a meditation.
    ///
    /// Cache hit returns immediately; on a miss the waveform is generated, cached, and returned.
    /// A failing cache-save is non-fatal — the generated waveform is still returned.
    ///
    /// - Throws: `WaveformGenerationError` if the file cannot be decoded, or `CancellationError`.
    func waveform(for meditation: GuidedMeditation) async throws -> MeditationWaveform

    /// Kicks off generation in the background (fire-and-forget) so the waveform is cached
    /// by the time the editor is opened. Never blocks the caller and never crashes on error.
    func precompute(for meditation: GuidedMeditation)

    /// Removes the cached waveform for a meditation (called when the meditation is deleted).
    func removeCached(id: UUID)
}
