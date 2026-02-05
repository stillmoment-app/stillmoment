//
//  ColorThemeTests.swift
//  Still Moment
//
//  Unit tests for ColorTheme domain model.
//

import XCTest
@testable import StillMoment

final class ColorThemeTests: XCTestCase {
    func testDefaultIsWarmDesert() {
        XCTAssertEqual(ColorTheme.default, .warmDesert)
    }

    func testAllCasesContainsBothThemes() {
        XCTAssertEqual(ColorTheme.allCases, [.warmDesert, .darkWarm])
    }

    func testRawValueRoundtrip() {
        for theme in ColorTheme.allCases {
            let encoded = theme.rawValue
            let decoded = ColorTheme(rawValue: encoded)
            XCTAssertEqual(decoded, theme, "Roundtrip failed for \(theme)")
        }
    }

    func testRawValuesAreStable() {
        // Raw values are used for @AppStorage persistence - changing them breaks user preferences
        XCTAssertEqual(ColorTheme.warmDesert.rawValue, "warmDesert")
        XCTAssertEqual(ColorTheme.darkWarm.rawValue, "darkWarm")
    }
}
