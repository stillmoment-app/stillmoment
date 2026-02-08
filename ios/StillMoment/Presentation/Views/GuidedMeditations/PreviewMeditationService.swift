//
//  PreviewMeditationService.swift
//  Still Moment
//
//  Preview-only mock service for GuidedMeditationsListView previews
//

import Foundation

#if DEBUG
final class PreviewMeditationService: GuidedMeditationServiceProtocol {
    var meditations: [GuidedMeditation]

    init(meditations: [GuidedMeditation] = []) {
        self.meditations = meditations
    }

    func loadMeditations() throws -> [GuidedMeditation] {
        self.meditations
    }

    func saveMeditations(_ meditations: [GuidedMeditation]) throws {
        self.meditations = meditations
    }

    func addMeditation(from _: URL, metadata: AudioMetadata) throws -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "preview.mp3",
            fileName: "preview.mp3",
            duration: metadata.duration,
            teacher: metadata.artist ?? "Unknown",
            name: metadata.title ?? "Untitled"
        )
    }

    func updateMeditation(_ meditation: GuidedMeditation) throws {}

    func deleteMeditation(id: UUID) throws {}

    func fileURL(for meditation: GuidedMeditation) -> URL? {
        guard let localFilePath = meditation.localFilePath else {
            return nil
        }
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("Meditations")
            .appendingPathComponent(localFilePath)
    }

    func getMeditationsDirectory() -> URL {
        FileManager.default.temporaryDirectory
    }

    func needsMigration() -> Bool {
        false
    }

    /// Sample data for previews
    static let sampleMeditations: [GuidedMeditation] = [
        GuidedMeditation(
            localFilePath: "sample1.mp3",
            fileName: "loving-kindness.mp3",
            duration: 691, // 11:31
            teacher: "Christine Braehler",
            name: "Loving-without-Losing-Yourself"
        ),
        GuidedMeditation(
            localFilePath: "sample2.mp3",
            fileName: "einschlafen.mp3",
            duration: 3629, // 1:00:29
            teacher: "Somebody",
            name: "Meditation wieder Einschlafen bei naechtlichem Erwachen"
        ),
        GuidedMeditation(
            localFilePath: "sample3.mp3",
            fileName: "body-scan.mp3",
            duration: 1245, // 20:45
            teacher: "Christine Braehler",
            name: "Body Scan Meditation"
        )
    ]
}
#endif
