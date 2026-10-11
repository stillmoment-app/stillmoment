//
//  AttunementCleanupMigration.swift
//  Still Moment
//
//  Infrastructure - One-time silent migration that removes legacy attunement data.
//

import Foundation
import OSLog

/// Removes any leftover attunement data from previous app versions.
///
/// Runs once on the first launch after the upgrade that drops the attunement feature
/// (shared-088). Subsequent launches are no-ops thanks to the idempotency marker.
///
/// Touched data:
/// - `UserDefaults`: `introductionId`, `introductionEnabled`, `customAudioFiles_attunement`
/// - File system: `<baseDirectory>/CustomAudio/attunements/` (recursively removed; in the app
///   the base directory is Application Support)
///
/// All operations are silent. The user sees no dialog or message.
enum AttunementCleanupMigration {
    /// UserDefaults key marking that the migration has already run on this device.
    static let markerKey = "stillmoment.migration.attunementRemoved.v1"

    /// Legacy UserDefaults keys that may exist from earlier versions.
    private enum LegacyKeys {
        static let introductionId = "introductionId"
        static let introductionEnabled = "introductionEnabled"
        static let customAudioFilesAttunement = "customAudioFiles_attunement"
    }

    /// Runs the cleanup migration if it has not run before. Idempotent.
    ///
    /// - Parameters:
    ///   - userDefaults: Settings that may hold the legacy keys and the marker
    ///   - baseDirectory: Folder that may hold the legacy `CustomAudio/attunements` subfolder
    static func runIfNeeded(userDefaults: UserDefaults, baseDirectory: URL) {
        guard !userDefaults.bool(forKey: self.markerKey) else {
            return
        }

        var clearedKeys: [String] = []
        for key in [
            LegacyKeys.introductionId,
            LegacyKeys.introductionEnabled,
            LegacyKeys.customAudioFilesAttunement
        ] where userDefaults.object(forKey: key) != nil {
            userDefaults.removeObject(forKey: key)
            clearedKeys.append(key)
        }

        let fileManager = FileManager.default
        let attunementDir = baseDirectory.appendingPathComponent("CustomAudio/attunements")
        var filesDeleted = 0
        if fileManager.fileExists(atPath: attunementDir.path) {
            if let contents = try? fileManager.contentsOfDirectory(atPath: attunementDir.path) {
                filesDeleted = contents.count
            }
            try? fileManager.removeItem(at: attunementDir)
        }

        userDefaults.set(true, forKey: self.markerKey)
        Logger.infrastructure.info(
            "Attunement cleanup migration completed",
            metadata: [
                "filesDeleted": filesDeleted,
                "userDefaultsKeysCleared": clearedKeys.count
            ]
        )
    }
}
