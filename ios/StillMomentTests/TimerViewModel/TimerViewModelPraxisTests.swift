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
    var mockPraxisRepository: MockPraxisRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockPraxisRepository = MockPraxisRepository()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            praxisRepository: self.mockPraxisRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockPraxisRepository = nil
        super.tearDown()
    }

    // MARK: - Init from PraxisRepository

    func testInit_loadsCurrentPraxisFromRepository() {
        // Given: repository has a specific praxis
        let praxis = Praxis(durationMinutes: 25, backgroundSoundId: "forest")
        self.mockPraxisRepository.currentPraxis = praxis

        // When
        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            praxisRepository: self.mockPraxisRepository
        )

        // Then: currentPraxis matches what was in repository
        XCTAssertEqual(viewModel.currentPraxis.durationMinutes, 25)
        XCTAssertEqual(viewModel.currentPraxis.backgroundSoundId, "forest")
    }

    func testInit_appliesStoredPraxisToSettings() {
        // Given
        let praxis = Praxis(
            durationMinutes: 20,
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3
        )
        self.mockPraxisRepository.currentPraxis = praxis

        // When
        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            praxisRepository: self.mockPraxisRepository
        )

        // Then: settings reflect the stored praxis
        XCTAssertEqual(viewModel.settings.backgroundSoundId, "forest")
        XCTAssertEqual(viewModel.settings.backgroundSoundVolume, 0.3, accuracy: 0.001)
    }

    func testInit_setsSelectedMinutesFromPraxis() {
        // Given
        let praxis = Praxis(durationMinutes: 30)
        self.mockPraxisRepository.currentPraxis = praxis

        // When
        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            praxisRepository: self.mockPraxisRepository
        )

        // Then
        XCTAssertEqual(viewModel.selectedMinutes, 30)
    }

    // MARK: - updateFromPraxis

    func testUpdateFromPraxis_updatesCurrentPraxis() {
        // Given
        let praxis = Praxis(durationMinutes: 20, backgroundSoundId: "forest")

        // When
        self.sut.updateFromPraxis(praxis)

        // Then
        XCTAssertEqual(self.sut.currentPraxis.durationMinutes, 20)
        XCTAssertEqual(self.sut.currentPraxis.backgroundSoundId, "forest")
    }

    func testUpdateFromPraxis_updatesSettings() {
        // Given
        let praxis = Praxis(
            durationMinutes: 20,
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3
        )

        // When
        self.sut.updateFromPraxis(praxis)

        // Then
        XCTAssertEqual(self.sut.settings.backgroundSoundId, "forest")
        XCTAssertEqual(self.sut.settings.backgroundSoundVolume, 0.3, accuracy: 0.001)
    }

    func testUpdateFromPraxis_updatesSelectedMinutes() {
        // Given
        let praxis = Praxis(durationMinutes: 30)

        // When
        self.sut.updateFromPraxis(praxis)

        // Then
        XCTAssertEqual(self.sut.selectedMinutes, 30)
    }

    func testUpdateFromPraxis_transfersAllIntervalSettings() {
        // Given: praxis with specific interval configuration
        let praxis = Praxis(
            durationMinutes: 20,
            intervalGongsEnabled: true,
            intervalMinutes: 7,
            intervalMode: .afterStart
        )

        // When
        self.sut.updateFromPraxis(praxis)

        // Then: interval settings transferred
        XCTAssertTrue(self.sut.settings.intervalGongsEnabled)
        XCTAssertEqual(self.sut.settings.intervalMinutes, 7)
        XCTAssertEqual(self.sut.settings.intervalMode, .afterStart)
    }

    // MARK: - Setting Pills

    func testPreparationPillLabel_whenEnabled_containsSeconds() {
        // Given
        let praxis = Praxis(
            preparationTimeEnabled: true,
            preparationTimeSeconds: 15,
            startGongSoundId: GongSound.defaultSoundId
        )
        self.sut.updateFromPraxis(praxis)

        // Then: pill label contains the preparation seconds
        XCTAssertNotNil(self.sut.preparationPillLabel)
        XCTAssertTrue(self.sut.preparationPillLabel?.contains("15") == true)
    }

    func testPreparationPillLabel_whenDisabled_isNil() {
        // Given
        let praxis = Praxis(
            preparationTimeEnabled: false,
            preparationTimeSeconds: 15,
            startGongSoundId: GongSound.defaultSoundId
        )
        self.sut.updateFromPraxis(praxis)

        // Then: pill is hidden
        XCTAssertNil(self.sut.preparationPillLabel)
    }

    func testIntervalPillLabel_whenDisabled_isNil() {
        // Given
        let praxis = Praxis(intervalGongsEnabled: false)
        self.sut.updateFromPraxis(praxis)

        // Then: interval pill is hidden
        XCTAssertNil(self.sut.intervalPillLabel)
    }

    func testIntervalPillLabel_whenEnabled_containsMinutes() {
        // Given
        let praxis = Praxis(intervalGongsEnabled: true, intervalMinutes: 10)
        self.sut.updateFromPraxis(praxis)

        // Then: interval pill shows the duration
        XCTAssertNotNil(self.sut.intervalPillLabel)
        XCTAssertTrue(self.sut.intervalPillLabel?.contains("10") == true)
    }

    func testAlwaysVisiblePills_areAlwaysPresent() {
        // When: default configuration
        // Then: gong and background pills are always non-empty
        XCTAssertFalse(self.sut.gongPillLabel.isEmpty)
        XCTAssertFalse(self.sut.backgroundPillLabel.isEmpty)
    }

    // MARK: - Setting Card Labels (shared-083)

    func testPreparationCard_whenEnabled_showsSecondsAndIsNotOff() {
        let praxis = Praxis(
            preparationTimeEnabled: true,
            preparationTimeSeconds: 15,
            startGongSoundId: GongSound.defaultSoundId
        )
        self.sut.updateFromPraxis(praxis)

        XCTAssertTrue(self.sut.preparationCardLabel.contains("15"))
        XCTAssertFalse(self.sut.preparationCardIsOff)
    }

    func testPreparationCard_whenDisabled_showsOffAndIsOff() {
        let praxis = Praxis(
            preparationTimeEnabled: false,
            preparationTimeSeconds: 15,
            startGongSoundId: GongSound.defaultSoundId
        )
        self.sut.updateFromPraxis(praxis)

        XCTAssertEqual(self.sut.preparationCardLabel, NSLocalizedString("common.off", comment: ""))
        XCTAssertTrue(self.sut.preparationCardIsOff)
    }

    func testAttunementCard_whenDisabled_showsNoneAndIsOff() {
        let praxis = Praxis(attunementId: nil, attunementEnabled: false)
        self.sut.updateFromPraxis(praxis)

        XCTAssertEqual(
            self.sut.attunementCardLabel,
            NSLocalizedString("settings.card.value.attunement.off", comment: "")
        )
        XCTAssertTrue(self.sut.attunementCardIsOff)
    }

    func testBackgroundCard_whenSilent_showsSilenceAndIsNotOff() {
        // Hintergrund hat kein Off — "Stille" ist eine bewusste Auswahl
        let praxis = Praxis(backgroundSoundId: "silent")
        self.sut.updateFromPraxis(praxis)

        XCTAssertEqual(
            self.sut.backgroundCardLabel,
            NSLocalizedString("praxis.editor.background.silence", comment: "")
        )
        XCTAssertFalse(self.sut.backgroundCardIsOff)
    }

    func testGongCard_isNeverOff() {
        let praxis = Praxis(startGongSoundId: GongSound.defaultSoundId)
        self.sut.updateFromPraxis(praxis)

        XCTAssertFalse(self.sut.gongCardLabel.isEmpty)
        XCTAssertFalse(self.sut.gongCardIsOff)
    }

    func testIntervalCard_whenDisabled_showsOffAndIsOff() {
        let praxis = Praxis(intervalGongsEnabled: false)
        self.sut.updateFromPraxis(praxis)

        XCTAssertEqual(self.sut.intervalCardLabel, NSLocalizedString("common.off", comment: ""))
        XCTAssertTrue(self.sut.intervalCardIsOff)
    }

    func testIntervalCard_whenEnabled_showsMinutesAndIsNotOff() {
        let praxis = Praxis(intervalGongsEnabled: true, intervalMinutes: 10)
        self.sut.updateFromPraxis(praxis)

        XCTAssertTrue(self.sut.intervalCardLabel.contains("10"))
        XCTAssertFalse(self.sut.intervalCardIsOff)
    }

    func testStartTimer_persistsSelectedDurationToPraxisRepository() {
        // Given
        self.sut.selectedMinutes = 20

        // When
        self.sut.startTimer()

        // Then: praxisRepository has the updated duration
        XCTAssertEqual(self.mockPraxisRepository.savedPraxis?.durationMinutes, 20)
        XCTAssertEqual(self.mockPraxisRepository.currentPraxis.durationMinutes, 20)
    }

    // MARK: - makePraxisEditorViewModel

    func testMakePraxisEditorViewModel_editorReceivesCorrectPraxis() {
        // Given
        let praxis = Praxis(durationMinutes: 25, backgroundSoundId: "rain")

        // When
        let editorVM = self.sut.makePraxisEditorViewModel(praxis: praxis)

        // Then: editor starts with the given praxis values
        XCTAssertEqual(editorVM.durationMinutes, 25)
        XCTAssertEqual(editorVM.backgroundSoundId, "rain")
    }

    func testMakePraxisEditorViewModel_usesSharedAudioService() {
        // Given: TimerViewModel has a known MockAudioService
        let praxis = Praxis.default

        // When: editor plays a gong preview
        let editorVM = self.sut.makePraxisEditorViewModel(praxis: praxis)
        editorVM.playGongPreview(soundId: "temple-bell", volume: 0.8)

        // Then: the call reaches the shared mock — not a new AudioService instance
        XCTAssertTrue(self.mockAudioService.playGongPreviewCalled)
    }

    func testMakePraxisEditorViewModel_saveCallbackUpdatesTimerViewModel() {
        // Given
        let praxis = Praxis(durationMinutes: 30)
        let editorVM = self.sut.makePraxisEditorViewModel(praxis: praxis)
        editorVM.durationMinutes = 45

        // When: user saves in the editor
        editorVM.save()

        // Then: TimerViewModel reflects the saved praxis
        XCTAssertEqual(self.sut.currentPraxis.durationMinutes, 45)
        XCTAssertEqual(self.sut.selectedMinutes, 45)
    }

    func testStartTimer_persistedDurationIsAvailableOnNextLaunch() {
        // Given: user selects 30 minutes and starts
        self.sut.selectedMinutes = 30
        self.sut.startTimer()

        // When: new VM is created (simulates app restart)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            praxisRepository: self.mockPraxisRepository
        )

        // Then: wheel shows 30 minutes
        XCTAssertEqual(newViewModel.selectedMinutes, 30)
    }
}
