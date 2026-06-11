//
//  GuidedMeditationGongTests.swift
//  Still Moment
//
//  Domain Tests - Start/end gong per meditation (shared-106)
//

import XCTest
@testable import StillMoment

final class GuidedMeditationGongTests: XCTestCase {
    // MARK: - Default

    func testGongIsDisabledByDefault() {
        // Given
        let meditation = self.makeMeditation()

        // Then
        XCTAssertFalse(meditation.gongEnabled)
    }

    // MARK: - Persistence Compatibility

    func testLegacyMeditationWithoutGongFieldDecodesAsDisabled() throws {
        // Given: persisted JSON from a version before the gong setting existed
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

        // Then: plays without gong
        XCTAssertFalse(meditation.gongEnabled)
    }

    func testGongSettingSurvivesEncodingRoundtrip() throws {
        // Given
        let original = self.makeMeditation(gongEnabled: true)

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GuidedMeditation.self, from: data)

        // Then
        XCTAssertTrue(decoded.gongEnabled)
    }

    func testMigrationToLocalFilePreservesGongSetting() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: true)

        // When
        let migrated = meditation.withLocalFilePath("new/path.mp3")

        // Then
        XCTAssertTrue(migrated.gongEnabled)
    }

    // MARK: - Helpers

    private func makeMeditation(gongEnabled: Bool = false) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: 600,
            teacher: "Test Teacher",
            name: "Test Meditation",
            gongEnabled: gongEnabled
        )
    }
}
