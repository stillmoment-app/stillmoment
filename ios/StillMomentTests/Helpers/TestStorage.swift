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
final class TestStorage {
    // MARK: Lifecycle

    init() throws {
        let name = "test.stillmoment.\(UUID().uuidString)"
        self.suiteName = name
        self.userDefaults = try XCTUnwrap(UserDefaults(suiteName: name))
        self.baseDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(name)
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
        self.userDefaults.removePersistentDomain(forName: self.suiteName)
        try? FileManager.default.removeItem(at: self.baseDirectory)
    }

    // MARK: Private

    private let suiteName: String
}
