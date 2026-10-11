//
//  StorageLocation.swift
//  Still Moment
//
//  Where the app keeps its data (ios-056). Chosen once in StillMomentApp and handed
//  to AppDependencies.live(); services only receive the parts they need.
//

import Foundation

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
}
