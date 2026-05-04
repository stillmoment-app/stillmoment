//
//  SoundscapeResolverTests.swift
//  Still Moment
//
//  Tests for SoundscapeResolver — unified resolution of built-in and custom soundscapes
//

import XCTest
@testable import StillMoment

final class SoundscapeResolverTests: XCTestCase {
    private var soundRepository: MockBackgroundSoundRepository?
    private var customAudioRepository: MockCustomAudioRepository?
    private var sut: SoundscapeResolver?

    override func setUp() {
        super.setUp()
        let soundRepo = MockBackgroundSoundRepository()
        let customRepo = MockCustomAudioRepository()
        self.soundRepository = soundRepo
        self.customAudioRepository = customRepo
        self.sut = SoundscapeResolver(soundRepository: soundRepo, customAudioRepository: customRepo)
    }

    override func tearDown() {
        self.sut = nil
        self.soundRepository = nil
        self.customAudioRepository = nil
        super.tearDown()
    }

    // MARK: - resolve(id:)

    func testResolveBuiltInSoundscape() {
        // Given
        guard let sut, let soundRepo = self.soundRepository else {
            return XCTFail("setup failed")
        }
        let sound = BackgroundSound(
            id: "forest",
            filename: "forest.mp3",
            name: "Forest",
            description: "Forest sounds",
            iconName: "leaf.fill",
            volume: 0.15
        )
        soundRepo.soundsToReturn = [sound]

        // When
        let result = sut.resolve(id: "forest")

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "forest")
        XCTAssertEqual(result?.displayName, "Forest")
    }

    func testResolveSilentReturnsNil() {
        guard let sut else {
            return XCTFail("sut is nil")
        }

        // When
        let result = sut.resolve(id: BackgroundSound.silentId)

        // Then
        XCTAssertNil(result)
    }

    func testResolveCustomSoundscape() {
        // Given
        guard let sut, let customRepo = self.customAudioRepository else {
            return XCTFail("setup failed")
        }
        let customId = UUID()
        let customFile = CustomAudioFile(
            id: customId,
            name: "Rain Recording",
            filename: "\(customId.uuidString).mp3",
            duration: 300,
            dateAdded: Date()
        )
        customRepo.stubbedSoundscapes = [customFile]

        // When
        let result = sut.resolve(id: customId.uuidString)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, customId.uuidString)
        XCTAssertEqual(result?.displayName, "Rain Recording")
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
        guard let sut, let soundRepo = self.soundRepository, let customRepo = self.customAudioRepository
        else {
            return XCTFail("setup failed")
        }
        let sound = BackgroundSound(
            id: "ocean",
            filename: "ocean.mp3",
            name: "Ocean",
            description: "Ocean waves",
            iconName: "water.waves",
            volume: 0.15
        )
        soundRepo.soundsToReturn = [sound]

        let customId = UUID()
        let customFile = CustomAudioFile(
            id: customId,
            name: "Custom Rain",
            filename: "\(customId.uuidString).mp3",
            duration: 120,
            dateAdded: Date()
        )
        customRepo.stubbedSoundscapes = [customFile]

        // When
        let all = sut.allAvailable()

        // Then
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.contains { $0.id == "ocean" })
        XCTAssertTrue(all.contains { $0.id == customId.uuidString })
    }

    // MARK: - resolveAudioURL(id:)

    func testResolveAudioURLForCustomSoundscape() throws {
        // Given
        guard let sut, let customRepo = self.customAudioRepository else {
            return XCTFail("setup failed")
        }
        let customId = UUID()
        let expectedURL = URL(fileURLWithPath: "/tmp/rain.mp3")
        let customFile = CustomAudioFile(
            id: customId,
            name: "Rain",
            filename: "\(customId.uuidString).mp3",
            duration: 300,
            dateAdded: Date()
        )
        customRepo.stubbedSoundscapes = [customFile]
        customRepo.stubbedFileURL = expectedURL

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
