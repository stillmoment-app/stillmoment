//
//  GongSelectionLogicTests.swift
//  Still Moment
//
//  Presentation Tests — pure layout decisions for gong selection (shared-115/shared-116).
//

import XCTest
@testable import StillMoment

final class GongSelectionLogicTests: XCTestCase {
    // MARK: - Volume card visibility (shared-115)

    func testVolumeCardVisibleForAudibleGong() {
        XCTAssertTrue(GongSelectionLogic.isVolumeCardVisible(soundId: GongSound.defaultSoundId))
    }

    func testVolumeCardHiddenForVibration() {
        XCTAssertFalse(GongSelectionLogic.isVolumeCardVisible(soundId: GongSound.vibrationId))
    }

    // MARK: - Sound list visibility in the editor (shared-116)

    func testSoundListHiddenWhenNoGongEnabled() {
        XCTAssertFalse(
            GongSelectionLogic.isSoundListVisible(startGongEnabled: false, endGongEnabled: false)
        )
    }

    func testSoundListVisibleWhenStartGongEnabled() {
        XCTAssertTrue(
            GongSelectionLogic.isSoundListVisible(startGongEnabled: true, endGongEnabled: false)
        )
    }

    func testSoundListVisibleWhenEndGongEnabled() {
        XCTAssertTrue(
            GongSelectionLogic.isSoundListVisible(startGongEnabled: false, endGongEnabled: true)
        )
    }

    func testSoundListVisibleWhenBothGongsEnabled() {
        XCTAssertTrue(
            GongSelectionLogic.isSoundListVisible(startGongEnabled: true, endGongEnabled: true)
        )
    }
}
