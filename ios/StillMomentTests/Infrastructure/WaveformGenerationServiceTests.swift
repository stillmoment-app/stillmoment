//
//  WaveformGenerationServiceTests.swift
//  Still Moment
//

import AVFoundation
import XCTest
@testable import StillMoment

final class WaveformGenerationServiceTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.sut = WaveformGenerationService()
        self.fixtureURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("waveform-fixture-\(UUID().uuidString).caf")
    }

    override func tearDownWithError() throws {
        if let fixtureURL, FileManager.default.fileExists(atPath: fixtureURL.path) {
            try FileManager.default.removeItem(at: fixtureURL)
        }
        self.sut = nil
        self.fixtureURL = nil
        try super.tearDownWithError()
    }

    func testGeneratesNormalizedWaveformFromSineFixture() async throws {
        // Given: a deterministic 3-second sine-wave file written to disk
        let sut = try XCTUnwrap(self.sut)
        let url = try XCTUnwrap(self.fixtureURL)
        try self.writeSineWave(to: url, seconds: 3.0)

        // When
        let waveform = try await sut.generateWaveform(for: url)

        // Then: exactly sampleCount samples, all within [0, 1], not all silent
        XCTAssertEqual(waveform.samples.count, MeditationWaveform.sampleCount)
        XCTAssertTrue(waveform.samples.allSatisfy { $0 >= 0 && $0 <= 1 })
        XCTAssertTrue(waveform.samples.contains { $0 > 0 })
    }

    func testMissingFileThrowsFileNotAccessible() async throws {
        // Given: a URL that does not exist
        let sut = try XCTUnwrap(self.sut)
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("does-not-exist-\(UUID().uuidString).caf")

        // When / Then
        do {
            _ = try await sut.generateWaveform(for: missing)
            XCTFail("Expected fileNotAccessible error")
        } catch let error as WaveformGenerationError {
            guard case .fileNotAccessible = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    // MARK: Private

    private var sut: WaveformGenerationService?
    private var fixtureURL: URL?

    /// Writes a deterministic mono sine wave to disk so the integration test does not
    /// depend on a checked-in binary fixture.
    private func writeSineWave(to url: URL, seconds: Double) throws {
        let sampleRate = 44100.0
        let frequency = 220.0

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: false
        ]
        let audioFile = try AVAudioFile(forWriting: url, settings: settings)

        let format = audioFile.processingFormat
        let totalFrames = AVAudioFrameCount(sampleRate * seconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
              let channel = buffer.floatChannelData
        else {
            throw WaveformGenerationError.decodingFailed(reason: "Could not allocate fixture buffer")
        }

        buffer.frameLength = totalFrames
        let channelData = channel[0]
        for frame in 0..<Int(totalFrames) {
            let phase = 2.0 * Double.pi * frequency * Double(frame) / sampleRate
            channelData[frame] = Float(sin(phase)) * 0.8
        }

        try audioFile.write(from: buffer)
    }
}
