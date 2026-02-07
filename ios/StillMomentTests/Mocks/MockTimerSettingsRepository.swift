//
//  MockTimerSettingsRepository.swift
//  Still Moment
//
//  Mock for TimerSettingsRepository in tests
//

@testable import StillMoment

final class MockTimerSettingsRepository: TimerSettingsRepository {
    // MARK: - Test Tracking

    var loadCalled = false
    var loadCallCount = 0
    var saveCalled = false
    var saveCallCount = 0
    var lastSavedSettings: MeditationSettings?

    // MARK: - Configurable Return Value

    var settingsToReturn: MeditationSettings = .default

    // MARK: - Protocol Implementation

    func load() -> MeditationSettings {
        self.loadCalled = true
        self.loadCallCount += 1
        return self.settingsToReturn
    }

    func save(_ settings: MeditationSettings) {
        self.saveCalled = true
        self.saveCallCount += 1
        self.lastSavedSettings = settings
        self.settingsToReturn = settings
    }
}
