//
//  UpgradeTestData.swift
//  Still Moment
//
//  shared-144: The canonical data every release freezes as its data snapshot.
//  Writer and reader share these values, so they are defined only here.
//

import Foundation
@testable import StillMoment

/// What a user has set up in the app, as the upgrade test freezes it per release.
///
/// `UpgradeDataSnapshotWriterTests` stores these values through the app's real storage
/// paths; `UpgradeDataSnapshotReaderTests` expects to read exactly these values back from
/// every frozen snapshot. Changing a value here only affects snapshots written from now on;
/// older snapshots keep what their release wrote, so the reader would turn red.
enum UpgradeTestData {
    // MARK: - Library

    /// A meditation with teacher, title, playback range and both gongs on.
    /// Only the reference to the audio file is stored, not the file itself.
    static let meditation = GuidedMeditation(
        id: meditationId,
        localFilePath: "\(meditationId.uuidString).mp3",
        fileName: "upgrade-test.mp3",
        duration: 900,
        teacher: "Tara Brach",
        name: "Upgrade Test Meditation",
        dateAdded: Date(timeIntervalSinceReferenceDate: 800_000_000),
        trimStart: 30,
        trimEnd: 600,
        startGongEnabled: true,
        endGongEnabled: true,
        gongSoundId: GongSound.defaultSoundId
    )

    // MARK: - Praxis

    /// Timer settings that differ from the factory defaults wherever the ticket asks for it.
    static let praxis = Praxis(
        id: praxisId,
        durationMinutes: 20,
        preparationTimeEnabled: true,
        preparationTimeSeconds: 15,
        startGongSoundId: "deep-resonance",
        gongVolume: 1.0,
        intervalGongsEnabled: true,
        intervalMinutes: 5,
        intervalMode: .repeating,
        intervalSoundId: GongSound.defaultIntervalSoundId,
        intervalGongVolume: 0.75,
        backgroundSoundId: "forest",
        backgroundSoundVolume: 0.15
    )

    // MARK: - My Sounds

    /// Name of the user's own sound under "My Sounds". The writer imports a file with this
    /// name, so id and file name are assigned by the app, as on a device.
    static let customSoundName = "Rain Upgrade Test"
    static let customSoundExtension = "mp3"

    // MARK: - Settings

    static let appearance = AppearanceMode.light
    static let guidedPreparationTimeSeconds = 10

    // MARK: - Snapshot files

    /// Snapshot files are named `DataSnapshot-<version>.plist`.
    static let snapshotFilePrefix = "DataSnapshot-"
    static let snapshotFileExtension = "plist"

    static func snapshotFileName(version: String) -> String {
        "\(self.snapshotFilePrefix)\(version).\(self.snapshotFileExtension)"
    }

    // MARK: Private

    /// 1E5F2B9A-3C4D-4E6F-8A7B-9C0D1E2F3A4B (byte form avoids an unwrap of `UUID(uuidString:)`)
    private static let meditationId = UUID(uuid: (
        0x1E, 0x5F, 0x2B, 0x9A, 0x3C, 0x4D, 0x4E, 0x6F,
        0x8A, 0x7B, 0x9C, 0x0D, 0x1E, 0x2F, 0x3A, 0x4B
    ))

    /// 2A6B3C8D-4E5F-4061-9273-A4B5C6D7E8F9
    private static let praxisId = UUID(uuid: (
        0x2A, 0x6B, 0x3C, 0x8D, 0x4E, 0x5F, 0x40, 0x61,
        0x92, 0x73, 0xA4, 0xB5, 0xC6, 0xD7, 0xE8, 0xF9
    ))
}
