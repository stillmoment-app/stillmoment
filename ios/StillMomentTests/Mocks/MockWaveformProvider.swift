//
//  MockWaveformProvider.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

@MainActor
final class MockWaveformProvider: WaveformProviderProtocol {
    var fixedWaveform: MeditationWaveform?
    var waveformShouldThrow = false
    private(set) var waveformCallCount = 0
    private(set) var precomputedMeditationIds: [UUID] = []
    private(set) var removedCachedIds: [UUID] = []

    func waveform(for meditation: GuidedMeditation) async throws -> MeditationWaveform {
        self.waveformCallCount += 1
        if self.waveformShouldThrow {
            throw WaveformGenerationError.decodingFailed(reason: "mock failure")
        }
        return self.fixedWaveform ?? MeditationWaveform(
            samples: [Float](repeating: 0.5, count: MeditationWaveform.sampleCount)
        )
    }

    func precompute(for meditation: GuidedMeditation) {
        self.precomputedMeditationIds.append(meditation.id)
    }

    func removeCached(id: UUID) {
        self.removedCachedIds.append(id)
    }
}
