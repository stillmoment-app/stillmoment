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

        return try await self.generateWaveform(from: audioFile, name: fileURL.lastPathComponent)
    }

    /// Decodes a waveform from an already-opened reader. Split out from `generateWaveform(for:)`
    /// so the chunk loop can be exercised with a fake reader (see `AudioFrameReader`).
    func generateWaveform(from reader: AudioFrameReader, name: String) async throws -> MeditationWaveform {
        let format = reader.processingFormat
        let totalFrames = Int(reader.length)

        guard totalFrames > 0 else {
            Logger.audio.warning("Waveform generation: file has no frames, returning empty waveform")
            return WaveformAccumulator(bucketCount: MeditationWaveform.sampleCount, totalFrameCount: 0).finalize()
        }

        var accumulator = WaveformAccumulator(
            bucketCount: MeditationWaveform.sampleCount,
            totalFrameCount: totalFrames
        )
        try await self.decodeChunks(of: reader, format: format, into: &accumulator)

        Logger.audio.info("Waveform generated for \(name) (\(totalFrames) frames)")
        return accumulator.finalize()
    }

    // MARK: Private

    /// Reads the audio file roughly one second at a time, feeding each chunk to the accumulator.
    /// Reads are bounded by the remaining frame count so the loop never over-reads past EOF.
    private func decodeChunks(
        of reader: AudioFrameReader,
        format: AVAudioFormat,
        into accumulator: inout WaveformAccumulator
    ) async throws {
        let chunkFrameCount = AVAudioFrameCount(max(1, format.sampleRate))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrameCount) else {
            throw WaveformGenerationError.decodingFailed(reason: "Could not allocate PCM buffer")
        }

        var hasDecodedAudio = false
        while reader.framePosition < reader.length {
            try Task.checkCancellation()

            let remaining = AVAudioFrameCount(reader.length - reader.framePosition)
            let framesToRead = min(chunkFrameCount, remaining)

            do {
                try reader.read(into: buffer, frameCount: framesToRead)
            } catch {
                // `AVAudioFile.length` on MP3 counts encoder padding the decoder cannot
                // actually reach, so the final read throws. If we already decoded audio,
                // treat it as end-of-file and finalize with what we have rather than
                // discarding the entire waveform. A failure on the very first read is a
                // genuine decoding error and still propagates.
                if hasDecodedAudio {
                    Logger.audio.warning(
                        "Waveform generation: read failed near end of file, finalizing with decoded frames"
                    )
                    break
                }
                throw WaveformGenerationError.decodingFailed(reason: error.localizedDescription)
            }

            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else {
                break
            }

            let monoSamples = self.monoSamples(from: buffer, frameLength: frameLength)
            accumulator.append(samples: monoSamples)
            hasDecodedAudio = true
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
