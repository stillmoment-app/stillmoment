//
//  AppTabTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

final class AppTabTests: XCTestCase {
    // MARK: - Raw Values

    func testTimerRawValue() {
        XCTAssertEqual(AppTab.timer.rawValue, "timer")
    }

    func testLibraryRawValue() {
        XCTAssertEqual(AppTab.library.rawValue, "library")
    }

    func testSettingsRawValue() {
        XCTAssertEqual(AppTab.settings.rawValue, "settings")
    }

    // MARK: - CaseIterable

    func testAllCasesContainsAllThreeTabs() {
        let allCases = AppTab.allCases

        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.timer))
        XCTAssertTrue(allCases.contains(.library))
        XCTAssertTrue(allCases.contains(.settings))
    }

    // MARK: - Raw Value Initialization (Default Case)

    func testInitFromValidRawValue() {
        XCTAssertEqual(AppTab(rawValue: "timer"), .timer)
        XCTAssertEqual(AppTab(rawValue: "library"), .library)
        XCTAssertEqual(AppTab(rawValue: "settings"), .settings)
    }

    func testInitFromInvalidRawValueReturnsNil() {
        // When no stored value exists or invalid value, init returns nil
        XCTAssertNil(AppTab(rawValue: ""))
        XCTAssertNil(AppTab(rawValue: "invalid"))
        XCTAssertNil(AppTab(rawValue: "Timer")) // case-sensitive
    }

    // MARK: - Default Tab Behavior

    func testDefaultTabIsLibrary() {
        // On first launch the active tab should be library (shared-084).
        // StillMomentApp uses AppTab.defaultTab.rawValue as the @AppStorage default.
        XCTAssertEqual(AppTab.defaultTab, .library)
    }

    // MARK: - Persistence Key Consistency

    func testRawValuesAreStableForPersistence() {
        // These values are persisted in UserDefaults via @AppStorage
        // Changing them would break existing user preferences
        XCTAssertEqual(
            AppTab.timer.rawValue,
            "timer",
            "Timer raw value must remain 'timer' for backwards compatibility"
        )
        XCTAssertEqual(
            AppTab.library.rawValue,
            "library",
            "Library raw value must remain 'library' for backwards compatibility"
        )
        XCTAssertEqual(
            AppTab.settings.rawValue,
            "settings",
            "Settings raw value must remain 'settings' for backwards compatibility"
        )
    }
}
