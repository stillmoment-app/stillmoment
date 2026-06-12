//
//  MockWaveformCacheService.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockWaveformCacheService: WaveformCacheServiceProtocol {
    var storage: [UUID: MeditationWaveform] = [:]
    var saveShouldThrow = false
    private(set) var loadCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var deleteCallCount = 0

    func load(id: UUID) -> MeditationWaveform? {
        self.loadCallCount += 1
        return self.storage[id]
    }

    func save(id: UUID, waveform: MeditationWaveform) throws {
        self.saveCallCount += 1
        if self.saveShouldThrow {
            throw WaveformGenerationError.decodingFailed(reason: "mock save failure")
        }
        self.storage[id] = waveform
    }

    func delete(id: UUID) {
        self.deleteCallCount += 1
        self.storage[id] = nil
    }
}
