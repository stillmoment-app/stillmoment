//
//  WaveformGenerationServiceProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Waveform Generation
//

import Foundation

/// Errors that can occur while generating a waveform from an audio file.
enum WaveformGenerationError: Error, LocalizedError {
    case fileNotAccessible
    case decodingFailed(reason: String)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .fileNotAccessible:
            "Could not access audio file for waveform generation"
        case let .decodingFailed(reason):
            "Could not decode audio for waveform generation: \(reason)"
        }
    }
}

/// Generates a normalized `MeditationWaveform` by decoding an audio file.
///
/// Implementations decode chunk-wise and run off the main thread; decoding a long file
/// can take several seconds, so callers should treat this as expensive.
protocol WaveformGenerationServiceProtocol {
    /// Decodes the audio file and produces a normalized waveform.
    ///
    /// - Parameter fileURL: URL to the audio file.
    /// - Returns: A `MeditationWaveform` with `MeditationWaveform.sampleCount` samples.
    /// - Throws: `WaveformGenerationError` if the file cannot be accessed or decoded,
    ///   or `CancellationError` if the task is cancelled.
    func generateWaveform(for fileURL: URL) async throws -> MeditationWaveform
}
