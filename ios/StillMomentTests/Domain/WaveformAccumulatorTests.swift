//
//  WaveformAccumulatorTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

final class WaveformAccumulatorTests: XCTestCase {
    // MARK: - Bucket distribution

    func testFramesAreDistributedEvenlyAcrossBuckets() {
        // Given: 10 frames, 5 buckets — 2 frames per bucket. Frame magnitude rises with index.
        var accumulator = WaveformAccumulator(bucketCount: 5, totalFrameCount: 10)
        let samples: [Float] = (0..<10).map { Float($0 + 1) / 10.0 }

        // When
        accumulator.append(samples: samples)
        let waveform = accumulator.finalize()

        // Then: each bucket's peak is the larger of its two frames; monotonically increasing.
        XCTAssertEqual(waveform.samples.count, 5)
        for index in 1..<waveform.samples.count {
            XCTAssertGreaterThan(waveform.samples[index], waveform.samples[index - 1])
        }
    }

    // MARK: - Peak picking

    func testBucketKeepsMaximumAbsoluteValue() {
        // Given: one bucket, mix of positive and negative samples; peak is the largest magnitude.
        var accumulator = WaveformAccumulator(bucketCount: 1, totalFrameCount: 4)

        // When
        accumulator.append(samples: [0.2, -0.9, 0.5, -0.1])
        let waveform = accumulator.finalize()

        // Then: normalized to its own peak -> 1.0
        XCTAssertEqual(waveform.samples.count, 1)
        XCTAssertEqual(waveform.samples[0], 1.0, accuracy: 0.0001)
    }

    // MARK: - Normalization

    func testPeaksAreNormalizedToGlobalMaximum() {
        // Given: 2 buckets, second bucket twice as loud as first
        var accumulator = WaveformAccumulator(bucketCount: 2, totalFrameCount: 2)

        // When
        accumulator.append(samples: [0.25, 0.5])
        let waveform = accumulator.finalize()

        // Then: loudest becomes 1.0, the other scaled relative to it
        XCTAssertEqual(waveform.samples[0], 0.5, accuracy: 0.0001)
        XCTAssertEqual(waveform.samples[1], 1.0, accuracy: 0.0001)
    }

    func testNormalizationAcceptsChunkedAppends() {
        // Given: same data delivered in two chunks must match a single append
        var chunked = WaveformAccumulator(bucketCount: 4, totalFrameCount: 4)
        chunked.append(samples: [0.1, 0.2])
        chunked.append(samples: [0.4, 0.8])

        var single = WaveformAccumulator(bucketCount: 4, totalFrameCount: 4)
        single.append(samples: [0.1, 0.2, 0.4, 0.8])

        // When / Then
        XCTAssertEqual(chunked.finalize().samples, single.finalize().samples)
    }

    // MARK: - Edge cases

    func testFewerFramesThanBucketsLeavesTrailingBucketsAtZero() {
        // Given: 3 frames spread over 10 buckets
        var accumulator = WaveformAccumulator(bucketCount: 10, totalFrameCount: 3)

        // When
        accumulator.append(samples: [1.0, 1.0, 1.0])
        let waveform = accumulator.finalize()

        // Then: exactly 10 samples, some buckets are zero (no frame landed there)
        XCTAssertEqual(waveform.samples.count, 10)
        XCTAssertTrue(waveform.samples.contains(0))
        XCTAssertTrue(waveform.samples.contains(1.0))
    }

    func testEmptyInputProducesAllZeroWaveform() {
        // Given: declared frames but nothing appended
        let accumulator = WaveformAccumulator(bucketCount: 8, totalFrameCount: 16)

        // When
        let waveform = accumulator.finalize()

        // Then
        XCTAssertEqual(waveform.samples.count, 8)
        XCTAssertTrue(waveform.samples.allSatisfy { $0 == 0 })
    }

    func testZeroTotalFramesProducesAllZeroWaveformWithoutCrash() {
        // Given: total frame count of zero
        var accumulator = WaveformAccumulator(bucketCount: 5, totalFrameCount: 0)

        // When: appending is a no-op, no division by zero
        accumulator.append(samples: [0.5, 0.9])
        let waveform = accumulator.finalize()

        // Then
        XCTAssertEqual(waveform.samples.count, 5)
        XCTAssertTrue(waveform.samples.allSatisfy { $0 == 0 })
    }

    func testAllSilenceInputProducesAllZeroWaveform() {
        // Given: all samples are zero (silent file)
        var accumulator = WaveformAccumulator(bucketCount: 6, totalFrameCount: 6)

        // When
        accumulator.append(samples: [0, 0, 0, 0, 0, 0])
        let waveform = accumulator.finalize()

        // Then: no division by zero, all zeros
        XCTAssertEqual(waveform.samples.count, 6)
        XCTAssertTrue(waveform.samples.allSatisfy { $0 == 0 })
    }

    func testZeroBucketCountIsClampedToOne() {
        // Given: invalid bucket count
        var accumulator = WaveformAccumulator(bucketCount: 0, totalFrameCount: 2)

        // When
        accumulator.append(samples: [0.5, 1.0])
        let waveform = accumulator.finalize()

        // Then: at least one bucket exists
        XCTAssertEqual(waveform.samples.count, 1)
        XCTAssertEqual(waveform.samples[0], 1.0, accuracy: 0.0001)
    }
}
