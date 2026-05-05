//
//  BreathingCircleView.swift
//  Still Moment
//
//  Presentation Layer — geteilter Atemkreis fuer Timer und Player.
//

import SwiftUI

/// Atemkreis mit drei Schichten — geteilte Visualisierung fuer Timer und Player:
/// 1. Statischer Ring-Hintergrund (Track) — in jeder Phase sichtbar
/// 2. Restzeit-Bogen + Sonnen-Punkt — nur in der Hauptphase
/// 3. Atem-Glow im Inneren (animiert in der Hauptphase)
///
/// In der Pre-Roll-Phase ist nur der statische Track zu sehen; die verbleibende
/// Vorbereitungszeit kommuniziert sich allein durch die Countdown-Zahl im Inneren.
///
/// Die Komponente ist visuell — Logik (Phase, Progress, Reduced-Motion-Status)
/// kommt vom aufrufenden View. Keine Player-spezifischen Annahmen (Audio,
/// AVPlayer) — Inhalt wird via `content`-Closure injiziert.
struct BreathingCircleView<Content: View>: View {
    // MARK: Internal

    let phase: MeditationPhase
    /// Fortschritt der Hauptphase (0–1, vergangene Sitzungszeit).
    /// Wird fuer den Restzeit-Bogen genutzt, ignoriert in Pre-Roll.
    let progress: Double
    let reduceMotion: Bool
    /// Aussendurchmesser des Atemkreises. Default 280 px (Player). Timer auf
    /// iPhone SE skaliert auf z. B. 240 px herunter.
    var outerSize: CGFloat = 280
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Layer 1: statischer Ring-Hintergrund
            Circle()
                .stroke(self.theme.ringTrack, lineWidth: self.lineWidth)

            // Layer 2: Restzeit-Bogen + Sonnen-Punkt am vorderen Ende.
            // Nur in der Hauptphase sichtbar — Pre-Roll zeigt bewusst nur den Track.
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
            EmptyView()
        case .playing:
            ZStack {
                self.arc(amount: self.progress.clamped(to: 0...1))
                self.progressDot
            }
            .animation(.linear(duration: 1.0), value: self.progress)
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

    /// "Sonne" am vorderen Ende des Restzeit-Bogens — kleiner gefuellter Kreis
    /// in Akzent-Token, mit dezentem Soft-Shadow zur Betonung. Position berechnet
    /// sich aus dem aktuellen `progress` (Winkel vom 12-Uhr-Punkt im Uhrzeigersinn).
    private var progressDot: some View {
        let clamped = self.progress.clamped(to: 0...1)
        let radius = (self.outerSize - self.lineWidth) / 2
        let angle = clamped * 2 * .pi
        let dx = radius * sin(angle)
        let dy = -radius * cos(angle)
        return Circle()
            .fill(self.theme.interactive)
            .frame(width: self.dotSize, height: self.dotSize)
            .shadow(color: self.theme.interactive.opacity(0.6), radius: 4)
            .offset(x: dx, y: dy)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @State private var breathing = false

    private var glowSize: CGFloat {
        self.outerSize * (220.0 / 280.0)
    }

    private let lineWidth: CGFloat = 3
    private let dotSize: CGFloat = 9

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
        case .playing:
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
        case .playing:
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
        case .playing:
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
            reduceMotion: true
        ) {
            GlassPauseButton(isPlaying: true) {}
        }
    }
}
