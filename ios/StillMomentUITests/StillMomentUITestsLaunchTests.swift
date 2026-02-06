//
//  StillMomentUITestsLaunchTests.swift
//  Still Moment
//

import XCTest

final class StillMomentUITestsLaunchTests: XCTestCase {
    override static var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()

        // Wait for app to be ready
        let appReady = app.wait(for: .runningForeground, timeout: 5)
        XCTAssertTrue(appReady, "App should be running in foreground")

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
