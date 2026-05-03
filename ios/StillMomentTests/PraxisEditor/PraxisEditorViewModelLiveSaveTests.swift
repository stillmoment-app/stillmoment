//
//  PraxisEditorViewModelLiveSaveTests.swift
//  Still Moment
//
//  Tests for live-save behaviour: every setter mutation persists the
//  current configuration immediately (no explicit save() call required).
//

import XCTest
@testable import StillMoment

@MainActor
final class PraxisEditorViewModelLiveSaveTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: PraxisEditorViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockRepository: MockPraxisRepository!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockAudioService: MockAudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockSoundRepository: MockBackgroundSoundRepository!

    override func setUp() {
        super.setUp()
        self.mockRepository = MockPraxisRepository()
        self.mockAudioService = MockAudioService()
        self.mockSoundRepository = MockBackgroundSoundRepository()
        self.sut = PraxisEditorViewModel(
            praxis: .default,
            repository: self.mockRepository,
            audioService: self.mockAudioService,
            soundRepository: self.mockSoundRepository
        ) { _ in }
    }

    override func tearDown() {
        self.sut = nil
        self.mockRepository = nil
        self.mockAudioService = nil
        self.mockSoundRepository = nil
        super.tearDown()
    }

    /// Spins the run loop so the auto-save sink (deferred via `RunLoop.main`) executes
    /// before the assertion runs. Without this the sink would still be queued.
    private func waitForAutoSave() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    func testInit_doesNotPersistInitialPraxis() {
        // Init wires up subscriptions — but no setter has fired yet, so the
        // repository should not have been called.
        self.waitForAutoSave()
        XCTAssertNil(self.mockRepository.savedPraxis)
    }

    func testDurationMinutesChange_persistsImmediately() {
        self.sut.durationMinutes = 25
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.durationMinutes, 25)
    }

    func testPreparationTimeEnabledChange_persistsImmediately() {
        self.sut.preparationTimeEnabled = false
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.preparationTimeEnabled, false)
    }

    func testPreparationTimeSecondsChange_persistsImmediately() {
        self.sut.preparationTimeSeconds = 30
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.preparationTimeSeconds, 30)
    }

    func testStartGongSoundIdChange_persistsImmediately() {
        self.sut.startGongSoundId = "soft-chime"
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.startGongSoundId, "soft-chime")
    }

    func testGongVolumeChange_persistsImmediately() {
        self.sut.gongVolume = 0.42
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.gongVolume, 0.42)
    }

    func testAttunementIdChange_persistsImmediately() {
        self.sut.attunementId = "earth-en"
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.attunementId, "earth-en")
    }

    func testAttunementEnabledChange_persistsImmediately() {
        self.sut.attunementEnabled = true
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.attunementEnabled, true)
    }

    func testIntervalGongsEnabledChange_persistsImmediately() {
        self.sut.intervalGongsEnabled = true
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.intervalGongsEnabled, true)
    }

    func testIntervalMinutesChange_persistsImmediately() {
        self.sut.intervalMinutes = 7
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.intervalMinutes, 7)
    }

    func testIntervalSoundIdChange_persistsImmediately() {
        self.sut.intervalSoundId = "soft-chime"
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.intervalSoundId, "soft-chime")
    }

    func testIntervalGongVolumeChange_persistsImmediately() {
        self.sut.intervalGongVolume = 0.42
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.intervalGongVolume, 0.42)
    }

    func testBackgroundSoundIdChange_persistsImmediately() {
        self.sut.backgroundSoundId = "rain"
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.backgroundSoundId, "rain")
    }

    func testBackgroundSoundVolumeChange_persistsImmediately() {
        self.sut.backgroundSoundVolume = 0.42
        self.waitForAutoSave()
        XCTAssertEqual(self.mockRepository.savedPraxis?.backgroundSoundVolume, 0.42)
    }
}
