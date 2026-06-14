//
//  GongWaveform.swift
//  Still Moment
//
//  Presentation Layer — character-carrying mini waveform for gong selection (shared-115).
//
//  Each gong sound maps to a fixed decay envelope (left = attack, right = release)
//  that encodes its character: bar height ~ depth/fullness, tail length ~ reverb.
//  The envelope values are a shared cross-platform specification and must stay
//  identical to the Android `WAVE` map so both platforms render the same shape.
//

import SwiftUI

/// Mini waveform shown on the right of each gong row.
///
/// Renders 11 vertical bars whose heights follow a fixed per-sound envelope.
/// The vibration option has no envelope and is rendered as three dots instead.
struct GongWaveform: View {
    let soundId: String
    let isSelected: Bool

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        if let envelope = Self.envelope(forSoundId: self.soundId) {
            self.bars(envelope: envelope)
        } else {
            self.hapticDots
        }
    }

    // MARK: - Subviews

    private var barColor: Color {
        self.isSelected ? self.theme.interactive : self.theme.controlTrack
    }

    private func bars(envelope: [CGFloat]) -> some View {
        HStack(alignment: .center, spacing: Self.barSpacing) {
            ForEach(Array(envelope.enumerated()), id: \.offset) { _, value in
                Capsule()
                    .fill(self.barColor)
                    .frame(width: Self.barWidth, height: Self.barHeight(forValue: value))
            }
        }
        .frame(height: Self.maxBarHeight)
        .accessibilityHidden(true)
    }

    private var hapticDots: some View {
        HStack(spacing: Self.dotSpacing) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(self.barColor)
                    .frame(width: Self.dotDiameter, height: Self.dotDiameter)
            }
        }
        .frame(height: Self.maxBarHeight)
        .accessibilityHidden(true)
    }

    // MARK: - Layout constants

    private static let barWidth: CGFloat = 2.5
    private static let barSpacing: CGFloat = 2
    private static let maxBarHeight: CGFloat = 20
    private static let minBarHeight: CGFloat = 4
    private static let heightRange: CGFloat = 16
    private static let dotDiameter: CGFloat = 6
    private static let dotSpacing: CGFloat = 4
}

// MARK: - Envelope Specification

extension GongWaveform {
    /// Fixed decay envelopes keyed by sound ID (11 bars each).
    ///
    /// Shared cross-platform specification — values are identical to the Android
    /// `WAVE` map. Keyed by sound ID (not the localized name) so localization
    /// never affects the rendered shape.
    static let waveEnvelopes: [String: [CGFloat]] = [
        // tief, langer Ausklang
        "temple-bell": [0.35, 0.90, 1.00, 0.85, 0.78, 0.68, 0.60, 0.50, 0.42, 0.34, 0.26],
        // hell, ausgewogen
        "classic-bowl": [0.30, 0.95, 0.80, 0.65, 0.55, 0.45, 0.40, 0.32, 0.28, 0.22, 0.18],
        // sehr tief, breit, langer Nachhall
        "deep-resonance": [0.45, 0.70, 0.90, 1.00, 0.92, 0.86, 0.80, 0.72, 0.64, 0.54, 0.44],
        // trocken, kurz
        "clear-strike": [0.25, 1.00, 0.70, 0.45, 0.30, 0.20, 0.14, 0.10, 0.08, 0.06, 0.05]
    ]

    /// Envelope for the given sound ID, or `nil` when the sound has no waveform
    /// (vibration or unknown ID).
    static func envelope(forSoundId soundId: String) -> [CGFloat]? {
        self.waveEnvelopes[soundId]
    }

    /// Maps a normalized envelope value (0...1) to a bar height in points (4–20pt).
    static func barHeight(forValue value: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return self.minBarHeight + (clamped * self.heightRange).rounded()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Waveforms") {
    ThemeRootView {
        VStack(alignment: .leading, spacing: 16) {
            GongWaveform(soundId: "temple-bell", isSelected: true)
            GongWaveform(soundId: "classic-bowl", isSelected: false)
            GongWaveform(soundId: "deep-resonance", isSelected: false)
            GongWaveform(soundId: "clear-strike", isSelected: false)
            GongWaveform(soundId: GongSound.vibrationId, isSelected: false)
        }
        .padding()
    }
}
#endif
