//
//  MockGuidedMeditationService.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockGuidedMeditationService: GuidedMeditationServiceProtocol {
    var meditations: [GuidedMeditation] = []

    // Error simulation flags for all operations
    var loadShouldThrow = false
    var saveShouldThrow = false
    var addShouldThrow = false
    var updateShouldThrow = false
    var deleteShouldThrow = false

    /// Migration simulation
    var mockNeedsMigration = false

    func loadMeditations() throws -> [GuidedMeditation] {
        if self.loadShouldThrow {
            throw GuidedMeditationError.persistenceFailed(reason: "Mock error")
        }
        return self.meditations
    }

    func saveMeditations(_ meditations: [GuidedMeditation]) throws {
        if self.saveShouldThrow {
            throw GuidedMeditationError.persistenceFailed(reason: "Mock error")
        }
        self.meditations = meditations
    }

    func addMeditation(from url: URL, metadata: AudioMetadata) throws -> GuidedMeditation {
        if self.addShouldThrow {
            throw GuidedMeditationError.fileCopyFailed(reason: "Mock error")
        }
        let meditationId = UUID()
        let meditation = GuidedMeditation(
            id: meditationId,
            localFilePath: "\(meditationId.uuidString).mp3",
            fileName: url.lastPathComponent,
            duration: metadata.duration,
            teacher: metadata.artist ?? "Unknown",
            name: metadata.title ?? "Untitled"
        )
        self.meditations.append(meditation)
        return meditation
    }

    func updateMeditation(_ meditation: GuidedMeditation) throws {
        if self.updateShouldThrow {
            throw GuidedMeditationError.persistenceFailed(reason: "Mock error")
        }
        if let index = self.meditations.firstIndex(where: { $0.id == meditation.id }) {
            self.meditations[index] = meditation
        }
    }

    func deleteMeditation(id: UUID) throws {
        if self.deleteShouldThrow {
            throw GuidedMeditationError.persistenceFailed(reason: "Mock error")
        }
        self.meditations.removeAll { $0.id == id }
    }

    func getMeditationsDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Meditations")
    }

    func needsMigration() -> Bool {
        self.mockNeedsMigration
    }
}
