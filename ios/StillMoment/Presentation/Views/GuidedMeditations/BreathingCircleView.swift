//
//  BreathingCircleView.swift
//  Still Moment
//
//  Presentation Layer — Atemkreis fuer den Guided-Meditation-Player.
//

import SwiftUI

/// 280×280-Atemkreis mit drei Schichten:
/// 1. Statischer Ring-Hintergrund (Track)
/// 2. Restzeit-/Pre-Roll-Bogen
/// 3. Atem-Glow im Inneren (animiert in der Hauptphase)
///
/// Die Komponente ist visuell — Logik (Phase, Progress, Reduced-Motion-Status)
/// kommt vom aufrufenden View.
struct BreathingCircleView<Content: View>: View {
    // MARK: Internal

    let phase: PlayerPhase
    /// Fortschritt der Hauptphase (0–1, vergangene Sitzungszeit).
    /// Wird fuer den Restzeit-Bogen genutzt, ignoriert in Pre-Roll.
    let progress: Double
    /// Pre-Roll-Fortschritt (0–1, entleert sich linear: 1 = voll, 0 = leer).
    let preRollProgress: Double
    let reduceMotion: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Layer 1: statischer Ring-Hintergrund
            Circle()
                .stroke(self.theme.ringTrack, lineWidth: self.lineWidth)

            // Layer 2: Bogen (Restzeit oder Pre-Roll)
            Circle()
                .trim(from: 0, to: self.arcAmount)
                .stroke(
                    self.theme.interactive,
                    style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: self.arcAmount)

            // Layer 3: Atem-Glow + Inhalt (Pause-Button oder Countdown)
            ZStack {
                self.glow
                    .scaleEffect(self.glowScale)
                    .opacity(self.glowOpacity)
                    .animation(self.glowAnimation, value: self.breathing)

                self.content()
            }
            .frame(width: self.glowSize, height: self.glowSize)
        }
        .frame(width: self.outerSize, height: self.outerSize)
        .onAppear {
            self.startBreathingIfNeeded()
        }
        .onChange(of: self.phase) { _ in
            self.startBreathingIfNeeded()
        }
        .onChange(of: self.reduceMotion) { _ in
            self.startBreathingIfNeeded()
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @State private var breathing = false

    private let outerSize: CGFloat = 280
    private let glowSize: CGFloat = 220
    private let lineWidth: CGFloat = 3

    /// Vollzyklus 16 s → halbe Periode 8 s mit autoreverses
    private let breathHalfPeriod: Double = 8

    /// Anteil des Bogens, der gerade gefuellt ist.
    /// - Hauptphase: waechst mit `progress` (vergangene Zeit).
    /// - Pre-Roll: entleert sich linear aus 1 → 0 (`preRollProgress`).
    private var arcAmount: Double {
        switch self.phase {
        case .preRoll:
            self.preRollProgress.clamped(to: 0...1)
        case .playing,
             .paused:
            self.progress.clamped(to: 0...1)
        }
    }

    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        self.theme.interactive.opacity(0.35),
                        self.theme.interactive.opacity(0.12),
                        self.theme.interactive.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: self.glowSize / 2
                )
            )
            .overlay(
                Circle().strokeBorder(self.theme.interactive.opacity(0.20), lineWidth: 0.75)
            )
    }

    /// Skala des Glow:
    /// - Pre-Roll: ruhig auf neutralem Wert (0.93).
    /// - Reduced Motion: konstanter Mittelwert.
    /// - Hauptphase normal: pulsiert zwischen 0.90 und 1.05.
    private var glowScale: CGFloat {
        switch self.phase {
        case .preRoll:
            return 0.93
        case .playing,
             .paused:
            if self.reduceMotion {
                return 0.93
            }
            return self.breathing ? 1.05 : 0.90
        }
    }

    /// Opacity des Glow:
    /// - Pre-Roll: gedaempft (0.65) — Glow „schlaeft" noch.
    /// - Reduced Motion: konstanter Mittelwert.
    /// - Hauptphase normal: pulsiert zwischen 0.75 und 1.0.
    private var glowOpacity: Double {
        switch self.phase {
        case .preRoll:
            return 0.65
        case .playing,
             .paused:
            if self.reduceMotion {
                return 0.85
            }
            return self.breathing ? 1.0 : 0.75
        }
    }

    private var glowAnimation: Animation? {
        switch self.phase {
        case .preRoll:
            return nil
        case .playing,
             .paused:
            if self.reduceMotion {
                return nil
            }
            return .easeInOut(duration: self.breathHalfPeriod)
                .repeatForever(autoreverses: true)
        }
    }

    private func startBreathingIfNeeded() {
        guard self.phase != .preRoll, !self.reduceMotion else {
            self.breathing = false
            return
        }
        // Animation startet ueber `glowAnimation` und `value: self.breathing`
        if !self.breathing {
            self.breathing = true
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Playing") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.10, blue: 0.06),
                Color(red: 0.08, green: 0.05, blue: 0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        BreathingCircleView(
            phase: .playing,
            progress: 0.3,
            preRollProgress: 0,
            reduceMotion: false
        ) {
            GlassPauseButton(isPlaying: true) {}
        }
    }
}

@available(iOS 17.0, *)
#Preview("Pre-Roll") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.10, blue: 0.06),
                Color(red: 0.08, green: 0.05, blue: 0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        BreathingCircleView(
            phase: .preRoll,
            progress: 0,
            preRollProgress: 0.6,
            reduceMotion: false
        ) {
            Text("9")
                .font(.system(size: 72, weight: .light, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

@available(iOS 17.0, *)
#Preview("Reduced Motion") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.10, blue: 0.06),
                Color(red: 0.08, green: 0.05, blue: 0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        BreathingCircleView(
            phase: .playing,
            progress: 0.5,
            preRollProgress: 0,
            reduceMotion: true
        ) {
            GlassPauseButton(isPlaying: true) {}
        }
    }
}
