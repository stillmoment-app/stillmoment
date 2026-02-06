//
//  ColorThemeTests.swift
//  Still Moment
//
//  Unit tests for ColorTheme domain model.
//

import XCTest
@testable import StillMoment

final class ColorThemeTests: XCTestCase {
    func testDefaultIsCandlelight() {
        XCTAssertEqual(ColorTheme.default, .candlelight)
    }

    func testAllCasesContainsAllThemesInPickerOrder() {
        XCTAssertEqual(
            ColorTheme.allCases,
            [.candlelight, .forest, .moon]
        )
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
        XCTAssertEqual(ColorTheme.candlelight.rawValue, "candlelight")
        XCTAssertEqual(ColorTheme.forest.rawValue, "forest")
        XCTAssertEqual(ColorTheme.moon.rawValue, "moon")
    }
}
