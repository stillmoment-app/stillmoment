//
//  FontLicenseTests.swift
//  Still Moment
//
//  shared-136: The OFL text shipped with the fonts must be readable in the app.
//

import XCTest
@testable import StillMoment

final class FontLicenseTests: XCTestCase {
    func testLicenseTextShippedWithAppStartsWithFontCopyrights() throws {
        // When
        let text = try XCTUnwrap(FontLicense.loadText(from: .main), "OFL.txt not found in app bundle")

        // Then
        let firstLines = Array(text.components(separatedBy: .newlines).prefix(2))
        XCTAssertEqual(firstLines.count, 2)
        XCTAssertTrue(firstLines.first?.hasPrefix("Copyright 2020 The Newsreader Project Authors") ?? false)
        XCTAssertTrue(firstLines.last?.hasPrefix("Copyright 2024 The Geist Project Authors") ?? false)
    }

    func testLicenseTextShippedWithAppIsCompleteUpToDisclaimerEnd() throws {
        // When
        let text = try XCTUnwrap(FontLicense.loadText(from: .main), "OFL.txt not found in app bundle")

        // Then
        XCTAssertTrue(
            text.trimmingCharacters(in: .whitespacesAndNewlines)
                .hasSuffix("OTHER DEALINGS IN THE FONT SOFTWARE.")
        )
    }

    func testMissingLicenseFileYieldsNoTextInsteadOfCrashing() {
        // Given: the unit test bundle does not contain OFL.txt
        let bundleWithoutLicense = Bundle(for: FontLicenseTests.self)

        // When
        let text = FontLicense.loadText(from: bundleWithoutLicense)

        // Then
        XCTAssertNil(text)
    }
}
