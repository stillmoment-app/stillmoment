//
//  GongWaveformTests.swift
//  Still Moment
//
//  Unit tests for shared-115 — gong selection mini waveform envelope mapping
//  and volume-card visibility logic. Pure logic, no UIKit/SwiftUI rendering.
//

import CoreGraphics
import XCTest
@testable import StillMoment

final class GongWaveformTests: XCTestCase {
    // MARK: - Envelope per sound ID (11 bars, character-carrying)

    func testEnvelopeHasElevenBarsForTempleBell() {
        let envelope = GongWaveform.envelope(forSoundId: "temple-bell")
        XCTAssertEqual(envelope?.count, 11)
    }

    func testEnvelopeHasElevenBarsForClassicBowl() {
        let envelope = GongWaveform.envelope(forSoundId: "classic-bowl")
        XCTAssertEqual(envelope?.count, 11)
    }

    func testEnvelopeHasElevenBarsForDeepResonance() {
        let envelope = GongWaveform.envelope(forSoundId: "deep-resonance")
        XCTAssertEqual(envelope?.count, 11)
    }

    func testEnvelopeHasElevenBarsForClearStrike() {
        let envelope = GongWaveform.envelope(forSoundId: "clear-strike")
        XCTAssertEqual(envelope?.count, 11)
    }

    func testEnvelopeMatchesFixedTempleBellValues() {
        // The envelopes are a shared cross-platform specification — they must
        // match the WAVE map exactly so iOS and Android render identically.
        let expected: [CGFloat] = [0.35, 0.90, 1.00, 0.85, 0.78, 0.68, 0.60, 0.50, 0.42, 0.34, 0.26]
        let envelope = GongWaveform.envelope(forSoundId: "temple-bell")
        XCTAssertNotNil(envelope)
        for (actual, want) in zip(envelope ?? [], expected) {
            XCTAssertEqual(actual, want, accuracy: 0.0001)
        }
    }

    // MARK: - Vibration has no waveform

    func testEnvelopeIsNilForVibration() {
        XCTAssertNil(GongWaveform.envelope(forSoundId: GongSound.vibrationId))
    }

    func testEnvelopeIsNilForUnknownSound() {
        XCTAssertNil(GongWaveform.envelope(forSoundId: "not-a-real-sound"))
    }

    // MARK: - Bar height mapping (4–20pt)

    func testBarHeightForSilentValueIsFloor() {
        XCTAssertEqual(GongWaveform.barHeight(forValue: 0), 4, accuracy: 0.0001)
    }

    func testBarHeightForFullValueIsCeiling() {
        XCTAssertEqual(GongWaveform.barHeight(forValue: 1), 20, accuracy: 0.0001)
    }

    // MARK: - Volume card visibility

    func testVolumeCardHiddenForVibration() {
        XCTAssertFalse(GongSelectionLogic.isVolumeCardVisible(soundId: GongSound.vibrationId))
    }

    func testVolumeCardVisibleForAudibleSound() {
        XCTAssertTrue(GongSelectionLogic.isVolumeCardVisible(soundId: "temple-bell"))
    }
}
