//
//  GuidedMeditationEditSheetModeTests.swift
//  Still Moment
//
//  Unit tests for the pure mode logic of GuidedMeditationEditSheet (ios-044).
//

import XCTest
@testable import StillMoment

final class GuidedMeditationEditSheetModeTests: XCTestCase {
    // MARK: - Save button keys

    func testImportModeUsesImportAction() {
        let mode = GuidedMeditationEditSheetMode.importMode

        XCTAssertEqual(mode.saveButtonKey, "guided_meditations.import.action")
    }

    func testEditModeUsesCommonSave() {
        let mode = GuidedMeditationEditSheetMode.edit

        XCTAssertEqual(mode.saveButtonKey, "common.save")
    }

    // MARK: - Autofocus rule

    func testImportModeAutofocusesNameWhenPrefillIsEmpty() {
        let mode = GuidedMeditationEditSheetMode.importMode

        XCTAssertTrue(mode.shouldAutofocusName(prefilledName: ""))
    }

    func testImportModeAutofocusesNameWhenPrefillIsWhitespaceOnly() {
        let mode = GuidedMeditationEditSheetMode.importMode

        XCTAssertTrue(mode.shouldAutofocusName(prefilledName: "   "))
    }

    func testImportModeDoesNotAutofocusWhenPrefillIsPresent() {
        let mode = GuidedMeditationEditSheetMode.importMode

        XCTAssertFalse(mode.shouldAutofocusName(prefilledName: "bodyscan"))
    }

    func testEditModeNeverAutofocuses() {
        let mode = GuidedMeditationEditSheetMode.edit

        XCTAssertFalse(mode.shouldAutofocusName(prefilledName: ""))
        XCTAssertFalse(mode.shouldAutofocusName(prefilledName: "Existing Name"))
    }
}
