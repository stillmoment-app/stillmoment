//
//  WaveformProvider.swift
//  Still Moment
//
//  Infrastructure - Waveform Provider (cache + generation orchestration)
//

import Foundation
import OSLog

/// Serves waveforms for meditations, backed by a cache and an on-demand generator.
///
/// Concurrent requests for the same meditation share one in-flight generation task, so the
/// post-import precompute and an editor opening never decode the same file twice. Generation
/// runs off the main thread inside the generator; this class only coordinates tasks and cache.
@MainActor
final class WaveformProvider: WaveformProviderProtocol {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - generationService: Decodes an audio file into a waveform (expensive, off-main).
    ///   - cacheService: Persists/loads waveforms per meditation id.
    ///   - meditationService: Resolves a meditation to its local audio file URL via
    ///     `fileURL(for:)`. Defaults to the shared `GuidedMeditationService`.
    nonisolated init(
        generationService: WaveformGenerationServiceProtocol = WaveformGenerationService(),
        cacheService: WaveformCacheServiceProtocol = WaveformCacheService(),
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService()
    ) {
        self.generationService = generationService
        self.cacheService = cacheService
        self.meditationService = meditationService
    }

    // MARK: Internal

    func waveform(for meditation: GuidedMeditation) async throws -> MeditationWaveform {
        // A cached entry from a build with a different resolution counts as a miss,
        // so old caches upgrade themselves on first use.
        if let cached = self.cacheService.load(id: meditation.id),
           cached.samples.count == MeditationWaveform.sampleCount {
            return cached
        }

        if let existing = self.inFlight[meditation.id] {
            return try await existing.value
        }

        let task = Task<MeditationWaveform, Error> { [weak self] in
            guard let self else {
                throw WaveformGenerationError.fileNotAccessible
            }
            // Clear the in-flight entry only after generation (incl. cache save) has
            // completed, so a later concurrent caller is served from the cache rather than
            // starting a duplicate decode. The error path clears it too, allowing a retry.
            defer { self.inFlight[meditation.id] = nil }
            return try await self.generateAndCache(for: meditation)
        }
        self.inFlight[meditation.id] = task

        return try await task.value
    }

    func precompute(for meditation: GuidedMeditation) {
        Task(priority: .utility) { [weak self] in
            guard let self else {
                return
            }
            do {
                _ = try await self.waveform(for: meditation)
            } catch is CancellationError {
                // Cancellation is expected (e.g. editor closed) — nothing to report.
            } catch {
                Logger.infrastructure.error(
                    "Waveform precompute failed",
                    error: error,
                    metadata: ["id": meditation.id.uuidString]
                )
            }
        }
    }

    func removeCached(id: UUID) {
        self.cacheService.delete(id: id)
    }

    // MARK: Private

    private let generationService: WaveformGenerationServiceProtocol
    private let cacheService: WaveformCacheServiceProtocol
    private let meditationService: GuidedMeditationServiceProtocol

    /// Active generation tasks keyed by meditation id; entries are removed when finished.
    private var inFlight: [UUID: Task<MeditationWaveform, Error>] = [:]

    private func generateAndCache(for meditation: GuidedMeditation) async throws -> MeditationWaveform {
        guard let fileURL = self.meditationService.fileURL(for: meditation) else {
            throw WaveformGenerationError.fileNotAccessible
        }

        let waveform = try await self.generationService.generateWaveform(for: fileURL)

        do {
            try self.cacheService.save(id: meditation.id, waveform: waveform)
        } catch {
            // Non-fatal: a failed cache write only means we regenerate next time.
            Logger.infrastructure.error(
                "Failed to cache waveform",
                error: error,
                metadata: ["id": meditation.id.uuidString]
            )
        }

        return waveform
    }
}
