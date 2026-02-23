//
//  CustomAudioFileTests.swift
//  Still Moment
//
//  Tests for CustomAudioFile domain model
//

import XCTest
@testable import StillMoment

final class CustomAudioFileTests: XCTestCase {
    // MARK: - formattedDuration

    func testFormattedDuration_withNilDuration_returnsLocalizedUnknown() {
        // Given
        let file = self.makeFile(duration: nil)

        // When / Then
        XCTAssertEqual(
            file.formattedDuration,
            NSLocalizedString("custom.audio.duration.unknown", comment: "")
        )
    }

    func testFormattedDuration_withMinutesAndSeconds_returnsMMSS() {
        // Given
        let file = self.makeFile(duration: 95) // 1 min 35 sec

        // When / Then
        XCTAssertEqual(file.formattedDuration, "1:35")
    }

    func testFormattedDuration_underOneMinute_showsZeroMinutes() {
        // Given
        let file = self.makeFile(duration: 45)

        // When / Then
        XCTAssertEqual(file.formattedDuration, "0:45")
    }

    func testFormattedDuration_exactMinutes_showsZeroSeconds() {
        // Given
        let file = self.makeFile(duration: 180) // 3 min

        // When / Then
        XCTAssertEqual(file.formattedDuration, "3:00")
    }

    func testFormattedDuration_zeroDuration_showsZero() {
        // Given
        let file = self.makeFile(duration: 0)

        // When / Then
        XCTAssertEqual(file.formattedDuration, "0:00")
    }

    func testFormattedDuration_singleDigitSeconds_padsWithZero() {
        // Given
        let file = self.makeFile(duration: 63) // 1 min 3 sec

        // When / Then
        XCTAssertEqual(file.formattedDuration, "1:03")
    }

    // MARK: - Equatable

    func testEquatable_sameProperties_isEqual() {
        let id = UUID()
        let date = Date()
        let fileA = CustomAudioFile(
            id: id,
            name: "Test",
            filename: "test.mp3",
            duration: 60,
            type: .soundscape,
            dateAdded: date
        )
        let fileB = CustomAudioFile(
            id: id,
            name: "Test",
            filename: "test.mp3",
            duration: 60,
            type: .soundscape,
            dateAdded: date
        )
        XCTAssertEqual(fileA, fileB)
    }

    func testEquatable_differentId_isNotEqual() {
        let date = Date()
        let fileA = CustomAudioFile(
            id: UUID(),
            name: "Same",
            filename: "same.mp3",
            duration: 60,
            type: .soundscape,
            dateAdded: date
        )
        let fileB = CustomAudioFile(
            id: UUID(),
            name: "Same",
            filename: "same.mp3",
            duration: 60,
            type: .soundscape,
            dateAdded: date
        )
        XCTAssertNotEqual(fileA, fileB)
    }

    // MARK: - Codable

    func testCodable_roundtripPreservesAllProperties() throws {
        // Given
        let original = self.makeFile(duration: 120)

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CustomAudioFile.self, from: data)

        // Then
        XCTAssertEqual(original, decoded)
    }

    func testCodable_nilDuration_roundtripPreservesNil() throws {
        // Given
        let original = self.makeFile(duration: nil)

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CustomAudioFile.self, from: data)

        // Then
        XCTAssertNil(decoded.duration)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.type, decoded.type)
    }

    // MARK: - CustomAudioType

    func testCustomAudioType_rawValues() {
        XCTAssertEqual(CustomAudioType.soundscape.rawValue, "soundscape")
        XCTAssertEqual(CustomAudioType.attunement.rawValue, "attunement")
    }

    func testCustomAudioType_codableRoundtrip() throws {
        // Given
        let soundscape = CustomAudioType.soundscape
        let attunement = CustomAudioType.attunement

        // When
        let soundscapeData = try JSONEncoder().encode(soundscape)
        let attunementData = try JSONEncoder().encode(attunement)

        // Then
        XCTAssertEqual(try JSONDecoder().decode(CustomAudioType.self, from: soundscapeData), .soundscape)
        XCTAssertEqual(try JSONDecoder().decode(CustomAudioType.self, from: attunementData), .attunement)
    }

    // MARK: - Helpers

    private func makeFile(
        id: UUID = UUID(),
        name: String = "Test Sound",
        duration: TimeInterval? = 60,
        type: CustomAudioType = .soundscape
    ) -> CustomAudioFile {
        CustomAudioFile(
            id: id,
            name: name,
            filename: "\(id.uuidString).mp3",
            duration: duration,
            type: type,
            dateAdded: Date()
        )
    }
}
