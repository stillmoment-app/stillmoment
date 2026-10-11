//
//  UpgradeDataSnapshotReaderTests.swift
//  Still Moment
//
//  shared-144: The current version reads the data of every released version.
//

import XCTest
@testable import StillMoment

/// Loads every frozen data snapshot (`DataSnapshot-<version>.plist`, one per release) into
/// fresh settings and reads it through today's storage paths. Every value of
/// `UpgradeTestData` has to come back unchanged — users skip updates, so all snapshots
/// count, not only the latest.
@MainActor
final class UpgradeDataSnapshotReaderTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.storage = try TestStorage()
    }

    override func tearDown() {
        self.storage?.remove()
        self.storage = nil
        super.tearDown()
    }

    func testEveryReleasedDataSnapshotIsReadCompletely() throws {
        let snapshots = try Self.bundledSnapshots()
        XCTAssertFalse(snapshots.isEmpty, "No data snapshot found in the test bundle")

        for snapshot in snapshots {
            let storage = try XCTUnwrap(self.storage)
            storage.remove()
            try FileManager.default.createDirectory(at: storage.baseDirectory, withIntermediateDirectories: true)
            storage.install(snapshot.domain)

            let reader = SnapshotCheck(version: snapshot.version)
            self.checkLibrary(in: storage, reader)
            self.checkPraxis(in: storage, reader)
            self.checkCustomSound(in: storage, reader)
            self.checkSettings(in: storage, reader)
        }
    }

    // MARK: Private

    private var storage: TestStorage?

    private func checkLibrary(in storage: TestStorage, _ check: SnapshotCheck) {
        let service = GuidedMeditationService(userDefaults: storage.userDefaults, baseDirectory: storage.baseDirectory)
        let expected = UpgradeTestData.meditation
        let meditations: [GuidedMeditation]
        do {
            meditations = try service.loadMeditations()
        } catch {
            return check.fail("library could not be loaded: \(error)")
        }
        guard let meditation = meditations.first(where: { $0.id == expected.id }) else {
            return check.fail("meditation \(expected.id) is missing (found \(meditations.count) meditations)")
        }
        check.equal(meditation.teacher, expected.teacher, "meditation teacher")
        check.equal(meditation.name, expected.name, "meditation title")
        check.equal(meditation.trimStart, expected.trimStart, "meditation playback range start")
        check.equal(meditation.trimEnd, expected.trimEnd, "meditation playback range end")
        check.equal(meditation.startGongEnabled, expected.startGongEnabled, "meditation start gong")
        check.equal(meditation.endGongEnabled, expected.endGongEnabled, "meditation end gong")
        check.equal(meditation.gongSoundId, expected.gongSoundId, "meditation gong sound")
        check.equal(meditation.localFilePath, expected.localFilePath, "meditation audio file reference")
        check.equal(meditation.fileName, expected.fileName, "meditation original file name")
        check.equal(meditation.duration, expected.duration, "meditation duration")
        check.equal(meditation.dateAdded, expected.dateAdded, "meditation date added")
    }

    private func checkPraxis(in storage: TestStorage, _ check: SnapshotCheck) {
        let praxis = UserDefaultsPraxisRepository(userDefaults: storage.userDefaults).load()
        let expected = UpgradeTestData.praxis
        check.equal(praxis.id, expected.id, "praxis id")
        check.equal(praxis.durationMinutes, expected.durationMinutes, "praxis duration")
        check.equal(praxis.preparationTimeEnabled, expected.preparationTimeEnabled, "praxis preparation on/off")
        check.equal(praxis.preparationTimeSeconds, expected.preparationTimeSeconds, "praxis preparation time")
        check.equal(praxis.startGongSoundId, expected.startGongSoundId, "praxis gong")
        check.equal(praxis.gongVolume, expected.gongVolume, "praxis gong volume")
        check.equal(praxis.intervalGongsEnabled, expected.intervalGongsEnabled, "praxis interval gongs on/off")
        check.equal(praxis.intervalMinutes, expected.intervalMinutes, "praxis interval minutes")
        check.equal(praxis.intervalMode, expected.intervalMode, "praxis interval mode")
        check.equal(praxis.intervalSoundId, expected.intervalSoundId, "praxis interval gong sound")
        check.equal(praxis.intervalGongVolume, expected.intervalGongVolume, "praxis interval gong volume")
        check.equal(praxis.backgroundSoundId, expected.backgroundSoundId, "praxis background sound")
        check.equal(praxis.backgroundSoundVolume, expected.backgroundSoundVolume, "praxis background volume")
    }

    private func checkCustomSound(in storage: TestStorage, _ check: SnapshotCheck) {
        let repository = CustomAudioRepository(userDefaults: storage.userDefaults, baseDirectory: storage.baseDirectory)
        let sounds = repository.loadAll()
        guard let sound = sounds.first(where: { $0.name == UpgradeTestData.customSoundName }) else {
            let names = sounds.map(\.name)
            return check.fail("own sound '\(UpgradeTestData.customSoundName)' is missing (found \(names))")
        }
        let expectedFileName = "\(sound.id.uuidString).\(UpgradeTestData.customSoundExtension)"
        check.equal(sound.filename, expectedFileName, "own sound audio file reference")
    }

    private func checkSettings(in storage: TestStorage, _ check: SnapshotCheck) {
        let appearance = ThemeManager(store: storage.userDefaults).appearanceMode
        check.equal(appearance, UpgradeTestData.appearance, "appearance")

        let guided = GuidedMeditationSettingsRepository(userDefaults: storage.userDefaults).load()
        check.equal(
            guided.preparationTimeSeconds,
            UpgradeTestData.guidedPreparationTimeSeconds,
            "guided meditation preparation time"
        )
    }
}

// MARK: - Snapshot loading

private struct DataSnapshot {
    let version: String
    let domain: [String: Any]
}

extension UpgradeDataSnapshotReaderTests {
    /// All snapshots in the test bundle, oldest version first.
    private static func bundledSnapshots() throws -> [DataSnapshot] {
        let bundle = Bundle(for: UpgradeDataSnapshotReaderTests.self)
        let urls = bundle
            .urls(forResourcesWithExtension: UpgradeTestData.snapshotFileExtension, subdirectory: nil) ?? []
        return try urls
            .filter { $0.lastPathComponent.hasPrefix(UpgradeTestData.snapshotFilePrefix) }
            .map { url in
                let version = String(url.deletingPathExtension().lastPathComponent
                    .dropFirst(UpgradeTestData.snapshotFilePrefix.count))
                let data = try Data(contentsOf: url)
                let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
                let domain = try XCTUnwrap(plist as? [String: Any], "Snapshot \(version) is not a dictionary")
                return DataSnapshot(version: version, domain: domain)
            }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }
    }
}

private extension TestStorage {
    /// Puts a frozen snapshot into the (emptied) settings, as if that release had left it on the device.
    func install(_ domain: [String: Any]) {
        for (key, value) in domain {
            self.userDefaults.set(value, forKey: key)
        }
    }
}

/// Reports every lost or changed value with the snapshot's version and the value's name.
private struct SnapshotCheck {
    let version: String

    func equal<T: Equatable>(_ actual: T, _ expected: T, _ value: String) {
        XCTAssertEqual(
            actual,
            expected,
            "Data snapshot \(self.version): \(value) read as \(actual), expected \(expected)"
        )
    }

    func fail(_ message: String) {
        XCTFail("Data snapshot \(self.version): \(message)")
    }
}
