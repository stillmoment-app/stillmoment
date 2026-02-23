//
//  TimerViewModelPraxisTests.swift
//  Still Moment
//
//  Tests for TimerViewModel Praxis integration
//

import XCTest
@testable import StillMoment

@MainActor
final class TimerViewModelPraxisTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockTimerService: MockTimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockSettingsRepository: MockTimerSettingsRepository!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPraxisRepository: MockPraxisRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockSettingsRepository = MockTimerSettingsRepository()
        self.mockPraxisRepository = MockPraxisRepository()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: self.mockPraxisRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockSettingsRepository = nil
        self.mockPraxisRepository = nil
        super.tearDown()
    }

    // MARK: - applyPraxis

    func testApplyPraxis_updatesSettings() {
        // Given
        let praxis = Praxis(
            name: "Evening",
            durationMinutes: 20,
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3
        )

        // When
        self.sut.applyPraxis(praxis)

        // Then
        XCTAssertEqual(self.sut.settings.backgroundSoundId, "forest")
        XCTAssertEqual(self.sut.settings.backgroundSoundVolume, 0.3, accuracy: 0.001)
    }

    func testApplyPraxis_updatesSelectedMinutes() {
        // Given
        let praxis = Praxis(name: "Long", durationMinutes: 30)

        // When
        self.sut.applyPraxis(praxis)

        // Then
        XCTAssertEqual(self.sut.selectedMinutes, 30)
    }

    func testApplyPraxis_updatesActivePraxisName() {
        // Given
        let praxis = Praxis(name: "Morning Calm", durationMinutes: 15)

        // When
        self.sut.applyPraxis(praxis)

        // Then
        XCTAssertEqual(self.sut.activePraxisName, "Morning Calm")
    }

    func testApplyPraxis_savesSettingsToRepository() {
        // Given
        let praxis = Praxis(name: "Test", durationMinutes: 25, startGongSoundId: "classic-bowl")

        // When
        self.sut.applyPraxis(praxis)

        // Then: settings were persisted
        XCTAssertTrue(self.mockSettingsRepository.saveCalled)
    }

    func testApplyPraxis_setsAllSettingsFromPraxis() {
        // Given: praxis with specific interval configuration
        let praxis = Praxis(
            name: "Interval",
            durationMinutes: 20,
            intervalGongsEnabled: true,
            intervalMinutes: 7,
            intervalMode: .afterStart
        )

        // When
        self.sut.applyPraxis(praxis)

        // Then: interval settings transferred
        XCTAssertTrue(self.sut.settings.intervalGongsEnabled)
        XCTAssertEqual(self.sut.settings.intervalMinutes, 7)
        XCTAssertEqual(self.sut.settings.intervalMode, .afterStart)
    }

    // MARK: - displayPraxisName

    func testDisplayPraxisName_whenActivePraxisNameEmpty_returnsDefaultName() {
        // Given: no active praxis resolved (empty mock)
        self.mockPraxisRepository.praxes = []

        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: self.mockPraxisRepository
        )

        // Then
        XCTAssertFalse(viewModel.displayPraxisName.isEmpty)
    }

    func testDisplayPraxisName_afterApplyPraxis_showsNewName() {
        // Given
        let praxis = Praxis(name: "Focus", durationMinutes: 10)

        // When
        self.sut.applyPraxis(praxis)

        // Then
        XCTAssertEqual(self.sut.displayPraxisName, "Focus")
    }

    // MARK: - activePraxisName at init

    func testInit_withStoredActivePraxisId_resolvesName() {
        // Given: repository has a stored active praxis
        let id = UUID()
        let praxis = Praxis(id: id, name: "Stored Active")
        self.mockPraxisRepository.praxes = [praxis]
        self.mockPraxisRepository.storedActivePraxisId = id

        // When: create new VM
        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: self.mockPraxisRepository
        )

        // Then
        XCTAssertEqual(viewModel.activePraxisName, "Stored Active")
    }

    func testInit_withNoStoredActivePraxisId_usesFirstPraxis() {
        // Given: no stored active praxis ID
        self.mockPraxisRepository.storedActivePraxisId = nil
        let praxis = Praxis(id: UUID(), name: "First")
        self.mockPraxisRepository.praxes = [praxis]

        // When
        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: self.mockPraxisRepository
        )

        // Then
        XCTAssertEqual(viewModel.activePraxisName, "First")
    }
}
