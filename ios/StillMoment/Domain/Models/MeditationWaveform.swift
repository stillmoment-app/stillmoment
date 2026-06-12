//
//  MeditationWaveform.swift
//  Still Moment
//
//  Domain Model - Precomputed Waveform Data
//

import Foundation

/// A precomputed, normalized waveform for a guided meditation.
///
/// Holds a fixed number of peak samples (`sampleCount`), each normalized to `[0, 1]`.
/// The resolution is deliberately higher than the ~220 bars an overview renders so a
/// zoomed-in view (shared-108) shows real detail; overviews call `downsampled(to:)`.
/// The data is small (~2200 floats), cached per meditation, and never derived from a
/// mutating audio file, so it does not need invalidation (non-destructive invariant).
struct MeditationWaveform: Codable, Equatable {
    // MARK: Internal

    /// The number of peak samples generated per file. Fixed across the app so cached
    /// data and renderers agree on resolution.
    static let sampleCount = 2200

    /// Peak amplitudes, normalized to `[0, 1]`. For an all-silent file every
    /// value is `0`.
    let samples: [Float]

    /// Reduces the waveform to `targetCount` display bars, keeping the loudest sample
    /// of each bucket so short peaks stay visible. Returns `self` when the waveform
    /// already has `targetCount` samples or fewer.
    func downsampled(to targetCount: Int) -> MeditationWaveform {
        guard targetCount > 0, self.samples.count > targetCount else {
            return self
        }

        var peaks = [Float](repeating: 0, count: targetCount)
        for (index, sample) in self.samples.enumerated() {
            let bucket = min(index * targetCount / self.samples.count, targetCount - 1)
            if sample > peaks[bucket] {
                peaks[bucket] = sample
            }
        }
        return MeditationWaveform(samples: peaks)
    }

    /// Cuts out the sample range covered by a fractional window of the file — the
    /// zoomed trim editor (shared-108) renders this slice instead of the full
    /// waveform, so an 18 % window keeps ~400 of 2200 samples (real detail).
    /// Fractions are clamped to `[0, 1]`; partially covered edge samples are included.
    func windowed(fromFraction: Double, toFraction: Double) -> MeditationWaveform {
        let count = Double(self.samples.count)
        let lower = Int((min(max(fromFraction, 0), 1) * count).rounded(.down))
        let upper = Int((min(max(toFraction, 0), 1) * count).rounded(.up))
        guard lower < upper else {
            return MeditationWaveform(samples: [])
        }
        return MeditationWaveform(samples: Array(self.samples[lower..<upper]))
    }
}
