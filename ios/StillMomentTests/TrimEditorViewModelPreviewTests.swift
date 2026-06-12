//
//  TrimEditorViewModelPreviewTests.swift
//  Still Moment
//
//  Tests for the audition previews of the trim editor (shared-108):
//  previews respect the audible window [start, end] — the end point is auditioned
//  with the last seconds INSIDE the range, never with audio the selection cuts off.
//

import XCTest
@testable import StillMoment

@MainActor
final class TrimEditorViewModelPreviewTests: XCTestCase {
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

    func testStartMarkPreviewPlaysFromTheMark() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 100)

        sut.markDragEnded()

        XCTAssertTrue(sut.isPreviewing)
        XCTAssertEqual(self.audio.lastSeekMeditationPreviewTime, 100)
    }

    func testEndMarkPreviewPlaysTheLastSecondsUpToTheMark() {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)

        sut.markDragEnded()

        // 2.2 s audition window ends AT the mark — it never plays cut-off audio.
        XCTAssertTrue(sut.isPreviewing)
        XCTAssertEqual(self.audio.lastSeekMeditationPreviewTime ?? 0, 597.8, accuracy: 0.001)
    }

    func testEndMarkPreviewStopsAtTheMarkWhenPositionReachesIt() async {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)
        sut.markDragEnded()

        self.audio.meditationPreviewPositionSubject.send(600.2)
        await self.drainMainQueue()

        XCTAssertFalse(sut.isPreviewing)
        XCTAssertTrue(self.audio.stopMeditationPreviewCalled)
        XCTAssertEqual(sut.playheadTime, 600)
    }

    func testEndMarkPreviewParksPlayheadAtTheMark() async {
        let sut = self.makeSUT(previewDurations: .test)
        sut.movePoint(.end, to: 600)

        sut.markDragEnded()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(sut.isPreviewing)
        XCTAssertEqual(sut.playheadTime, 600)
    }

    func testEndNudgePreviewPlaysUpToTheMark() {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)

        sut.nudgeActivePoint(by: -1)

        // 1.4 s nudge audition ends at the nudged mark (599 s).
        XCTAssertEqual(self.audio.lastSeekMeditationPreviewTime ?? 0, 597.6, accuracy: 0.001)
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

    /// Lets queued main-actor continuations (Combine `.receive(on:)`) run.
    private func drainMainQueue() async {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
}
