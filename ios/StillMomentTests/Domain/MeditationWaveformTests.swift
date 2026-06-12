//
//  MeditationWaveformTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

final class MeditationWaveformTests: XCTestCase {
    func testSampleCountIs2200() {
        XCTAssertEqual(MeditationWaveform.sampleCount, 2200)
    }

    func testDownsamplingPreservesBucketPeaks() {
        // Given: 6 samples with a distinct peak per pair
        let waveform = MeditationWaveform(samples: [0, 1.0, 0.5, 0.1, 0.25, 0])

        // When
        let downsampled = waveform.downsampled(to: 3)

        // Then: each display bar keeps the loudest sample of its bucket
        XCTAssertEqual(downsampled.samples, [1.0, 0.5, 0.25])
    }

    func testDownsamplingToLargerOrEqualCountReturnsUnchanged() {
        // Given
        let waveform = MeditationWaveform(samples: [0.1, 0.2, 0.3])

        // When / Then
        XCTAssertEqual(waveform.downsampled(to: 3), waveform)
        XCTAssertEqual(waveform.downsampled(to: 10), waveform)
    }

    func testDownsamplingDistributesUnevenBuckets() {
        // Given: 5 samples into 2 buckets (3 + 2 split)
        let waveform = MeditationWaveform(samples: [0.1, 0.9, 0.2, 0.3, 0.7])

        // When
        let downsampled = waveform.downsampled(to: 2)

        // Then
        XCTAssertEqual(downsampled.samples, [0.9, 0.7])
    }

    func testDownsamplingEmptyWaveformStaysEmpty() {
        // Given
        let waveform = MeditationWaveform(samples: [])

        // When / Then
        XCTAssertEqual(waveform.downsampled(to: 220).samples, [])
    }

    func testCodableRoundtripPreservesSamples() throws {
        // Given
        let original = MeditationWaveform(samples: [0, 0.25, 0.5, 0.75, 1.0])

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MeditationWaveform.self, from: data)

        // Then
        XCTAssertEqual(decoded, original)
    }

    func testEquatableComparesSamples() {
        // Given / When / Then
        XCTAssertEqual(
            MeditationWaveform(samples: [0.1, 0.2]),
            MeditationWaveform(samples: [0.1, 0.2])
        )
        XCTAssertNotEqual(
            MeditationWaveform(samples: [0.1, 0.2]),
            MeditationWaveform(samples: [0.1, 0.3])
        )
    }
}
