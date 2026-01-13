//
//  MockGuidedMeditationSettingsRepository.swift
//  Still Moment
//
//  Mock for GuidedMeditationSettingsRepository in tests
//

@testable import StillMoment

final class MockGuidedMeditationSettingsRepository: GuidedSettingsRepository {
    // MARK: - Test Tracking

    var loadCalled = false
    var loadCallCount = 0
    var saveCalled = false
    var saveCallCount = 0
    var lastSavedSettings: GuidedMeditationSettings?

    // MARK: - Configurable Return Value

    var settingsToReturn: GuidedMeditationSettings = .default

    // MARK: - Protocol Implementation

    func load() -> GuidedMeditationSettings {
        self.loadCalled = true
        self.loadCallCount += 1
        return self.settingsToReturn
    }

    func save(_ settings: GuidedMeditationSettings) {
        self.saveCalled = true
        self.saveCallCount += 1
        self.lastSavedSettings = settings
        self.settingsToReturn = settings
    }
}
