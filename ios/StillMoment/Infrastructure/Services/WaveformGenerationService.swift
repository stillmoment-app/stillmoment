//
//  WaveformGenerationService.swift
//  Still Moment
//
//  Infrastructure - Waveform Generation (chunk-wise AVAudioFile decode)
//

import AVFoundation
import Foundation
import OSLog

/// Concrete implementation of `WaveformGenerationServiceProtocol`.
///
/// Decodes an audio file chunk-wise with `AVAudioFile` into an `AVAudioPCMBuffer`
/// (about one second of frames per chunk) and feeds each chunk to a
/// `WaveformAccumulator`. The full file is never decoded into memory at once
/// (one hour of audio would be roughly 600 MB of PCM). Decoding runs off the main
/// thread and checks for cancellation between chunks.
final class WaveformGenerationService: WaveformGenerationServiceProtocol {
    // MARK: Internal

    func generateWaveform(for fileURL: URL) async throws -> MeditationWaveform {
        try Task.checkCancellation()

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw WaveformGenerationError.fileNotAccessible
        }

        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: fileURL)
        } catch {
            throw WaveformGenerationError.decodingFailed(reason: error.localizedDescription)
        }

        let format = audioFile.processingFormat
        let totalFrames = Int(audioFile.length)

        guard totalFrames > 0 else {
            Logger.audio.warning("Waveform generation: file has no frames, returning empty waveform")
            return WaveformAccumulator(bucketCount: MeditationWaveform.sampleCount, totalFrameCount: 0).finalize()
        }

        var accumulator = WaveformAccumulator(
            bucketCount: MeditationWaveform.sampleCount,
            totalFrameCount: totalFrames
        )
        try await self.decodeChunks(of: audioFile, format: format, into: &accumulator)

        Logger.audio.info("Waveform generated for \(fileURL.lastPathComponent) (\(totalFrames) frames)")
        return accumulator.finalize()
    }

    // MARK: Private

    /// Reads the audio file roughly one second at a time, feeding each chunk to the accumulator.
    /// Reads are bounded by the remaining frame count so the loop never over-reads past EOF.
    private func decodeChunks(
        of audioFile: AVAudioFile,
        format: AVAudioFormat,
        into accumulator: inout WaveformAccumulator
    ) async throws {
        let chunkFrameCount = AVAudioFrameCount(max(1, format.sampleRate))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrameCount) else {
            throw WaveformGenerationError.decodingFailed(reason: "Could not allocate PCM buffer")
        }

        while audioFile.framePosition < audioFile.length {
            try Task.checkCancellation()

            let remaining = AVAudioFrameCount(audioFile.length - audioFile.framePosition)
            let framesToRead = min(chunkFrameCount, remaining)

            do {
                try audioFile.read(into: buffer, frameCount: framesToRead)
            } catch {
                throw WaveformGenerationError.decodingFailed(reason: error.localizedDescription)
            }

            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else {
                break
            }

            let monoSamples = self.monoSamples(from: buffer, frameLength: frameLength)
            accumulator.append(samples: monoSamples)
        }
    }

    /// Extracts mono samples from a float PCM buffer. Uses the first channel; the
    /// `WaveformAccumulator` only needs per-frame magnitude, so a single channel is
    /// representative for a peak waveform.
    private func monoSamples(from buffer: AVAudioPCMBuffer, frameLength: Int) -> [Float] {
        guard let channelData = buffer.floatChannelData else {
            return []
        }
        let firstChannel = channelData[0]
        return Array(UnsafeBufferPointer(start: firstChannel, count: frameLength))
    }
}
