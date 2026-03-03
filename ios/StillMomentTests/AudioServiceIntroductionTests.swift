//
//  AudioServiceIntroductionTests.swift
//  Still Moment
//
//  Tests for introduction audio bundle integrity and duration accuracy
//

import AVFoundation
import XCTest
@testable import StillMoment

@MainActor
final class AudioServiceIntroductionTests: XCTestCase {
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

    func testAllIntroductionAudioFiles_AreIncludedInBundle() {
        // Given - All registered introductions with their available languages
        let introductions = Introduction.allIntroductions

        // Then - Verify each audio file exists in bundle
        for intro in introductions {
            for language in intro.availableLanguages {
                guard let filename = intro.audioFilename(for: language) else {
                    XCTFail("audioFilename returned nil for \(intro.id) / \(language)")
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
                    "Introduction audio '\(filename)' (id: '\(intro.id)', lang: '\(language)') must be included in bundle"
                )

                if let url {
                    XCTAssertTrue(
                        FileManager.default.fileExists(atPath: url.path),
                        "Introduction audio '\(filename)' must exist at path: \(url.path)"
                    )
                }
            }
        }

        // Verify we have at least one introduction
        XCTAssertFalse(introductions.isEmpty, "Should have at least one registered introduction")
    }

    func testAllIntroductionAudioFiles_ConfiguredDurationMatchesActualDuration() throws {
        // Given - All registered introductions with their available languages
        let introductions = Introduction.allIntroductions

        // Then - Verify configured durationSeconds matches actual audio file duration
        for intro in introductions {
            for language in intro.availableLanguages {
                guard let filename = intro.audioFilename(for: language) else {
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
                let configuredDuration = intro.durationSeconds(for: language)

                // Configured duration must be between floor and ceil of actual audio length.
                // This ensures:
                // 1. The introduction audio is never cut off (durationSeconds >= floor)
                // 2. The configured duration is accurate (durationSeconds <= ceil)
                XCTAssertGreaterThanOrEqual(
                    configuredDuration,
                    floorDuration,
                    "Introduction '\(intro.id)' (\(language)): configured \(configuredDuration)s " +
                        "but audio is \(actualDuration)s (floor: \(floorDuration)s)"
                )
                XCTAssertLessThanOrEqual(
                    configuredDuration,
                    ceilDuration,
                    "Introduction '\(intro.id)' (\(language)): configured \(configuredDuration)s " +
                        "but audio is \(actualDuration)s (ceil: \(ceilDuration)s)"
                )
            }
        }
    }
}
