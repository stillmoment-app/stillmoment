//
//  TimerViewModelPreviewTests.swift
//  Still Moment
//
//  Tests for audio preview methods moved from SettingsView to TimerViewModel (ios-033)
//

import XCTest
@testable import StillMoment

/// Tests for TimerViewModel audio preview functionality
/// Preview methods allow settings UI to trigger sound previews without holding services directly
@MainActor
final class TimerViewModelPreviewTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockTimerService: MockTimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockSettingsRepository: MockTimerSettingsRepository!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockSoundRepository: MockBackgroundSoundRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockSettingsRepository = MockTimerSettingsRepository()
        self.mockSoundRepository = MockBackgroundSoundRepository()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            soundRepository: self.mockSoundRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockSettingsRepository = nil
        self.mockSoundRepository = nil
        super.tearDown()
    }

    // MARK: - Gong Preview

    func testPlayGongPreview_delegatesToAudioService() {
        // When
        self.sut.playGongPreview(soundId: "tibetan-bowl", volume: 0.8)

        // Then
        XCTAssertTrue(self.mockAudioService.playGongPreviewCalled)
        XCTAssertEqual(self.mockAudioService.lastPreviewSoundId, "tibetan-bowl")
        XCTAssertEqual(Double(self.mockAudioService.lastPreviewVolume ?? 0), 0.8, accuracy: 0.001)
    }

    func testPlayGongPreview_handlesErrorGracefully() {
        // Given
        self.mockAudioService.shouldThrowOnPlay = true

        // When — should not crash
        self.sut.playGongPreview(soundId: "tibetan-bowl", volume: 0.5)

        // Then — error was handled (no crash)
        XCTAssertTrue(self.mockAudioService.playGongPreviewCalled)
    }

    // MARK: - Interval Gong Preview

    func testPlayIntervalGongPreview_delegatesToAudioService() {
        // When
        self.sut.playIntervalGongPreview(soundId: "soft-interval", volume: 0.6)

        // Then — uses preview player (not main player) to avoid conflicts during meditation
        XCTAssertTrue(self.mockAudioService.playGongPreviewCalled)
        XCTAssertEqual(self.mockAudioService.lastPreviewSoundId, "soft-interval")
        XCTAssertEqual(Double(self.mockAudioService.lastPreviewVolume ?? 0), 0.6, accuracy: 0.001)
    }

    func testPlayIntervalGongPreview_handlesErrorGracefully() {
        // Given
        self.mockAudioService.shouldThrowOnPlay = true

        // When — should not crash
        self.sut.playIntervalGongPreview(soundId: "soft-interval", volume: 0.5)

        // Then — error was handled
        XCTAssertTrue(self.mockAudioService.playGongPreviewCalled)
    }

    // MARK: - Background Sound Preview

    func testPlayBackgroundPreview_delegatesToAudioService() {
        // When
        self.sut.playBackgroundPreview(soundId: "forest", volume: 0.3)

        // Then
        XCTAssertTrue(self.mockAudioService.playBackgroundPreviewCalled)
        XCTAssertEqual(self.mockAudioService.lastBackgroundPreviewSoundId, "forest")
        XCTAssertEqual(Double(self.mockAudioService.lastBackgroundPreviewVolume ?? 0), 0.3, accuracy: 0.001)
    }

    func testPlayBackgroundPreview_handlesErrorGracefully() {
        // Given
        self.mockAudioService.shouldThrowOnPlay = true

        // When — should not crash
        self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // Then — error was handled
        XCTAssertTrue(self.mockAudioService.playBackgroundPreviewCalled)
    }

    // MARK: - Stop All Previews

    func testStopAllPreviews_stopsGongAndBackgroundPreview() {
        // When
        self.sut.stopAllPreviews()

        // Then
        XCTAssertTrue(self.mockAudioService.stopGongPreviewCalled)
        XCTAssertTrue(self.mockAudioService.stopBackgroundPreviewCalled)
    }

    // MARK: - Available Background Sounds

    func testAvailableBackgroundSounds_returnsRepositorySounds() {
        // Given
        let testSounds = [
            BackgroundSound(
                id: "forest",
                filename: "forest.mp3",
                name: BackgroundSound.LocalizedString(en: "Forest", de: "Wald"),
                description: BackgroundSound.LocalizedString(en: "Forest sounds", de: "Waldgeraeusche"),
                iconName: "leaf.fill",
                volume: 0.15
            ),
            BackgroundSound(
                id: "rain",
                filename: "rain.mp3",
                name: BackgroundSound.LocalizedString(en: "Rain", de: "Regen"),
                description: BackgroundSound.LocalizedString(en: "Rain sounds", de: "Regengeraeusche"),
                iconName: "cloud.rain.fill",
                volume: 0.15
            )
        ]
        self.mockSoundRepository.soundsToReturn = testSounds

        // When
        let sounds = self.sut.availableBackgroundSounds

        // Then
        XCTAssertEqual(sounds.count, 2)
        XCTAssertEqual(sounds[0].id, "forest")
        XCTAssertEqual(sounds[1].id, "rain")
    }

    func testAvailableBackgroundSounds_returnsEmptyWhenNoSounds() {
        // Given
        self.mockSoundRepository.soundsToReturn = []

        // When
        let sounds = self.sut.availableBackgroundSounds

        // Then
        XCTAssertTrue(sounds.isEmpty)
    }
}
