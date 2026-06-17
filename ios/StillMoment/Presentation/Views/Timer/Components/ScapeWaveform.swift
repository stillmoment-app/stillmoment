//
//  ScapeWaveform.swift
//  Still Moment
//
//  Presentation Layer — looping mini waveform for soundscape selection (shared-121).
//
//  Unlike the gong waveform (a fixed decay envelope for a one-shot sound), the
//  soundscape waveform represents a continuous loop: 13 bars whose heights follow
//  a fixed per-sound SWAVE envelope, and which animate as an equalizer while the
//  preview is playing. "Silence" has no envelope and is drawn as a flat line.
//
//  The SWAVE envelopes are a shared cross-platform specification and must stay
//  identical to the Android `SWAVE` map so both platforms render the same shape.
//

import SwiftUI

/// Mini waveform shown on the right of each soundscape row.
///
/// Renders 13 vertical bars whose heights follow a fixed per-sound envelope and
/// animate as an equalizer while `isPlaying` is true. "Silence" renders a flat line.
struct ScapeWaveform: View {
    let soundId: String
    let isSelected: Bool
    /// Drives the equalizer animation (true while this row's preview is sounding).
    var isPlaying: Bool = false

    @Environment(\.themeColors)
    private var theme
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        if let envelope = Self.envelope(forSoundId: self.soundId) {
            self.bars(envelope: envelope)
        } else {
            self.flatLine
        }
    }

    // MARK: - Subviews

    private var barColor: Color {
        self.isSelected ? self.theme.interactive : self.theme.controlTrack
    }

    private var animatesEqualizer: Bool {
        self.isPlaying && !self.reduceMotion
    }

    private func bars(envelope: [CGFloat]) -> some View {
        HStack(alignment: .center, spacing: Self.barSpacing) {
            ForEach(Array(envelope.enumerated()), id: \.offset) { index, value in
                Capsule()
                    .fill(self.barColor)
                    .frame(width: Self.barWidth, height: Self.barHeight(forValue: value))
                    .scaleEffect(y: self.animatesEqualizer ? Self.eqMinScale : 1, anchor: .center)
                    .animation(self.eqAnimation(index: index), value: self.animatesEqualizer)
            }
        }
        .frame(height: Self.maxBarHeight)
        .accessibilityHidden(true)
    }

    /// Equalizer animation that staggers per bar index (matches the prototype `eq` keyframe).
    private func eqAnimation(index: Int) -> Animation? {
        guard self.animatesEqualizer else {
            return nil
        }
        return .easeInOut(duration: Self.eqDuration)
            .repeatForever(autoreverses: true)
            .delay(Double(index) * Self.eqStagger)
    }

    private var flatLine: some View {
        Capsule()
            .fill(self.barColor)
            .frame(width: Self.flatWidth, height: Self.barWidth)
            .frame(height: Self.maxBarHeight)
            .accessibilityHidden(true)
    }

    // MARK: - Layout constants

    private static let barWidth: CGFloat = 2.5
    private static let barSpacing: CGFloat = 2
    private static let maxBarHeight: CGFloat = 22
    private static let minBarHeight: CGFloat = 4
    private static let heightRange: CGFloat = 16
    private static let flatWidth: CGFloat = 26
    private static let eqMinScale: CGFloat = 0.4
    private static let eqDuration: Double = 0.9
    private static let eqStagger: Double = 0.06
}

// MARK: - Envelope Specification

extension ScapeWaveform {
    /// Fixed loop envelopes keyed by sound ID (13 bars each).
    ///
    /// Shared cross-platform specification — values are identical to the Android
    /// `SWAVE` map. Keyed by sound ID (not the localized name) so localization
    /// never affects the rendered shape. These are loop patterns (steady), not
    /// the decaying envelopes of the gong waveform.
    static let swaveEnvelopes: [String: [CGFloat]] = [
        // Waldatmosphäre — sanftes Blätterrauschen
        "forest": [0.30, 0.55, 0.40, 0.70, 0.50, 0.62, 0.45, 0.72, 0.52, 0.60, 0.42, 0.58, 0.36],
        // Regen — gleichmäßiger, beruhigender Regen
        "cozy-rain": [0.62, 0.74, 0.58, 0.80, 0.66, 0.78, 0.60, 0.82, 0.64, 0.76, 0.58, 0.72, 0.60]
    ]

    /// Neutral, calm loop pattern used for imported/custom files (no real analysis).
    /// Identical to the Android default so both platforms render the same shape.
    static let defaultEnvelope: [CGFloat] = [
        0.45, 0.55, 0.48, 0.60, 0.50, 0.58, 0.46, 0.62, 0.50, 0.56, 0.44, 0.54, 0.42
    ]

    /// Envelope for the given sound ID, or `nil` when the sound has no waveform
    /// ("Silence" renders a flat line instead).
    ///
    /// Built-in scenes use their dedicated SWAVE envelope; any other id (a custom
    /// file's UUID) falls back to the neutral default.
    static func envelope(forSoundId soundId: String) -> [CGFloat]? {
        if soundId == BackgroundSound.silentId {
            return nil
        }
        return self.swaveEnvelopes[soundId] ?? self.defaultEnvelope
    }

    /// Maps a normalized envelope value (0...1) to a bar height in points (4–20pt).
    static func barHeight(forValue value: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return self.minBarHeight + (clamped * self.heightRange).rounded()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Scape Waveforms") {
    ThemeRootView {
        VStack(alignment: .leading, spacing: 16) {
            ScapeWaveform(soundId: "forest", isSelected: true, isPlaying: true)
            ScapeWaveform(soundId: "cozy-rain", isSelected: false)
            ScapeWaveform(soundId: UUID().uuidString, isSelected: false)
            ScapeWaveform(soundId: BackgroundSound.silentId, isSelected: false)
        }
        .padding()
    }
}
#endif
