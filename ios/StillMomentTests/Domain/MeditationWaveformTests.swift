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

    // MARK: Windowing (zoom, shared-108)

    func testWindowedSlicesTheFractionRange() {
        // Given: 10 samples — the window covers the middle 30 %
        let waveform = MeditationWaveform(samples: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9])

        // When
        let windowed = waveform.windowed(fromFraction: 0.2, toFraction: 0.5)

        // Then: exactly the samples of seconds 20–50 % remain
        XCTAssertEqual(windowed.samples, [0.2, 0.3, 0.4])
    }

    func testWindowedFullRangeReturnsAllSamples() {
        let waveform = MeditationWaveform(samples: [0.1, 0.2, 0.3])

        XCTAssertEqual(waveform.windowed(fromFraction: 0, toFraction: 1), waveform)
    }

    func testWindowedClampsOutOfRangeFractions() {
        let waveform = MeditationWaveform(samples: [0.1, 0.2, 0.3, 0.4])

        XCTAssertEqual(
            waveform.windowed(fromFraction: -0.5, toFraction: 1.5),
            waveform
        )
    }

    func testWindowedZoomShowsRealDetailNotStretchedBars() {
        // An 18 % window of a full-resolution waveform keeps ~396 of 2200 samples —
        // more than the 220 bars an overview renders, so the zoom gains real detail.
        let waveform = MeditationWaveform(
            samples: (0..<MeditationWaveform.sampleCount).map { Float($0) / 2200 }
        )

        let windowed = waveform.windowed(fromFraction: 0.41, toFraction: 0.59)

        XCTAssertGreaterThan(windowed.samples.count, 220)
        // The slice carries the original samples of that region, not interpolations.
        XCTAssertEqual(windowed.samples.first ?? 0, Float(902) / 2200, accuracy: 0.001)
    }

    func testWindowedInvertedRangeReturnsEmpty() {
        let waveform = MeditationWaveform(samples: [0.1, 0.2, 0.3])

        XCTAssertTrue(waveform.windowed(fromFraction: 0.8, toFraction: 0.2).samples.isEmpty)
    }

    func testWindowedEmptyWaveformStaysEmpty() {
        let waveform = MeditationWaveform(samples: [])

        XCTAssertTrue(waveform.windowed(fromFraction: 0.2, toFraction: 0.8).samples.isEmpty)
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
