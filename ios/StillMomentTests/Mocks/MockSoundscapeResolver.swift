//
//  MockSoundscapeResolver.swift
//  Still Moment
//
//  Test mock for SoundscapeResolverProtocol
//

import Foundation
@testable import StillMoment

final class MockSoundscapeResolver: SoundscapeResolverProtocol {
    // MARK: - Configurable returns

    var stubbedResolveResults: [String: ResolvedSoundscape] = [:]
    var stubbedAudioURLs: [String: URL] = [:]
    var stubbedAllAvailable: [ResolvedSoundscape] = []
    var shouldThrowOnResolveURL: Error?

    // MARK: - Recorded calls

    var resolvedIds: [String] = []
    var resolvedAudioURLIds: [String] = []

    // MARK: - Protocol

    func resolve(id: String) -> ResolvedSoundscape? {
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

    func allAvailable() -> [ResolvedSoundscape] {
        self.stubbedAllAvailable
    }
}
