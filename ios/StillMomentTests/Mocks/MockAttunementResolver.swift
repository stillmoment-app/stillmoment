//
//  MockAttunementResolver.swift
//  Still Moment
//
//  Test mock for AttunementResolverProtocol
//

import Foundation
@testable import StillMoment

final class MockAttunementResolver: AttunementResolverProtocol {
    // MARK: - Configurable returns

    var stubbedResolveResults: [String: ResolvedAttunement] = [:]
    var stubbedAudioURLs: [String: URL] = [:]
    var stubbedAllAvailable: [ResolvedAttunement] = []
    var shouldThrowOnResolveURL: Error?

    // MARK: - Recorded calls

    var resolvedIds: [String] = []
    var resolvedAudioURLIds: [String] = []

    // MARK: - Protocol

    func resolve(id: String) -> ResolvedAttunement? {
        self.resolvedIds.append(id)
        return self.stubbedResolveResults[id]
    }

    func resolveAudioURL(id: String) throws -> URL {
        self.resolvedAudioURLIds.append(id)
        if let error = self.shouldThrowOnResolveURL { throw error }
        guard let url = self.stubbedAudioURLs[id] else {
            throw AudioServiceError.soundFileNotFound
        }
        return url
    }

    func allAvailable() -> [ResolvedAttunement] {
        self.stubbedAllAvailable
    }
}
