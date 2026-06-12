//
//  TrimEditorViewModelTests.swift
//  Still Moment
//
//  Tests for the waveform trim editor ViewModel (shared-107, reworked touch concept).
//

import XCTest
@testable import StillMoment

@MainActor
final class TrimEditorViewModelTests: XCTestCase {
    // MARK: Lifecycle

    override func setUp() {
        super.setUp()
        self.audio = MockAudioService()
        self.provider = MockWaveformProvider()
        self.service = MockGuidedMeditationService()
        self.meditation = GuidedMeditation(
            localFilePath: "meditation.mp3",
            fileName: "meditation.mp3",
            duration: 1145,
            teacher: "Tara Goldstein",
            name: "Evening Wind Down"
        )
    }

    // MARK: Internal

    func testWaveformLoadSuccessExposesSamples() async {
        let expected = MeditationWaveform(samples: [Float](repeating: 0.3, count: MeditationWaveform.sampleCount))
        self.provider.fixedWaveform = expected
        let sut = self.makeSUT()

        sut.loadWaveform()
        await self.drainMainQueue()

        XCTAssertEqual(sut.waveform, expected)
        XCTAssertFalse(sut.waveformLoadFailed)
        XCTAssertFalse(sut.isLoadingWaveform)
    }

    func testWaveformLoadFailureSetsFallbackFlag() async {
        self.provider.waveformShouldThrow = true
        let sut = self.makeSUT()

        sut.loadWaveform()
        await self.drainMainQueue()

        XCTAssertNil(sut.waveform)
        XCTAssertTrue(sut.waveformLoadFailed)
        XCTAssertFalse(sut.isLoadingWaveform)
    }

    func testStartsInLoadingStateBeforeLoad() {
        let sut = self.makeSUT()

        XCTAssertTrue(sut.isLoadingWaveform)
        XCTAssertNil(sut.waveform)
        XCTAssertFalse(sut.waveformLoadFailed)
    }

    // MARK: - Playhead seeding

    func testPlayheadStartsAtEffectiveStart() {
        self.meditation.trimStart = 84

        let sut = self.makeSUT()

        XCTAssertEqual(sut.playheadTime, 84)
    }

    // MARK: - Selecting a point (readout cards)

    func testSelectPointMovesPlayheadToThatPoint() {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)
        sut.markDragEnded()

        sut.selectPoint(.end)

        XCTAssertEqual(sut.editorState.activePoint, .end)
        XCTAssertEqual(sut.playheadTime, 600)
    }

    func testSelectPointWhilePlayingSeeksAndKeepsPlaying() {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)
        sut.selectPoint(.start)
        sut.togglePlayback()
        self.audio.lastSeekMeditationPreviewTime = nil

        sut.selectPoint(.end)

        XCTAssertTrue(sut.isPlaying)
        XCTAssertEqual(self.audio.lastSeekMeditationPreviewTime, 600)
    }

    // MARK: - Dragging marks (lower zone)

    func testMovePointClampsViaDomain() {
        let sut = self.makeSUT()

        // Beyond end - minimumRange must clamp.
        sut.movePoint(.start, to: 5000)

        XCTAssertEqual(sut.editorState.start, sut.editorState.end - TrimEditorState.minimumRange, accuracy: 0.001)
    }

    func testMovePointDuringDragDoesNotTouchAudio() {
        let sut = self.makeSUT()

        sut.movePoint(.start, to: 100)

        XCTAssertFalse(self.audio.playMeditationPreviewCalled)
        XCTAssertFalse(self.audio.seekMeditationPreviewCalled)
    }

    func testMarkDragEndedMovesPlayheadToMarkAndPlaysShortPreview() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 100)

        sut.markDragEnded()

        XCTAssertEqual(sut.playheadTime, 100)
        XCTAssertTrue(sut.isPreviewing)
        XCTAssertFalse(sut.isPlaying)
        XCTAssertTrue(self.audio.playMeditationPreviewCalled)
        XCTAssertEqual(self.audio.lastSeekMeditationPreviewTime, 100)
    }

    func testPreviewStopsAfterItsDurationAndRestoresPlayhead() async {
        let sut = self.makeSUT(previewDurations: .test)
        sut.movePoint(.start, to: 100)

        sut.markDragEnded()
        self.audio.meditationPreviewPositionSubject.send(100.4)
        await self.drainMainQueue()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(sut.isPreviewing)
        XCTAssertTrue(self.audio.stopMeditationPreviewCalled)
        XCTAssertEqual(sut.playheadTime, 100)
    }

    func testMarkDragEndedWhilePlayingReplacesPlaybackWithPreview() {
        let sut = self.makeSUT()
        sut.togglePlayback()

        sut.movePoint(.start, to: 100)
        sut.markDragEnded()

        XCTAssertFalse(sut.isPlaying)
        XCTAssertTrue(sut.isPreviewing)
        XCTAssertEqual(sut.playheadTime, 100)
    }

    func testPositionPublisherMovesPlayheadDuringPreview() async {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 100)
        sut.markDragEnded()

        self.audio.meditationPreviewPositionSubject.send(101)
        await self.drainMainQueue()

        XCTAssertEqual(sut.playheadTime, 101)
    }

    // MARK: - Nudging

    func testNudgeMovesMarkAndPlayheadAndPlaysShortPreview() {
        let sut = self.makeSUT()
        sut.selectPoint(.start)

        sut.nudgeActivePoint(by: 1)

        XCTAssertEqual(sut.editorState.start, 1, accuracy: 0.001)
        XCTAssertEqual(sut.playheadTime, 1)
        XCTAssertTrue(sut.isPreviewing)
        XCTAssertFalse(sut.isPlaying)
        XCTAssertTrue(self.audio.playMeditationPreviewCalled)
    }

    // MARK: - Seeking the playhead (upper zone)

    func testSeekMovesPlayheadWithoutTouchingMarks() {
        let sut = self.makeSUT()

        sut.seek(to: 300)

        XCTAssertEqual(sut.playheadTime, 300)
        XCTAssertEqual(sut.editorState.start, 0)
        XCTAssertEqual(sut.editorState.end, self.meditation.duration)
        XCTAssertFalse(self.audio.playMeditationPreviewCalled)
    }

    func testSeekWhilePlayingPausesFirst() {
        let sut = self.makeSUT()
        sut.togglePlayback()

        sut.seek(to: 300)

        XCTAssertFalse(sut.isPlaying)
        XCTAssertTrue(self.audio.stopMeditationPreviewCalled)
        XCTAssertEqual(sut.playheadTime, 300)
    }

    func testSeekCancelsRunningPreview() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 100)
        sut.markDragEnded()

        sut.seek(to: 300)

        XCTAssertFalse(sut.isPreviewing)
        XCTAssertTrue(self.audio.stopMeditationPreviewCalled)
        XCTAssertEqual(sut.playheadTime, 300)
    }

    func testSeekClampsToFileBounds() {
        let sut = self.makeSUT()

        sut.seek(to: -5)
        XCTAssertEqual(sut.playheadTime, 0)

        sut.seek(to: self.meditation.duration + 100)
        XCTAssertEqual(sut.playheadTime, self.meditation.duration)
    }

    // MARK: - Playback

    func testTogglePlaybackStartsFromPlayhead() {
        let sut = self.makeSUT()
        sut.seek(to: 300)

        sut.togglePlayback()

        XCTAssertTrue(sut.isPlaying)
        XCTAssertTrue(self.audio.playMeditationPreviewCalled)
        XCTAssertEqual(self.audio.lastSeekMeditationPreviewTime, 300)
    }

    func testPauseKeepsPlayheadPosition() async {
        let sut = self.makeSUT()
        sut.togglePlayback()
        self.audio.meditationPreviewPositionSubject.send(42)
        await self.drainMainQueue()

        sut.togglePlayback()

        XCTAssertFalse(sut.isPlaying)
        XCTAssertTrue(self.audio.stopMeditationPreviewCalled)
        XCTAssertEqual(sut.playheadTime, 42)
    }

    func testResumeContinuesFromPausedPosition() async {
        let sut = self.makeSUT()
        sut.togglePlayback()
        self.audio.meditationPreviewPositionSubject.send(42)
        await self.drainMainQueue()
        sut.togglePlayback()

        sut.togglePlayback()

        XCTAssertTrue(sut.isPlaying)
        XCTAssertEqual(self.audio.lastSeekMeditationPreviewTime, 42)
    }

    func testTogglePlaybackDuringPreviewSwitchesToFullPlayback() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 100)
        sut.markDragEnded()

        sut.togglePlayback()

        XCTAssertTrue(sut.isPlaying)
        XCTAssertFalse(sut.isPreviewing)
        XCTAssertEqual(self.audio.lastSeekMeditationPreviewTime, 100)
    }

    func testPlaybackPausesWhenReachingEndPoint() async {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)
        sut.selectPoint(.start)
        sut.togglePlayback()

        self.audio.meditationPreviewPositionSubject.send(601)
        await self.drainMainQueue()

        XCTAssertFalse(sut.isPlaying)
        XCTAssertTrue(self.audio.stopMeditationPreviewCalled)
        XCTAssertEqual(sut.playheadTime, 600)
    }

    func testSeekPastEndThenPlayRunsToFileEnd() async {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)
        sut.seek(to: 700)
        sut.togglePlayback()

        self.audio.meditationPreviewPositionSubject.send(800)
        await self.drainMainQueue()

        XCTAssertTrue(sut.isPlaying)
        XCTAssertEqual(sut.playheadTime, 800)
    }

    func testPlayFromEndPointRunsPastEndToFileEnd() async {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)
        sut.markDragEnded()

        sut.togglePlayback()
        self.audio.meditationPreviewPositionSubject.send(700)
        await self.drainMainQueue()

        XCTAssertTrue(sut.isPlaying)
        XCTAssertEqual(sut.playheadTime, 700)
    }

    // MARK: - Whole file

    func testUseWholeFileResetsRangeAndPlayhead() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 100)
        sut.movePoint(.end, to: 600)
        sut.togglePlayback()

        sut.useWholeFile()

        XCTAssertEqual(sut.editorState.start, 0)
        XCTAssertEqual(sut.editorState.end, self.meditation.duration)
        XCTAssertEqual(sut.editorState.activePoint, .start)
        XCTAssertEqual(sut.playheadTime, 0)
        XCTAssertFalse(sut.isPlaying)
    }

    // MARK: - Lifecycle / publishers

    func testViewDisappearedStopsAudio() {
        let sut = self.makeSUT()
        sut.togglePlayback()

        sut.viewDisappeared()

        XCTAssertTrue(self.audio.stopMeditationPreviewCalled)
        XCTAssertFalse(sut.isPlaying)
        XCTAssertFalse(sut.isPreviewing)
    }

    func testPositionPublisherUpdatesPlayheadDuringPlayback() async {
        let sut = self.makeSUT()
        sut.togglePlayback()

        self.audio.meditationPreviewPositionSubject.send(42)
        await self.drainMainQueue()

        XCTAssertEqual(sut.playheadTime, 42)
    }

    func testPositionPublisherIgnoredWhenIdle() async {
        let sut = self.makeSUT()

        self.audio.meditationPreviewPositionSubject.send(99)
        await self.drainMainQueue()

        XCTAssertEqual(sut.playheadTime, 0)
    }

    func testCompletionPublisherResetsPlaying() async {
        let sut = self.makeSUT()
        sut.togglePlayback()

        self.audio.meditationPreviewCompletionSubject.send()
        await self.drainMainQueue()

        XCTAssertFalse(sut.isPlaying)
        XCTAssertFalse(sut.isPreviewing)
    }

    // MARK: Private

    // swiftlint:disable implicitly_unwrapped_optional
    private var audio: MockAudioService!
    private var provider: MockWaveformProvider!
    private var service: MockGuidedMeditationService!
    private var meditation: GuidedMeditation!
    // swiftlint:enable implicitly_unwrapped_optional

    private func makeSUT(previewDurations: TrimPreviewDurations = .standard) -> TrimEditorViewModel {
        TrimEditorViewModel(
            meditation: self.meditation,
            audioService: self.audio,
            waveformProvider: self.provider,
            meditationService: self.service,
            previewDurations: previewDurations
        )
    }

    /// Lets queued main-actor continuations (Combine `.receive(on:)`, async loads) run.
    private func drainMainQueue() async {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
}

extension TrimPreviewDurations {
    /// Tiny durations so auto-stop can be asserted without slowing the suite.
    static let test = TrimPreviewDurations(afterMarkDrag: 0.05, afterNudge: 0.05)
}
