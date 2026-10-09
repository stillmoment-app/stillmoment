//
//  FeedbackLinksTests.swift
//  Still Moment
//
//  shared-134: App bewerten (App Store) und Schreib uns (Mail an hello@stillmoment.app).
//

import XCTest
@testable import StillMoment

final class FeedbackLinksTests: XCTestCase {
    // MARK: - App bewerten

    func testRateAppOpensStillMomentInAppStoreForWritingAReview() throws {
        let url = try XCTUnwrap(FeedbackLinks.rateAppURL)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "apps.apple.com")
        XCTAssertEqual(components.path, "/app/id6755774465")
        XCTAssertEqual(components.queryItems?.first { $0.name == "action" }?.value, "write-review")
    }

    // MARK: - Schreib uns

    func testWriteToUsAddressesMailToStillMoment() throws {
        let components = try self.writeToUsComponents()

        XCTAssertEqual(components.scheme, "mailto")
        XCTAssertEqual(components.path, "hello@stillmoment.app")
        XCTAssertEqual(FeedbackLinks.contactAddress, "hello@stillmoment.app")
    }

    func testWriteToUsHasSubjectStillMoment() throws {
        let components = try self.writeToUsComponents()

        XCTAssertEqual(self.value(of: "subject", in: components), "Still Moment")
    }

    func testWriteToUsBodyStartsWithTwoEmptyLinesFollowedByVersionLine() throws {
        let components = try self.writeToUsComponents()
        let body = try XCTUnwrap(self.value(of: "body", in: components))

        let lines = body.components(separatedBy: "\r\n")
        XCTAssertEqual(lines, ["", "", "Still Moment 2.5.0 (11) · iOS 18.4"])
    }

    func testWriteToUsEncodesSpacesAsPercent20NotPlus() throws {
        let url = try XCTUnwrap(
            FeedbackLinks.writeToUsURL(appVersion: "2.5.0", build: "11", osVersion: "18.4")
        )

        XCTAssertTrue(url.absoluteString.contains("subject=Still%20Moment"), url.absoluteString)
        XCTAssertFalse(url.absoluteString.contains("+"), url.absoluteString)
    }

    func testVersionWithSpecialCharactersSurvivesUnchanged() throws {
        let components = try self.writeToUsComponents(appVersion: "2.5.0-beta+1&x=y")
        let body = try XCTUnwrap(self.value(of: "body", in: components))

        XCTAssertTrue(body.hasSuffix("Still Moment 2.5.0-beta+1&x=y (11) · iOS 18.4"), body)
        XCTAssertEqual(components.queryItems?.map(\.name), ["subject", "body"])
    }

    // MARK: - Helpers

    private func writeToUsComponents(appVersion: String = "2.5.0") throws -> URLComponents {
        let url = try XCTUnwrap(
            FeedbackLinks.writeToUsURL(appVersion: appVersion, build: "11", osVersion: "18.4")
        )
        return try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    }

    private func value(of name: String, in components: URLComponents) -> String? {
        components.queryItems?.first { $0.name == name }?.value
    }
}
