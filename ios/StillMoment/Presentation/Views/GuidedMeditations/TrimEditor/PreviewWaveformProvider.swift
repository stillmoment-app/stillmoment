//
//  PreviewWaveformProvider.swift
//  Still Moment
//
//  Preview-only waveform provider for the trim editor (shared-107).
//

import Foundation

#if DEBUG
/// Preview waveform provider — returns a synthetic speech-then-silence-then-speech
/// shape so the previews resemble a real meditation. Can simulate a decode failure.
@MainActor
final class PreviewWaveformProvider: WaveformProviderProtocol {
    // MARK: Lifecycle

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    // MARK: Internal

    func waveform(for _: GuidedMeditation) async throws -> MeditationWaveform {
        if self.shouldFail {
            throw WaveformGenerationError.decodingFailed(reason: "preview")
        }
        return MeditationWaveform(samples: Self.syntheticSamples())
    }

    func precompute(for _: GuidedMeditation) {}

    func removeCached(id _: UUID) {}

    // MARK: Private

    private let shouldFail: Bool

    private static func syntheticSamples() -> [Float] {
        (0..<MeditationWaveform.sampleCount).map { index in
            let fraction = Double(index) / Double(MeditationWaveform.sampleCount)
            let speech = abs(sin(fraction * 40)) * 0.8 + 0.15
            let isSilence = fraction > 0.18 && fraction < 0.82
            return Float(isSilence ? 0.06 : speech)
        }
    }
}
#endif
