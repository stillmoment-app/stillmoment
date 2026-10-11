//
//  TestStorage.swift
//  Still Moment
//
//  Test helper: a throwaway storage location per test (ios-056).
//

import Foundation
import XCTest
@testable import StillMoment

/// Own `UserDefaults` suite and own directory for one test, so nothing reaches the
/// app's real storage. Create it in `setUp`, call `remove()` in `tearDown`.
///
/// Every test gets the same, emptied suite and folder: unit tests run one after another,
/// and a fixed name keeps the simulator from collecting one settings file per test.
final class TestStorage {
    // MARK: Lifecycle

    init() throws {
        self.userDefaults = try XCTUnwrap(UserDefaults(suiteName: Self.name))
        self.baseDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(Self.name)
        // Start empty, even if an earlier, aborted run left something behind
        self.remove()
        try FileManager.default.createDirectory(at: self.baseDirectory, withIntermediateDirectories: true)
    }

    // MARK: Internal

    let userDefaults: UserDefaults
    let baseDirectory: URL

    /// The same storage as the app's composition root sees it.
    var location: StorageLocation {
        StorageLocation(
            userDefaults: self.userDefaults,
            baseDirectory: self.baseDirectory,
            shareInboxDirectory: self.baseDirectory.appendingPathComponent("ShareInbox")
        )
    }

    /// Deletes the suite and the directory.
    func remove() {
        self.userDefaults.removePersistentDomain(forName: Self.name)
        try? FileManager.default.removeItem(at: self.baseDirectory)
    }

    // MARK: Private

    private static let name = "StillMomentTests.TestStorage"
}
