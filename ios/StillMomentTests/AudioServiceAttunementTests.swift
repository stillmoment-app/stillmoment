//
//  AudioServiceAttunementTests.swift
//  Still Moment
//
//  Tests for attunement audio bundle integrity and duration accuracy
//

import AVFoundation
import XCTest
@testable import StillMoment

@MainActor
final class AudioServiceAttunementTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioService!

    override func setUp() {
        super.setUp()
        self.sut = AudioService()
    }

    override func tearDown() {
        self.sut.stop()
        AudioSessionCoordinator.shared.releaseAudioSession(for: .timer)
        self.sut = nil
        super.tearDown()
    }

    func testAllAttunementAudioFiles_AreIncludedInBundle() {
        // Given - All registered attunements with their available languages
        let attunements = Attunement.allAttunements

        // Then - Verify each audio file exists in bundle
        for attunement in attunements {
            for language in attunement.availableLanguages {
                guard let filename = attunement.audioFilename(for: language) else {
                    XCTFail("audioFilename returned nil for \(attunement.id) / \(language)")
                    continue
                }

                let components = filename.components(separatedBy: ".")
                let name = components.first ?? filename
                let ext = components.count > 1 ? components.last : nil

                let url = Bundle.main.url(
                    forResource: name,
                    withExtension: ext,
                    subdirectory: "IntroductionAudio"
                )

                XCTAssertNotNil(
                    url,
                    "Attunement audio '\(filename)' (id: '\(attunement.id)', lang: '\(language)') must be included in bundle"
                )

                if let url {
                    XCTAssertTrue(
                        FileManager.default.fileExists(atPath: url.path),
                        "Attunement audio '\(filename)' must exist at path: \(url.path)"
                    )
                }
            }
        }

        // Verify we have at least one attunement
        XCTAssertFalse(attunements.isEmpty, "Should have at least one registered attunement")
    }

    func testAllAttunementAudioFiles_ConfiguredDurationMatchesActualDuration() throws {
        // Given - All registered attunements with their available languages
        let attunements = Attunement.allAttunements

        // Then - Verify configured durationSeconds matches actual audio file duration
        for attunement in attunements {
            for language in attunement.availableLanguages {
                guard let filename = attunement.audioFilename(for: language) else {
                    continue
                }

                let components = filename.components(separatedBy: ".")
                let name = components.first ?? filename
                let ext = components.count > 1 ? components.last : nil

                guard let url = Bundle.main.url(
                    forResource: name,
                    withExtension: ext,
                    subdirectory: "IntroductionAudio"
                ) else {
                    continue // Bundle existence is tested separately
                }

                let player = try AVAudioPlayer(contentsOf: url)
                let actualDuration = player.duration
                let floorDuration = Int(floor(actualDuration))
                let ceilDuration = Int(ceil(actualDuration))
                let configuredDuration = attunement.durationSeconds(for: language)

                // Configured duration must be between floor and ceil of actual audio length.
                // This ensures:
                // 1. The attunement audio is never cut off (durationSeconds >= floor)
                // 2. The configured duration is accurate (durationSeconds <= ceil)
                XCTAssertGreaterThanOrEqual(
                    configuredDuration,
                    floorDuration,
                    "Attunement '\(attunement.id)' (\(language)): configured \(configuredDuration)s " +
                        "but audio is \(actualDuration)s (floor: \(floorDuration)s)"
                )
                XCTAssertLessThanOrEqual(
                    configuredDuration,
                    ceilDuration,
                    "Attunement '\(attunement.id)' (\(language)): configured \(configuredDuration)s " +
                        "but audio is \(actualDuration)s (ceil: \(ceilDuration)s)"
                )
            }
        }
    }
}
