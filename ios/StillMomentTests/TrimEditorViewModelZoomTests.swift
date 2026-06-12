//
//  TrimEditorViewModelZoomTests.swift
//  Still Moment
//
//  Tests for the zoom window of the waveform trim editor (shared-108).
//

import XCTest
@testable import StillMoment

@MainActor
final class TrimEditorViewModelZoomTests: XCTestCase {
    // MARK: Lifecycle

    override func setUp() {
        super.setUp()
        self.audio = MockAudioService()
        self.provider = MockWaveformProvider()
        self.service = MockGuidedMeditationService()
        // Reference file from the design handoff: 19:05 = 1145 s → zoom span 206 s.
        self.meditation = GuidedMeditation(
            localFilePath: "meditation.mp3",
            fileName: "meditation.mp3",
            duration: 1145,
            teacher: "Tara Goldstein",
            name: "Evening Wind Down"
        )
    }

    // MARK: Internal

    // MARK: - Initial state

    func testWindowStartsAsWholeFile() {
        let sut = self.makeSUT()

        XCTAssertEqual(sut.window, 0...1145)
        XCTAssertFalse(sut.isZoomed)
    }

    // MARK: - Auto-zoom via card / edge-chip tap

    func testFocusPointFramesEndMarkAndAnchorsPlayhead() {
        let sut = self.makeSUT()

        sut.focusPoint(.end)

        XCTAssertEqual(sut.editorState.activePoint, .end)
        XCTAssertEqual(sut.window.lowerBound, 939, accuracy: 0.001)
        XCTAssertEqual(sut.window.upperBound, 1145, accuracy: 0.001)
        XCTAssertTrue(sut.isZoomed)
        XCTAssertEqual(sut.playheadTime, 1145)
    }

    func testFocusPointFramesStartMarkClampedAtFileStart() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 30)

        sut.focusPoint(.start)

        XCTAssertEqual(sut.window.lowerBound, 0, accuracy: 0.001)
        XCTAssertEqual(sut.window.upperBound, 206, accuracy: 0.001)
        XCTAssertTrue(sut.isZoomed)
    }

    func testFocusPointOnShortFileNeverZooms() {
        self.meditation = GuidedMeditation(
            localFilePath: "short.mp3",
            fileName: "short.mp3",
            duration: 90,
            teacher: "Tara Goldstein",
            name: "Short Practice"
        )
        let sut = self.makeSUT()

        sut.focusPoint(.start)

        XCTAssertEqual(sut.window, 0...90)
        XCTAssertFalse(sut.isZoomed)
    }

    // MARK: - Recentering

    func testWindowStaysFixedWhileDragging() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 100)
        sut.focusPoint(.start)
        let windowDuringDrag = sut.window

        sut.movePoint(.start, to: 180)

        XCTAssertEqual(sut.window, windowDuringDrag)
    }

    func testMarkDragEndRecentersWindowWhenZoomed() {
        let sut = self.makeSUT()
        sut.focusPoint(.start)
        sut.movePoint(.start, to: 150)

        sut.markDragEnded()

        // frame(around: 150, .start): 150 − 206·0.25 = 98.5
        XCTAssertEqual(sut.window.lowerBound, 98.5, accuracy: 0.001)
        XCTAssertEqual(sut.window.upperBound, 304.5, accuracy: 0.001)
    }

    func testMarkDragEndKeepsWholeFileInOverview() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 150)

        sut.markDragEnded()

        XCTAssertEqual(sut.window, 0...1145)
        XCTAssertFalse(sut.isZoomed)
    }

    func testNudgeRecentersWindowWhenZoomed() {
        let sut = self.makeSUT()
        sut.movePoint(.start, to: 100)
        sut.focusPoint(.start)

        sut.nudgeActivePoint(by: 1)

        // Mark moved to 101 → window 49.5…255.5; the nudge preview still plays.
        XCTAssertEqual(sut.editorState.start, 101, accuracy: 0.001)
        XCTAssertEqual(sut.window.lowerBound, 49.5, accuracy: 0.001)
        XCTAssertEqual(sut.window.upperBound, 255.5, accuracy: 0.001)
        XCTAssertTrue(sut.isPreviewing)
    }

    func testNudgeKeepsWholeFileInOverview() {
        let sut = self.makeSUT()
        sut.selectPoint(.start)

        sut.nudgeActivePoint(by: 1)

        XCTAssertEqual(sut.window, 0...1145)
    }

    func testSeekNeverRecentersWindow() {
        let sut = self.makeSUT()
        sut.focusPoint(.start)
        let zoomedWindow = sut.window

        sut.seek(to: 600)

        XCTAssertEqual(sut.window, zoomedWindow)
    }

    // MARK: - Zoom out

    func testZoomOutKeepsMarksAndPlayhead() {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)
        sut.focusPoint(.end)

        sut.zoomOut()

        XCTAssertEqual(sut.window, 0...1145)
        XCTAssertFalse(sut.isZoomed)
        XCTAssertEqual(sut.editorState.end, 600, accuracy: 0.001)
        XCTAssertEqual(sut.playheadTime, 600)
    }

    func testUseWholeFileResetsWindowToo() {
        let sut = self.makeSUT()
        sut.focusPoint(.end)

        sut.useWholeFile()

        XCTAssertEqual(sut.window, 0...1145)
        XCTAssertEqual(sut.editorState.start, 0)
        XCTAssertEqual(sut.editorState.end, 1145)
    }

    // MARK: - Minimap pan

    func testPanWindowMovesWindowKeepingSpan() {
        let sut = self.makeSUT()
        sut.focusPoint(.end)

        sut.panWindow(toCenter: 572)

        XCTAssertEqual(sut.window.lowerBound, 469, accuracy: 0.001)
        XCTAssertEqual(sut.window.upperBound, 675, accuracy: 0.001)
        XCTAssertTrue(sut.isZoomed)
    }

    func testPanWindowClampsAtFileStart() {
        let sut = self.makeSUT()
        sut.focusPoint(.end)

        sut.panWindow(toCenter: 0)

        XCTAssertEqual(sut.window.lowerBound, 0, accuracy: 0.001)
        XCTAssertEqual(sut.window.upperBound, 206, accuracy: 0.001)
    }

    func testPanWindowKeepsMarksUntouched() {
        let sut = self.makeSUT()
        sut.movePoint(.end, to: 600)
        sut.focusPoint(.end)

        sut.panWindow(toCenter: 200)

        XCTAssertEqual(sut.editorState.start, 0)
        XCTAssertEqual(sut.editorState.end, 600, accuracy: 0.001)
    }

    // MARK: Private

    // swiftlint:disable implicitly_unwrapped_optional
    private var audio: MockAudioService!
    private var provider: MockWaveformProvider!
    private var service: MockGuidedMeditationService!
    private var meditation: GuidedMeditation!
    // swiftlint:enable implicitly_unwrapped_optional

    private func makeSUT() -> TrimEditorViewModel {
        TrimEditorViewModel(
            meditation: self.meditation,
            audioService: self.audio,
            waveformProvider: self.provider,
            meditationService: self.service
        )
    }
}
