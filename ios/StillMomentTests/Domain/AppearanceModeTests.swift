//
//  AppearanceModeTests.swift
//  Still Moment
//
//  Unit tests for AppearanceMode domain model.
//

import XCTest
@testable import StillMoment

final class AppearanceModeTests: XCTestCase {
    func testDefaultIsSystem() {
        XCTAssertEqual(AppearanceMode.default, .system)
    }

    func testAllCasesContainsAllModesInPickerOrder() {
        XCTAssertEqual(
            AppearanceMode.allCases,
            [.system, .light, .dark]
        )
    }

    func testRawValueRoundtrip() {
        for mode in AppearanceMode.allCases {
            let encoded = mode.rawValue
            let decoded = AppearanceMode(rawValue: encoded)
            XCTAssertEqual(decoded, mode, "Roundtrip failed for \(mode)")
        }
    }

    func testRawValuesAreStable() {
        // Raw values are used for @AppStorage persistence - changing them breaks user preferences
        XCTAssertEqual(AppearanceMode.system.rawValue, "system")
        XCTAssertEqual(AppearanceMode.light.rawValue, "light")
        XCTAssertEqual(AppearanceMode.dark.rawValue, "dark")
    }
}
