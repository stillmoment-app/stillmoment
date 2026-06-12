//
//  WaveformAccumulator.swift
//  Still Moment
//
//  Domain Model - Waveform Bucket Builder
//

import Foundation

/// Builds a `MeditationWaveform` by streaming PCM sample chunks into a fixed number
/// of buckets.
///
/// The total frame count is known up front (from the audio file length), so each
/// incoming frame is assigned to a bucket by its global position. Each bucket tracks
/// the peak (maximum absolute amplitude) of the frames that fall into it. `finalize()`
/// normalizes all peaks to the global maximum.
///
/// This is a builder, so it is a small mutable type by design. It contains no
/// AVFoundation/UIKit dependencies and is fully unit-testable with synthetic samples.
struct WaveformAccumulator {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - bucketCount: Number of buckets (waveform bars) to produce. Clamped to at least 1.
    ///   - totalFrameCount: Total number of audio frames that will be appended. Used to map
    ///     each frame to its bucket. A value of `0` produces an all-zero waveform.
    init(bucketCount: Int, totalFrameCount: Int) {
        let safeBucketCount = max(1, bucketCount)
        self.bucketCount = safeBucketCount
        self.totalFrameCount = max(0, totalFrameCount)
        self.peaks = [Float](repeating: 0, count: safeBucketCount)
    }

    // MARK: Internal

    /// Feeds a chunk of PCM samples (mono) sequentially. Samples are assigned to buckets
    /// by their running global frame index. Values may be negative; the absolute value is used.
    mutating func append(samples: [Float]) {
        guard self.totalFrameCount > 0 else {
            return
        }

        for sample in samples {
            let bucketIndex = self.bucketIndex(forFrame: self.processedFrameCount)
            let magnitude = abs(sample)
            if magnitude > self.peaks[bucketIndex] {
                self.peaks[bucketIndex] = magnitude
            }
            self.processedFrameCount += 1
        }
    }

    /// Produces the normalized waveform. Peaks are divided by the global maximum so the
    /// loudest bar becomes `1.0`. An all-silent input (global max `0`) yields all zeros
    /// (no division by zero).
    func finalize() -> MeditationWaveform {
        guard let globalMax = peaks.max(), globalMax > 0 else {
            return MeditationWaveform(samples: [Float](repeating: 0, count: self.bucketCount))
        }

        let normalized = self.peaks.map { $0 / globalMax }
        return MeditationWaveform(samples: normalized)
    }

    // MARK: Private

    private let bucketCount: Int
    private let totalFrameCount: Int
    private var peaks: [Float]
    private var processedFrameCount = 0

    /// Maps a global frame index to its bucket, distributing frames evenly across buckets.
    private func bucketIndex(forFrame frame: Int) -> Int {
        let rawIndex = frame * self.bucketCount / self.totalFrameCount
        return min(rawIndex, self.bucketCount - 1)
    }
}
