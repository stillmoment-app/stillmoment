//
//  AudioServiceInterruptionTests+DuringInterruption.swift
//  Still Moment
//
//  Timer sounds that become due while an interruption lasts (shared-147)
//

import AVFoundation
import XCTest
@testable import StillMoment

extension AudioServiceInterruptionTests {
    // MARK: - Gongs due during the interruption

    func testStartGongDueDuringInterruption_isSkippedAndEndsAtOnce() async throws {
        // Given: a phone call is going on
        try self.sut.activateTimerSession()
        await self.postInterruptionBegan()

        // When: the preparation ends
        try self.sut.playStartGong(soundId: GongSound.defaultSoundId, volume: 0.8)

        // Then: no gong into the call, the meditation begins right away
        XCTAssertFalse(self.sut.isTimerGongPlaying)
        XCTAssertEqual(self.gongEnds, 1)
    }

    func testEndGongDueDuringInterruption_isSkippedAndEndsAtOnce() async throws {
        // Given
        try self.sut.activateTimerSession()
        await self.postInterruptionBegan()

        // When: the meditation time runs out during the call
        try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 0.8)

        // Then
        XCTAssertFalse(self.sut.isTimerGongPlaying)
        XCTAssertEqual(self.gongEnds, 1)
    }

    func testIntervalGongDueDuringInterruption_isDropped() async throws {
        // Given
        try self.sut.activateTimerSession()
        await self.postInterruptionBegan()

        // When
        try self.sut.playIntervalGong(soundId: GongSound.defaultSoundId, volume: 0.8)

        // Then
        XCTAssertFalse(self.sut.isTimerGongPlaying)
    }

    func testInterruptionOverWithoutRelease_gongsPlayAgain() async throws {
        // Given: the call ended, the system did not give the sound back
        try self.sut.activateTimerSession()
        await self.postInterruptionBegan()
        await self.postInterruptionEnded(shouldResume: false)

        // When
        try self.sut.playIntervalGong(soundId: GongSound.defaultSoundId, volume: 0.8)

        // Then
        XCTAssertTrue(self.sut.isTimerGongPlaying)
    }

    func testTimerResetDuringInterruption_nextTimerPlaysItsGong() async throws {
        // Given: the user reset the timer during a call
        try self.sut.activateTimerSession()
        await self.postInterruptionBegan()
        self.sut.stop()
        self.sut.deactivateTimerSession()

        // When: a new timer starts
        try self.sut.activateTimerSession()
        try self.sut.playStartGong(soundId: GongSound.defaultSoundId, volume: 0.8)

        // Then
        XCTAssertTrue(self.sut.isTimerGongPlaying)
        XCTAssertEqual(self.gongEnds, 0)
    }

    func testGongThatCannotStart_endsExactlyOnce() throws {
        // Given: a gong player the system refuses to start
        let url = try XCTUnwrap(
            Bundle.main.url(
                forResource: "tibetan-singing-bowl-55786-10s",
                withExtension: "mp3",
                subdirectory: "GongSounds"
            )
        )
        let player = try RefusingAudioPlayer(contentsOf: url)

        // When
        self.sut.startTimerGong(player)

        // Then
        XCTAssertEqual(self.gongEnds, 1)
        XCTAssertFalse(self.sut.isTimerGongPlaying)
    }

    // MARK: - Background sound due during the interruption

    func testBackgroundSoundDueDuringInterruption_startsWhenSoundGivenBack() async throws {
        // Given: the start gong ended during a call, the background sound is due
        try self.sut.activateTimerSession()
        await self.postInterruptionBegan()
        try self.sut.startBackgroundAudio(soundId: Self.audibleSoundId, volume: 0.15)
        XCTAssertFalse(self.sut.isBackgroundAudioPlaying)

        // When
        await self.postInterruptionEnded(shouldResume: true)

        // Then
        XCTAssertTrue(self.sut.isBackgroundAudioPlaying)
    }

    func testBackgroundSoundDueDuringInterruption_staysOffWithoutRelease() async throws {
        // Given
        try self.sut.activateTimerSession()
        await self.postInterruptionBegan()
        try self.sut.startBackgroundAudio(soundId: Self.audibleSoundId, volume: 0.15)

        // When
        await self.postInterruptionEnded(shouldResume: false)

        // Then
        XCTAssertFalse(self.sut.isBackgroundAudioPlaying)
    }
}

/// An audio player that never starts, like AVAudioPlayer without a usable audio session
private final class RefusingAudioPlayer: AVAudioPlayer {
    override func play() -> Bool {
        false
    }
}
