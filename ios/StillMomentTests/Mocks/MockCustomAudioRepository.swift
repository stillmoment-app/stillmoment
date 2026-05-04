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

    var importedFiles: [URL] = []
    var deletedIds: [UUID] = []
    var updatedFiles: [CustomAudioFile] = []

    // MARK: - Configurable returns

    var stubbedSoundscapes: [CustomAudioFile] = []
    var stubbedFindResult: CustomAudioFile?
    var stubbedFileURL: URL?
    var shouldThrowOnImport: Error?
    var shouldThrowOnDelete: Error?
    var shouldThrowOnUpdate: Error?

    // MARK: - Protocol

    func loadAll() -> [CustomAudioFile] {
        self.stubbedSoundscapes
    }

    func importFile(from url: URL) throws -> CustomAudioFile {
        if let error = self.shouldThrowOnImport { throw error }
        self.importedFiles.append(url)
        let file = CustomAudioFile(
            id: UUID(),
            name: url.deletingPathExtension().lastPathComponent,
            filename: "\(UUID().uuidString).mp3",
            duration: 60,
            dateAdded: Date()
        )
        self.stubbedSoundscapes.append(file)
        return file
    }

    func delete(id: UUID) throws {
        if let error = self.shouldThrowOnDelete { throw error }
        self.deletedIds.append(id)
        self.stubbedSoundscapes.removeAll { $0.id == id }
    }

    func fileURL(for audioFile: CustomAudioFile) -> URL? {
        self.stubbedFileURL
    }

    func findFile(byId id: UUID) -> CustomAudioFile? {
        self.stubbedFindResult ?? self.stubbedSoundscapes.first { $0.id == id }
    }

    func update(_ file: CustomAudioFile) throws {
        if let error = self.shouldThrowOnUpdate { throw error }
        self.updatedFiles.append(file)
        if let index = self.stubbedSoundscapes.firstIndex(where: { $0.id == file.id }) {
            self.stubbedSoundscapes[index] = file
        }
    }
}
