//
//  MockGuidedMeditationService.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockGuidedMeditationService: GuidedMeditationServiceProtocol {
    var meditations: [GuidedMeditation] = []
    var resolvedURL: URL?
    var startAccessingCalled = false
    var stopAccessingCalled = false
    var resolveShouldThrow = false
    var startAccessingShouldFail = false

    // Error simulation flags for all operations
    var loadShouldThrow = false
    var saveShouldThrow = false
    var addShouldThrow = false
    var updateShouldThrow = false
    var deleteShouldThrow = false

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
            throw GuidedMeditationError.bookmarkCreationFailed
        }
        let meditation = GuidedMeditation(
            fileBookmark: Data(),
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

    func resolveBookmark(_ bookmark: Data) throws -> URL {
        if self.resolveShouldThrow {
            throw GuidedMeditationError.bookmarkResolutionFailed
        }
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        self.resolvedURL = url
        return url
    }

    func startAccessingSecurityScopedResource(_ url: URL) -> Bool {
        self.startAccessingCalled = true
        return !self.startAccessingShouldFail
    }

    func stopAccessingSecurityScopedResource(_ url: URL) {
        self.stopAccessingCalled = true
    }
}
