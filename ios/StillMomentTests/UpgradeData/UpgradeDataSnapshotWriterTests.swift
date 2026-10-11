//
//  UpgradeDataSnapshotWriterTests.swift
//  Still Moment
//
//  shared-144: Freezes the data this version leaves on a device (writer of the upgrade test).
//

import XCTest
@testable import StillMoment

/// Writes `UpgradeTestData` through the app's real storage paths into settings of its own
/// and saves their raw content (keys and format unchanged) as `DataSnapshot-<version>.plist`.
///
/// Skipped in normal test runs. It only runs when the release preparation (or a developer)
/// passes an output folder and a version, see `scripts/generate-data-snapshot.sh`:
/// xcodebuild hands environment variables prefixed with `TEST_RUNNER_` to the test process
/// without that prefix.
@MainActor
final class UpgradeDataSnapshotWriterTests: XCTestCase {
    // MARK: Internal

    static let outputDirectoryVariable = "STILLMOMENT_DATA_SNAPSHOT_DIR"
    static let versionVariable = "STILLMOMENT_DATA_SNAPSHOT_VERSION"

    func testWriteDataSnapshot() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let outputDirectory = environment[Self.outputDirectoryVariable],
              let version = environment[Self.versionVariable],
              !outputDirectory.isEmpty,
              !version.isEmpty
        else {
            throw XCTSkip("Writes a data snapshot only when \(Self.outputDirectoryVariable) and "
                + "\(Self.versionVariable) are set (scripts/generate-data-snapshot.sh)")
        }

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: Self.suiteName))
        let baseDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(Self.suiteName)
        self.removeStorage(userDefaults: userDefaults, baseDirectory: baseDirectory)
        defer { self.removeStorage(userDefaults: userDefaults, baseDirectory: baseDirectory) }
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)

        try self.writeCanonicalData(userDefaults: userDefaults, baseDirectory: baseDirectory)

        let domain = try XCTUnwrap(userDefaults.persistentDomain(forName: Self.suiteName))
        let data = try PropertyListSerialization.data(fromPropertyList: domain, format: .xml, options: 0)
        let outputURL = URL(fileURLWithPath: outputDirectory)
            .appendingPathComponent(UpgradeTestData.snapshotFileName(version: version))
        try data.write(to: outputURL, options: .atomic)
    }

    // MARK: Private

    private static let suiteName = "StillMomentTests.UpgradeDataSnapshot"

    /// Stores every canonical value the way the app does on a device.
    private func writeCanonicalData(userDefaults: UserDefaults, baseDirectory: URL) throws {
        // Library: what the app stores after import and editing (teacher, title,
        // playback range, gongs). Loading once more afterwards sets the markers a
        // relaunch of the app would set.
        let meditationService = GuidedMeditationService(userDefaults: userDefaults, baseDirectory: baseDirectory)
        _ = try meditationService.loadMeditations()
        try meditationService.saveMeditations([UpgradeTestData.meditation])
        _ = try meditationService.loadMeditations()

        UserDefaultsPraxisRepository(userDefaults: userDefaults).save(UpgradeTestData.praxis)

        // My Sounds: imported like a user's file, so the app assigns id and file name
        let sourceFile = baseDirectory.appendingPathComponent(
            "\(UpgradeTestData.customSoundName).\(UpgradeTestData.customSoundExtension)"
        )
        try Data("not real audio, only the reference counts".utf8).write(to: sourceFile)
        _ = try CustomAudioRepository(userDefaults: userDefaults, baseDirectory: baseDirectory)
            .importFile(from: sourceFile)

        ThemeManager(store: userDefaults).appearanceMode = UpgradeTestData.appearance

        GuidedMeditationSettingsRepository(userDefaults: userDefaults).save(
            GuidedMeditationSettings(preparationTimeSeconds: UpgradeTestData.guidedPreparationTimeSeconds)
        )
    }

    private func removeStorage(userDefaults: UserDefaults, baseDirectory: URL) {
        userDefaults.removePersistentDomain(forName: Self.suiteName)
        try? FileManager.default.removeItem(at: baseDirectory)
    }
}
