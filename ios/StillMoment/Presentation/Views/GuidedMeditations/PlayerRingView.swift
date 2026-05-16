//
//  PlayerRingView.swift
//  Still Moment
//
//  Presentation Layer — Player-eigene Ring-Komponente fuer Kerzenschein 2.0.
//

import SwiftUI

/// Ring-Komponente des Guided-Meditation-Players im KS-2.0-Vokabular.
///
/// Schichten:
/// 1. Statische Track-Linie (1 px, warme leise Akzent-Linie) — in jeder Phase sichtbar.
/// 2. Restzeit-Bogen (1.5 px, dieselbe Akzent-Farbe, abgerundete Enden) + Perle an
///    der Vorderkante — nur in der Hauptphase sichtbar; Pre-Roll zeigt allein die
///    Countdown-Zahl im Inneren.
///
/// Geometrie identisch zum Timer-Idle-Ring: zentriert, Start bei 12 Uhr, im
/// Uhrzeigersinn wachsend. Inhalt (Pause-Button oder Countdown) wird via
/// `content`-Closure injiziert — die Ring-Komponente trifft keine
/// Player-spezifischen Annahmen.
struct PlayerRingView<Content: View>: View {
    let phase: MeditationPhase
    /// Fortschritt der Hauptphase (0–1). Wird fuer den Restzeit-Bogen genutzt,
    /// in Pre-Roll ignoriert.
    let progress: Double
    /// Aussendurchmesser des Rings. Default 280 px — entspricht dem Player-Layout.
    var outerSize: CGFloat = 280
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(self.theme.interactive.opacity(0.32), lineWidth: PlayerRingMetrics.trackLineWidth)

            self.progressArc

            self.content()
        }
        .frame(width: self.outerSize, height: self.outerSize)
    }

    @ViewBuilder private var progressArc: some View {
        switch self.phase {
        case .preRoll:
            EmptyView()
        case .playing:
            ZStack {
                self.arc(amount: self.progress.clamped(to: 0...1))
                self.progressBead
            }
            .animation(.linear(duration: 1.0), value: self.progress)
        }
    }

    private func arc(amount: Double) -> some View {
        Circle()
            .trim(from: 0, to: amount)
            .stroke(
                self.theme.interactive.opacity(0.72),
                style: StrokeStyle(lineWidth: PlayerRingMetrics.arcLineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
    }

    /// Perle an der Vorderkante des Restzeit-Bogens — kleiner gefuellter Kreis
    /// in Akzentfarbe mit weichem Drop-Shadow als Glow.
    private var progressBead: some View {
        let clamped = self.progress.clamped(to: 0...1)
        let radius = (self.outerSize - PlayerRingMetrics.arcLineWidth) / 2
        let angle = clamped * 2 * .pi
        let dx = radius * sin(angle)
        let dy = -radius * cos(angle)
        return Circle()
            .fill(self.theme.interactive)
            .frame(width: PlayerRingMetrics.beadDiameter, height: PlayerRingMetrics.beadDiameter)
            .shadow(color: self.theme.interactive, radius: PlayerRingMetrics.beadShadowRadius)
            .offset(x: dx, y: dy)
    }

    @Environment(\.themeColors)
    private var theme
}

/// Konstanten der Player-Ring-Komponente — bewusst aus dem generischen
/// `PlayerRingView` ausgelagert, weil Swift in generischen Typen keine
/// statisch gespeicherten Properties erlaubt.
private enum PlayerRingMetrics {
    static let trackLineWidth: CGFloat = 1
    static let arcLineWidth: CGFloat = 1.5
    static let beadDiameter: CGFloat = 12
    static let beadShadowRadius: CGFloat = 4.5
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Playing — 30 %") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.06, blue: 0.04),
                Color(red: 0.20, green: 0.12, blue: 0.10),
                Color(red: 0.36, green: 0.23, blue: 0.18)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PlayerRingView(phase: .playing, progress: 0.3) {
            EmptyView()
        }
    }
}

@available(iOS 17.0, *)
#Preview("Pre-Roll") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.93, blue: 0.86),
                Color(red: 0.97, green: 0.80, blue: 0.66),
                Color(red: 0.91, green: 0.63, blue: 0.46)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PlayerRingView(phase: .preRoll, progress: 0) {
            Text("8")
                .font(.system(size: 72, weight: .light, design: .rounded))
        }
    }
}
