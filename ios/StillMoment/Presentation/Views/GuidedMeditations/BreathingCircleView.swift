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
    /// Wall-Clock-Startzeit der Pre-Roll-Phase (nil ausserhalb von Pre-Roll).
    let preRollStartedAt: Date?
    /// Gesamtdauer der Pre-Roll-Phase in Sekunden (nil ausserhalb von Pre-Roll).
    let preRollTotalSeconds: Int?
    let reduceMotion: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Layer 1: statischer Ring-Hintergrund
            Circle()
                .stroke(self.theme.ringTrack, lineWidth: self.lineWidth)

            // Layer 2: Bogen — pro Phase eigene Circle-Identitaet, damit SwiftUI
            // beim Phasenwechsel nicht ueber die `.trim()`-Werte interpoliert.
            // Spec: "Vorbereitungs-Bogen springt auf 0 und waechst dann mit Fortschritt".
            self.progressArc

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

    @ViewBuilder private var progressArc: some View {
        switch self.phase {
        case .preRoll:
            self.preRollArc
        case .playing,
             .paused:
            self.arc(amount: self.progress.clamped(to: 0...1))
                .animation(.linear(duration: 1.0), value: self.progress)
        }
    }

    /// Pre-Roll-Bogen, kontinuierlich aus der Wall-Clock berechnet via `TimelineView`.
    /// Ergebnis: der Bogen erreicht exakt 0, wenn der Countdown endet — kein
    /// Rest-Segment durch nachhinkendes Easing.
    @ViewBuilder private var preRollArc: some View {
        if let startedAt = self.preRollStartedAt,
           let total = self.preRollTotalSeconds, total > 0 {
            TimelineView(.animation) { context in
                let elapsed = context.date.timeIntervalSince(startedAt)
                let remaining = max(0, Double(total) - elapsed)
                self.arc(amount: (remaining / Double(total)).clamped(to: 0...1))
            }
        } else {
            self.arc(amount: 1.0)
        }
    }

    private func arc(amount: Double) -> some View {
        Circle()
            .trim(from: 0, to: amount)
            .stroke(
                self.theme.interactive,
                style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
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

    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        self.theme.interactive.opacity(0.55),
                        self.theme.interactive.opacity(0.20),
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
    /// - Pre-Roll: ruhig auf neutralem Wert (0.92).
    /// - Reduced Motion: konstanter Mittelwert.
    /// - Hauptphase normal: pulsiert zwischen 0.85 und 1.10 (Δ 25 % — sichtbar atmend).
    private var glowScale: CGFloat {
        switch self.phase {
        case .preRoll:
            return 0.92
        case .playing,
             .paused:
            if self.reduceMotion {
                return 0.92
            }
            return self.breathing ? 1.10 : 0.85
        }
    }

    /// Opacity des Glow:
    /// - Pre-Roll: gedaempft (0.55) — Glow „schlaeft" noch.
    /// - Reduced Motion: konstanter Mittelwert.
    /// - Hauptphase normal: pulsiert zwischen 0.55 und 1.0 (Δ 45 % — gut sichtbar).
    private var glowOpacity: Double {
        switch self.phase {
        case .preRoll:
            return 0.55
        case .playing,
             .paused:
            if self.reduceMotion {
                return 0.78
            }
            return self.breathing ? 1.0 : 0.55
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
            preRollStartedAt: nil,
            preRollTotalSeconds: nil,
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
            preRollStartedAt: Date().addingTimeInterval(-4),
            preRollTotalSeconds: 10,
            reduceMotion: false
        ) {
            Text("6")
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
            preRollStartedAt: nil,
            preRollTotalSeconds: nil,
            reduceMotion: true
        ) {
            GlassPauseButton(isPlaying: true) {}
        }
    }
}
