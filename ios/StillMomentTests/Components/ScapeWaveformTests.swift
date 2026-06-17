//
//  ScapeWaveformTests.swift
//  Still Moment
//
//  Tests for the soundscape mini-waveform envelope mapping (shared-121).
//  The SWAVE envelopes are a cross-platform specification and must stay
//  identical to the Android `SWAVE` map.
//

import SwiftUI
import XCTest
@testable import StillMoment

final class ScapeWaveformTests: XCTestCase {
    // MARK: - Envelope specification (13 values, cross-platform)

    func testForestEnvelopeMatchesSpecification() {
        let expected: [CGFloat] = [0.30, 0.55, 0.40, 0.70, 0.50, 0.62, 0.45, 0.72, 0.52, 0.60, 0.42, 0.58, 0.36]
        XCTAssertEqual(ScapeWaveform.envelope(forSoundId: "forest"), expected)
    }

    func testCozyRainEnvelopeMatchesSpecification() {
        let expected: [CGFloat] = [0.62, 0.74, 0.58, 0.80, 0.66, 0.78, 0.60, 0.82, 0.64, 0.76, 0.58, 0.72, 0.60]
        XCTAssertEqual(ScapeWaveform.envelope(forSoundId: "cozy-rain"), expected)
    }

    func testSilentSoundHasNoEnvelope() {
        XCTAssertNil(ScapeWaveform.envelope(forSoundId: BackgroundSound.silentId))
    }

    func testUnknownOrCustomSoundUsesNeutralDefaultEnvelope() {
        let expected: [CGFloat] = [0.45, 0.55, 0.48, 0.60, 0.50, 0.58, 0.46, 0.62, 0.50, 0.56, 0.44, 0.54, 0.42]
        // A custom file id (UUID string) is not in the built-in map → neutral default.
        XCTAssertEqual(ScapeWaveform.envelope(forSoundId: UUID().uuidString), expected)
    }

    func testEveryEnvelopeHasThirteenBars() {
        XCTAssertEqual(ScapeWaveform.envelope(forSoundId: "forest")?.count, 13)
        XCTAssertEqual(ScapeWaveform.envelope(forSoundId: "cozy-rain")?.count, 13)
        XCTAssertEqual(ScapeWaveform.envelope(forSoundId: UUID().uuidString)?.count, 13)
    }

    // MARK: - Bar height mapping (4 + round(env * 16))

    func testBarHeightAtZeroIsMinimum() {
        XCTAssertEqual(ScapeWaveform.barHeight(forValue: 0), 4)
    }

    func testBarHeightAtFullIsMaximum() {
        XCTAssertEqual(ScapeWaveform.barHeight(forValue: 1), 20)
    }

    func testBarHeightRoundsTheScaledValue() {
        // 0.5 * 16 = 8 → 4 + 8 = 12
        XCTAssertEqual(ScapeWaveform.barHeight(forValue: 0.5), 12)
    }

    func testBarHeightClampsOutOfRangeValues() {
        XCTAssertEqual(ScapeWaveform.barHeight(forValue: -1), 4)
        XCTAssertEqual(ScapeWaveform.barHeight(forValue: 2), 20)
    }
}
