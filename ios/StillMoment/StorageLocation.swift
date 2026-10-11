//
//  StorageLocation.swift
//  Still Moment
//
//  Where the app keeps its data (ios-056). Chosen once in StillMomentApp and handed
//  to AppDependencies.live(); services only receive the parts they need.
//

import Foundation
import OSLog

/// The places the app persists to: settings, the files below a base directory
/// (meditations, soundscapes, waveforms) and the Share Extension inbox.
///
/// `production()` is the only place that names the app's real storage. Services take
/// their storage as initializer parameters without defaults, so tests always have to
/// pick their own.
struct StorageLocation {
    let userDefaults: UserDefaults
    /// Takes the role of "Application Support"; services add their own subfolders.
    let baseDirectory: URL
    let shareInboxDirectory: URL

    /// The app's real storage.
    static func production() -> StorageLocation {
        let shareInboxDirectory = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.stillmoment")?
            .appendingPathComponent("ShareInbox")
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("ShareInbox")

        return StorageLocation(
            userDefaults: .standard,
            baseDirectory: .applicationSupportDirectory,
            shareInboxDirectory: shareInboxDirectory
        )
    }

    /// The storage for this app launch: the app's own — or, in Debug builds only, a freshly
    /// emptied test storage when unit tests or UI tests run the app.
    static func forCurrentLaunch() -> StorageLocation {
        #if DEBUG
        let isUnitTestHost = NSClassFromString("XCTestCase") != nil
        if self.usesTestStorage(arguments: ProcessInfo.processInfo.arguments, isUnitTestHost: isUnitTestHost) {
            Logger.infrastructure.info("Launching on the test storage")
            return self.freshTestStorage(named: self.testStorageName)
        }
        #endif
        return self.production()
    }
}

// MARK: - Test storage (Debug builds only)

#if DEBUG
extension StorageLocation {
    /// Launch argument with which UI tests ask for the test storage.
    static let useTestStorageArgument = "-UseTestStorage"

    /// Name of the test storage's UserDefaults suite and of its folder in `tmp/`.
    static let testStorageName = "StillMomentTestStorage"

    /// Unit tests run inside the app (test host), UI tests pass `-UseTestStorage`.
    static func usesTestStorage(arguments: [String], isUnitTestHost: Bool) -> Bool {
        isUnitTestHost || arguments.contains(self.useTestStorageArgument)
    }

    /// An emptied storage of its own: UserDefaults suite `name` and the folder `tmp/<name>`.
    /// Whatever an earlier run left there is deleted first.
    ///
    /// Launch arguments such as `-appearanceMode light` keep working: the argument domain
    /// is searched by every UserDefaults instance, suites included.
    static func freshTestStorage(named name: String) -> StorageLocation {
        guard let userDefaults = UserDefaults(suiteName: name) else {
            preconditionFailure("'\(name)' cannot be used as a UserDefaults suite name")
        }
        userDefaults.removePersistentDomain(forName: name)

        let fileManager = FileManager.default
        let baseDirectory = fileManager.temporaryDirectory.appendingPathComponent(name)
        do {
            if fileManager.fileExists(atPath: baseDirectory.path) {
                try fileManager.removeItem(at: baseDirectory)
            }
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        } catch {
            Logger.infrastructure.error("Failed to empty the test storage folder", error: error)
        }

        return StorageLocation(
            userDefaults: userDefaults,
            baseDirectory: baseDirectory,
            shareInboxDirectory: baseDirectory.appendingPathComponent("ShareInbox")
        )
    }
}
#endif
