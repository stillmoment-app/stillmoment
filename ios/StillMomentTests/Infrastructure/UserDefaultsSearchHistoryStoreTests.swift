//
//  UserDefaultsSearchHistoryStoreTests.swift
//  Still Moment
//
//  Roundtrip-Tests fuer den Suchhistorie-Store (ios-041).
//

import XCTest
@testable import StillMoment

final class UserDefaultsSearchHistoryStoreTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var userDefaults: UserDefaults!
    private let suiteName = "UserDefaultsSearchHistoryStoreTests"

    override func setUp() {
        super.setUp()
        // swiftlint:disable:next force_unwrapping
        self.userDefaults = UserDefaults(suiteName: self.suiteName)!
        self.userDefaults.removePersistentDomain(forName: self.suiteName)
    }

    override func tearDown() {
        self.userDefaults.removePersistentDomain(forName: self.suiteName)
        self.userDefaults = nil
        super.tearDown()
    }

    func testLoadOnEmptyStoreReturnsEmptyArray() {
        let sut = UserDefaultsSearchHistoryStore(userDefaults: self.userDefaults)
        XCTAssertEqual(sut.load(), [])
    }

    func testSaveAndLoadRoundtripPreservesOrder() {
        let sut = UserDefaultsSearchHistoryStore(userDefaults: self.userDefaults)
        sut.save(["Tara", "Atem", "Body"])
        XCTAssertEqual(sut.load(), ["Tara", "Atem", "Body"])
    }

    func testSaveOverwritesExistingHistory() {
        let sut = UserDefaultsSearchHistoryStore(userDefaults: self.userDefaults)
        sut.save(["Alt"])
        sut.save(["Neu"])
        XCTAssertEqual(sut.load(), ["Neu"])
    }

    func testHistorySurvivesNewStoreInstance() {
        let writer = UserDefaultsSearchHistoryStore(userDefaults: self.userDefaults)
        writer.save(["Atem"])

        let reader = UserDefaultsSearchHistoryStore(userDefaults: self.userDefaults)
        XCTAssertEqual(reader.load(), ["Atem"])
    }
}
