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

    /// File existence simulation (when false, fileURL returns nil even with valid localFilePath)
    var mockFileExists = true

    /// Meditations whose audio file was requested via `fileURL(for:)`, in call order
    private(set) var fileURLRequests: [UUID] = []

    /// Where `fileURL(for:)` points: a temporary folder of its own, never the app's real
    /// Meditations folder (ios-056). Not created here; tests that write into it remove it.
    let meditationsDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("MockMeditations-\(UUID().uuidString)")

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

    func addMeditation(from _: URL, draft: GuidedMeditation) throws -> GuidedMeditation {
        if self.addShouldThrow {
            throw GuidedMeditationError.fileCopyFailed(reason: "Mock error")
        }
        let meditation = draft.withLocalFilePath("\(draft.id.uuidString).mp3")
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

    func fileURL(for meditation: GuidedMeditation) -> URL? {
        self.fileURLRequests.append(meditation.id)
        guard let localFilePath = meditation.localFilePath else {
            return nil
        }
        guard self.mockFileExists else {
            return nil
        }
        return self.getMeditationsDirectory().appendingPathComponent(localFilePath)
    }

    func getMeditationsDirectory() -> URL {
        self.meditationsDirectory
    }

    func needsMigration() -> Bool {
        self.mockNeedsMigration
    }
}
