//
//  StringNonBlankTrimmedTests.swift
//  Still Moment
//
//  shared-128: Leere Werte aus Datei-Tags und Podcast-Verzeichnis zaehlen als fehlend.
//

import XCTest
@testable import StillMoment

final class StringNonBlankTrimmedTests: XCTestCase {
    func testWhitespaceAtTheEdgesIsRemoved() {
        XCTAssertEqual("  Body Scan (20:34 Min.)\n".nonBlankTrimmed, "Body Scan (20:34 Min.)")
    }

    func testBlankValueCountsAsMissing() {
        XCTAssertNil(" \n ".nonBlankTrimmed)
    }
}
