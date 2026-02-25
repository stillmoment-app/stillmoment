//
//  MockCustomAudioRepository.swift
//  Still Moment
//
//  Test mock for CustomAudioRepositoryProtocol
//

import Foundation
@testable import StillMoment

final class MockCustomAudioRepository: CustomAudioRepositoryProtocol {
    // MARK: - Recorded calls

    var importedFiles: [(URL, CustomAudioType)] = []
    var deletedIds: [UUID] = []
    var updatedFiles: [CustomAudioFile] = []

    // MARK: - Configurable returns

    var stubbedSoundscapes: [CustomAudioFile] = []
    var stubbedAttunements: [CustomAudioFile] = []
    var stubbedFindResult: CustomAudioFile?
    var stubbedFileURL: URL?
    var shouldThrowOnImport: Error?
    var shouldThrowOnDelete: Error?
    var shouldThrowOnUpdate: Error?

    // MARK: - Protocol

    func loadAll(type: CustomAudioType) -> [CustomAudioFile] {
        type == .soundscape ? self.stubbedSoundscapes : self.stubbedAttunements
    }

    func importFile(from url: URL, type: CustomAudioType) throws -> CustomAudioFile {
        if let error = self.shouldThrowOnImport { throw error }
        self.importedFiles.append((url, type))
        let file = CustomAudioFile(
            id: UUID(),
            name: url.deletingPathExtension().lastPathComponent,
            filename: "\(UUID().uuidString).mp3",
            duration: 60,
            type: type,
            dateAdded: Date()
        )
        if type == .soundscape {
            self.stubbedSoundscapes.append(file)
        } else {
            self.stubbedAttunements.append(file)
        }
        return file
    }

    func delete(id: UUID) throws {
        if let error = self.shouldThrowOnDelete { throw error }
        self.deletedIds.append(id)
        self.stubbedSoundscapes.removeAll { $0.id == id }
        self.stubbedAttunements.removeAll { $0.id == id }
    }

    func fileURL(for audioFile: CustomAudioFile) -> URL? {
        self.stubbedFileURL
    }

    func findFile(byId id: UUID) -> CustomAudioFile? {
        self.stubbedFindResult
            ?? (self.stubbedSoundscapes + self.stubbedAttunements).first { $0.id == id }
    }

    func update(_ file: CustomAudioFile) throws {
        if let error = self.shouldThrowOnUpdate { throw error }
        self.updatedFiles.append(file)
        if let index = self.stubbedSoundscapes.firstIndex(where: { $0.id == file.id }) {
            self.stubbedSoundscapes[index] = file
        } else if let index = self.stubbedAttunements.firstIndex(where: { $0.id == file.id }) {
            self.stubbedAttunements[index] = file
        }
    }
}
