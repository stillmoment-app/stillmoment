//
//  MockWaveformGenerationService.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockWaveformGenerationService: WaveformGenerationServiceProtocol {
    var generateShouldThrow = false
    var fixedWaveform: MeditationWaveform?
    private(set) var generateCallCount = 0
    private(set) var lastRequestedURL: URL?

    /// When set, generation suspends until `openGate()` is called. Lets a test hold two
    /// concurrent callers inside a single in-flight generation to verify dedupe.
    func gateGeneration() {
        self.gate = Gate()
    }

    /// Releases a previously installed gate so suspended generations can finish.
    func openGate() {
        self.gate?.open()
    }

    func generateWaveform(for fileURL: URL) async throws -> MeditationWaveform {
        self.generateCallCount += 1
        self.lastRequestedURL = fileURL

        if let gate = self.gate {
            await gate.wait()
        }

        if self.generateShouldThrow {
            throw WaveformGenerationError.decodingFailed(reason: "mock failure")
        }

        return self.fixedWaveform ?? MeditationWaveform(
            samples: [Float](repeating: 0.5, count: MeditationWaveform.sampleCount)
        )
    }

    // MARK: Private

    private var gate: Gate?

    /// A one-shot async barrier: callers `await wait()` until `open()` is called once.
    private final class Gate {
        func wait() async {
            if self.isOpen {
                return
            }
            await withCheckedContinuation { continuation in
                self.continuations.append(continuation)
            }
        }

        func open() {
            self.isOpen = true
            let pending = self.continuations
            self.continuations = []
            for continuation in pending {
                continuation.resume()
            }
        }

        private var isOpen = false
        private var continuations: [CheckedContinuation<Void, Never>] = []
    }
}
