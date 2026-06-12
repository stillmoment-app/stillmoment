//
//  GuidedMeditationPlayerViewModelTests+Waveform.swift
//  Still Moment
//
//  Waveform loading, scrub intents, window mapping and the resting-line state (shared-109).
//

import XCTest
@testable import StillMoment

@MainActor
extension GuidedMeditationPlayerViewModelTests {
    // MARK: - Waveform Loading (AK-1, AK-8)

    func testWaveformInitiallyNil() {
        XCTAssertNil(self.sut.waveform)
        XCTAssertFalse(self.sut.waveformLoadFailed)
    }

    func testWaveformLoadsSuccessfully() async {
        // Given a provider with a known waveform
        let known = MeditationWaveform(samples: [Float](repeating: 0.7, count: MeditationWaveform.sampleCount))
        self.mockWaveformProvider.fixedWaveform = known

        // When loading the waveform
        await self.sut.loadWaveform()

        // Then it is published and no failure is flagged
        XCTAssertEqual(self.sut.waveform, known)
        XCTAssertFalse(self.sut.waveformLoadFailed)
    }

    func testWaveformLoadFailureFallsBack() async {
        // Given generation fails (e.g. exotic format)
        self.mockWaveformProvider.waveformShouldThrow = true

        // When loading the waveform
        await self.sut.loadWaveform()

        // Then no waveform is set and the fallback flag is raised — player stays functional
        XCTAssertNil(self.sut.waveform)
        XCTAssertTrue(self.sut.waveformLoadFailed)
    }

    // MARK: - Scrub: grab pauses, release resumes (AK-2)

    func testBeginScrubPausesPlayback() async {
        // Given playback is running
        await self.sut.loadAudio()
        self.sut.playbackState = .playing

        // When grabbing the wave
        self.sut.beginScrub()

        // Then the drag starts and playback is paused
        XCTAssertTrue(self.sut.isDragging)
        XCTAssertTrue(self.mockPlayerService.pauseCalled)
    }

    func testEndScrubResumesWhenWasPlaying() async {
        // Given a drag that began while playing
        await self.sut.loadAudio()
        self.sut.playbackState = .playing
        self.sut.beginScrub()
        self.sut.scrub(to: 150)
        self.mockPlayerService.playCalled = false // isolate the resume call

        // When releasing inside the track
        self.sut.endScrub()

        // Then playback resumes from the new position
        XCTAssertFalse(self.sut.isDragging)
        XCTAssertEqual(self.mockPlayerService.seekTime, 150)
        XCTAssertTrue(self.mockPlayerService.playCalled)
    }

    func testEndScrubStaysPausedWhenWasPaused() async {
        // Given a drag that began while paused
        await self.sut.loadAudio()
        self.sut.playbackState = .paused
        self.sut.beginScrub()
        self.sut.scrub(to: 150)
        self.mockPlayerService.playCalled = false

        // When releasing
        self.sut.endScrub()

        // Then only the position changed — playback stays paused
        XCTAssertEqual(self.mockPlayerService.seekTime, 150)
        XCTAssertFalse(self.mockPlayerService.playCalled)
    }

    // MARK: - Scrub direction + anchoring (AK-3)

    func testBeginScrubAnchorsAtCurrentPosition() async {
        // Given the audio sits at 100s
        await self.sut.loadAudio()
        self.sut.currentTime = 100

        // When grabbing
        self.sut.beginScrub()

        // Then the drag is anchored at the current position
        XCTAssertEqual(self.sut.dragStartTime, 100, accuracy: 0.001)
        XCTAssertEqual(self.sut.dragPosition, 100, accuracy: 0.001)
    }

    func testScrubUpdatesDragPosition() async {
        await self.sut.loadAudio()
        self.sut.beginScrub()

        self.sut.scrub(to: 222)

        XCTAssertEqual(self.sut.dragPosition, 222, accuracy: 0.001)
    }

    // MARK: - Window center follows drag (display time)

    func testDisplayTimeFollowsDragWhileDragging() async {
        await self.sut.loadAudio()
        self.sut.currentTime = 100
        self.sut.beginScrub()
        self.sut.scrub(to: 150)

        XCTAssertEqual(self.sut.displayTime, 150, accuracy: 0.001)
    }

    func testDisplayTimeIsCurrentTimeWhenNotDragging() async {
        await self.sut.loadAudio()
        self.sut.currentTime = 100

        XCTAssertEqual(self.sut.displayTime, 100, accuracy: 0.001)
    }

    // MARK: - Trim window mapping (AK-6)

    func testScrubBoundsUntrimmed() {
        // The default test meditation has no trim → whole file
        XCTAssertEqual(self.sut.scrubBounds.lowerBound, 0, accuracy: 0.001)
        XCTAssertEqual(self.sut.scrubBounds.upperBound, 600, accuracy: 0.001)
    }

    func testScrubBoundsRespectTrim() {
        let vm = self.makeTrimmedViewModel()
        XCTAssertEqual(vm.scrubBounds.lowerBound, 120, accuracy: 0.001)
        XCTAssertEqual(vm.scrubBounds.upperBound, 1200, accuracy: 0.001)
    }

    func testScrubClampsToTrimStart() {
        let vm = self.makeTrimmedViewModel()
        vm.beginScrub()
        vm.scrub(to: 60) // before trim start
        XCTAssertEqual(vm.dragPosition, 120, accuracy: 0.001)
    }

    func testScrubClampsToTrimEnd() {
        let vm = self.makeTrimmedViewModel()
        vm.beginScrub()
        vm.scrub(to: 2000) // past trim end
        XCTAssertEqual(vm.dragPosition, 1200, accuracy: 0.001)
    }

    // MARK: - Mini overview: absolute seek (AK-5)

    func testSeekToFractionMapsToPosition() async {
        await self.sut.loadAudio() // untrimmed, 600s
        self.sut.seek(toFraction: 0.5)
        XCTAssertEqual(self.mockPlayerService.seekTime, 300)
    }

    func testSeekToFractionRespectsTrim() {
        let vm = self.makeTrimmedViewModel() // [120, 1200], 1080s playable
        vm.seek(toFraction: 0.5)
        XCTAssertEqual(self.mockPlayerService.seekTime, 660) // 120 + 540
    }

    func testSeekToFractionClampsAboveOne() {
        let vm = self.makeTrimmedViewModel()
        vm.seek(toFraction: 1.5)
        XCTAssertEqual(self.mockPlayerService.seekTime, 1200)
    }

    func testSeekToFractionClampsBelowZero() {
        let vm = self.makeTrimmedViewModel()
        vm.seek(toFraction: -0.5)
        XCTAssertEqual(self.mockPlayerService.seekTime, 120)
    }

    // MARK: - Live position + total (AK-4 drag readout)

    func testFormattedEffectiveDurationUntrimmed() {
        XCTAssertEqual(self.sut.formattedEffectiveDuration, "10:00")
    }

    func testFormattedEffectiveDurationRespectsTrim() {
        let vm = self.makeTrimmedViewModel() // 1200 - 120 = 1080s = 18:00
        XCTAssertEqual(vm.formattedEffectiveDuration, "18:00")
    }

    func testFormattedPositionRelativeToTrim() {
        let vm = self.makeTrimmedViewModel()
        vm.beginScrub()
        vm.scrub(to: 240) // 240 - 120 = 120s = 2:00 into the trimmed range
        XCTAssertEqual(vm.formattedPosition, "2:00")
    }

    // MARK: - Resting line state (AK-4)

    func testRemainingLineWhilePlaying() async {
        await self.sut.loadAudio()
        self.sut.currentTime = 100
        self.sut.playbackState = .playing

        // 600 - 100 = 500s = 8:20
        XCTAssertEqual(self.sut.remainingLineState, .remaining("8:20"))
    }

    func testRemainingLineWhenPaused() async {
        await self.sut.loadAudio()
        self.sut.playbackState = .paused

        XCTAssertEqual(self.sut.remainingLineState, .paused)
    }

    func testRemainingLineWhenFinished() async {
        await self.sut.loadAudio()
        self.sut.playbackState = .finished

        XCTAssertEqual(self.sut.remainingLineState, .finished)
    }

    // MARK: - Helpers

    /// A player VM over a meditation trimmed to [120, 1200] (18:00 playable of a 22:00 file).
    private func makeTrimmedViewModel() -> GuidedMeditationPlayerViewModel {
        let trimmed = GuidedMeditation(
            fileBookmark: Data("bookmark".utf8),
            fileName: "trimmed.mp3",
            duration: 1320,
            teacher: "Test Teacher",
            name: "Trimmed Meditation",
            trimStart: 120,
            trimEnd: 1200
        )
        return GuidedMeditationPlayerViewModel(
            meditation: trimmed,
            playerService: self.mockPlayerService,
            meditationService: self.mockMeditationService,
            waveformProvider: self.mockWaveformProvider
        )
    }
}
