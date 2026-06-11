//
//  GuidedMeditationTrimTests.swift
//  Still Moment
//
//  Domain Tests - Trim points for guided meditations (shared-105)
//

import XCTest
@testable import StillMoment

final class GuidedMeditationTrimTests: XCTestCase {
    // MARK: - Effective Range

    func testMeditationWithoutTrimPlaysFullFile() {
        // Given
        let meditation = self.makeMeditation(duration: 600)

        // Then
        XCTAssertEqual(meditation.effectiveStart, 0)
        XCTAssertEqual(meditation.effectiveEnd, 600)
        XCTAssertEqual(meditation.effectiveDuration, 600)
    }

    func testTrimmedMeditationSkipsIntroAndOutro() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 30, trimEnd: 540)

        // Then
        XCTAssertEqual(meditation.effectiveStart, 30)
        XCTAssertEqual(meditation.effectiveEnd, 540)
        XCTAssertEqual(meditation.effectiveDuration, 510)
    }

    func testTrimStartOnlySkipsIntro() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 45)

        // Then
        XCTAssertEqual(meditation.effectiveStart, 45)
        XCTAssertEqual(meditation.effectiveEnd, 600)
        XCTAssertEqual(meditation.effectiveDuration, 555)
    }

    func testTrimEndOnlySkipsOutro() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimEnd: 480)

        // Then
        XCTAssertEqual(meditation.effectiveStart, 0)
        XCTAssertEqual(meditation.effectiveEnd, 480)
        XCTAssertEqual(meditation.effectiveDuration, 480)
    }

    // MARK: - Displayed Duration

    func testDisplayedDurationIsEffectiveDuration() {
        // Given: 10:00 file trimmed to 8:30
        let meditation = self.makeMeditation(duration: 600, trimStart: 30, trimEnd: 540)

        // Then
        XCTAssertEqual(meditation.formattedDuration, "8:30")
    }

    func testFileDurationStaysFullFileLength() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 30, trimEnd: 540)

        // Then: file info shows the real file length as reference
        XCTAssertEqual(meditation.formattedFileDuration, "10:00")
    }

    func testDisplayedDurationWithoutTrimIsUnchanged() {
        // Given
        let meditation = self.makeMeditation(duration: 600)

        // Then
        XCTAssertEqual(meditation.formattedDuration, "10:00")
    }

    // MARK: - Persistence Compatibility

    func testLegacyMeditationWithoutTrimFieldsDecodes() throws {
        // Given: persisted JSON from a version before trim points existed
        let json = """
            {
                "id": "550E8400-E29B-41D4-A716-446655440000",
                "localFilePath": "abc.mp3",
                "fileName": "morning.mp3",
                "duration": 600,
                "teacher": "Test Teacher",
                "name": "Morning Meditation",
                "dateAdded": 700000000
            }
            """

        // When
        let data = try XCTUnwrap(json.data(using: .utf8))
        let meditation = try JSONDecoder().decode(GuidedMeditation.self, from: data)

        // Then: plays unchanged (no trim)
        XCTAssertNil(meditation.trimStart)
        XCTAssertNil(meditation.trimEnd)
        XCTAssertEqual(meditation.effectiveDuration, 600)
    }

    func testTrimPointsSurviveEncodingRoundtrip() throws {
        // Given
        let original = self.makeMeditation(duration: 600, trimStart: 30, trimEnd: 540)

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GuidedMeditation.self, from: data)

        // Then
        XCTAssertEqual(decoded.trimStart, 30)
        XCTAssertEqual(decoded.trimEnd, 540)
    }

    func testMigrationToLocalFilePreservesTrimPoints() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 30, trimEnd: 540)

        // When
        let migrated = meditation.withLocalFilePath("new/path.mp3")

        // Then
        XCTAssertEqual(migrated.trimStart, 30)
        XCTAssertEqual(migrated.trimEnd, 540)
    }

    // MARK: - Helpers

    private func makeMeditation(
        duration: TimeInterval,
        trimStart: TimeInterval? = nil,
        trimEnd: TimeInterval? = nil
    ) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: duration,
            teacher: "Test Teacher",
            name: "Test Meditation",
            trimStart: trimStart,
            trimEnd: trimEnd
        )
    }
}
