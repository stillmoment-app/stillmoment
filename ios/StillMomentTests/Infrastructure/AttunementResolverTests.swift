//
//  AttunementResolverTests.swift
//  Still Moment
//
//  Tests for AttunementResolver — unified resolution of built-in and custom attunements
//

import XCTest
@testable import StillMoment

final class AttunementResolverTests: XCTestCase {
    private var customAudioRepository: MockCustomAudioRepository?
    private var sut: AttunementResolver?

    override func setUp() {
        super.setUp()
        Attunement.languageOverride = "en"
        let repo = MockCustomAudioRepository()
        self.customAudioRepository = repo
        self.sut = AttunementResolver(customAudioRepository: repo)
    }

    override func tearDown() {
        Attunement.languageOverride = nil
        self.sut = nil
        self.customAudioRepository = nil
        super.tearDown()
    }

    // MARK: - resolve(id:)

    func testResolveBuiltInAttunement() {
        // Given: "breath" is a built-in attunement available in English
        guard let sut else {
            return XCTFail("sut is nil")
        }

        // When
        let result = sut.resolve(id: "breath")

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "breath")
        XCTAssertEqual(result?.durationSeconds, Attunement.breath.durationSeconds(for: "en"))
    }

    func testResolveBuiltInAttunementUnavailableLanguage() {
        // Given: Switch to unsupported language
        Attunement.languageOverride = "ja"
        guard let sut else {
            return XCTFail("sut is nil")
        }

        // When
        let result = sut.resolve(id: "breath")

        // Then: Built-in not available for Japanese
        XCTAssertNil(result)
    }

    func testResolveCustomAttunement() {
        // Given
        guard let sut, let repo = self.customAudioRepository else {
            return XCTFail("setup failed")
        }
        let customId = UUID()
        let customFile = CustomAudioFile(
            id: customId,
            name: "My Meditation",
            filename: "\(customId.uuidString).mp3",
            duration: 120,
            type: .attunement,
            dateAdded: Date()
        )
        repo.stubbedAttunements = [customFile]

        // When
        let result = sut.resolve(id: customId.uuidString)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, customId.uuidString)
        XCTAssertEqual(result?.displayName, "My Meditation")
        XCTAssertEqual(result?.durationSeconds, 120)
    }

    func testResolveCustomAttunementWithNilDuration() {
        // Given
        guard let sut, let repo = self.customAudioRepository else {
            return XCTFail("setup failed")
        }
        let customId = UUID()
        let customFile = CustomAudioFile(
            id: customId,
            name: "Unknown Duration",
            filename: "\(customId.uuidString).mp3",
            duration: nil,
            type: .attunement,
            dateAdded: Date()
        )
        repo.stubbedAttunements = [customFile]

        // When
        let result = sut.resolve(id: customId.uuidString)

        // Then: Duration defaults to 0 when unknown
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.durationSeconds, 0)
    }

    func testResolveUnknownIdReturnsNil() {
        guard let sut else {
            return XCTFail("sut is nil")
        }

        // When
        let result = sut.resolve(id: "nonexistent")

        // Then
        XCTAssertNil(result)
    }

    // MARK: - allAvailable()

    func testAllAvailableIncludesBuiltInAndCustom() {
        // Given
        guard let sut, let repo = self.customAudioRepository else {
            return XCTFail("setup failed")
        }
        let customId = UUID()
        let customFile = CustomAudioFile(
            id: customId,
            name: "Custom Intro",
            filename: "\(customId.uuidString).mp3",
            duration: 60,
            type: .attunement,
            dateAdded: Date()
        )
        repo.stubbedAttunements = [customFile]

        // When
        let all = sut.allAvailable()

        // Then: Built-in + custom
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.contains { $0.id == "breath" })
        XCTAssertTrue(all.contains { $0.id == customId.uuidString })
    }

    func testAllAvailableExcludesUnavailableBuiltIn() {
        // Given: Unsupported language
        Attunement.languageOverride = "ja"
        guard let sut, let repo = self.customAudioRepository else {
            return XCTFail("setup failed")
        }
        let customId = UUID()
        let customFile = CustomAudioFile(
            id: customId,
            name: "Custom Intro",
            filename: "\(customId.uuidString).mp3",
            duration: 60,
            type: .attunement,
            dateAdded: Date()
        )
        repo.stubbedAttunements = [customFile]

        // When
        let all = sut.allAvailable()

        // Then: Only custom
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, customId.uuidString)
    }

    // MARK: - resolveAudioURL(id:)

    func testResolveAudioURLForCustomAttunement() throws {
        // Given
        guard let sut, let repo = self.customAudioRepository else {
            return XCTFail("setup failed")
        }
        let customId = UUID()
        let expectedURL = URL(fileURLWithPath: "/tmp/test-audio.mp3")
        let customFile = CustomAudioFile(
            id: customId,
            name: "Custom Intro",
            filename: "\(customId.uuidString).mp3",
            duration: 60,
            type: .attunement,
            dateAdded: Date()
        )
        repo.stubbedAttunements = [customFile]
        repo.stubbedFileURL = expectedURL

        // When
        let url = try sut.resolveAudioURL(id: customId.uuidString)

        // Then
        XCTAssertEqual(url, expectedURL)
    }

    func testResolveAudioURLForUnknownIdThrows() {
        guard let sut else {
            return XCTFail("sut is nil")
        }

        // When/Then
        XCTAssertThrowsError(try sut.resolveAudioURL(id: "nonexistent"))
    }
}
