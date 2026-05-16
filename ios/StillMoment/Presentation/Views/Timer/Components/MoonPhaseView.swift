//
//  MoonPhaseView.swift
//  Still Moment
//
//  Presentation Layer — Mondphasen-Visualisierung der laufenden Sitzung (shared-095).
//

import SwiftUI

/// Mond, dessen Schatten linear ueber die Sitzungsdauer nach links wandert —
/// vom Neumond (progress 0) zum Vollmond (progress 1). Drei Layer:
///
/// 1. **Halo** — radialer Schein hinter dem Mond, Intensitaet waechst mit
///    Smoothstep-Easing (bleibt lange unauffaellig, wird erst spaet warm).
/// 2. **Mond-Disc** — radialer Verlauf mit verschobenem Zentrum (oben-links),
///    erzeugt subtile Beleuchtung ohne Krater oder Flecken.
/// 3. **Schatten-Disc** — schwarze Scheibe gleicher Groesse, deren x-Offset
///    linear mit dem Progress nach links driftet (`-progress × outerSize × 200/180`).
///    Der ZStack aus Mond + Schatten wird auf einen Circle maskiert; sobald der
///    Schatten den Mond verlaesst (progress nahe 1), bleibt nur der Vollmond.
///
/// Die Farben sind aus dem Handoff "claude_code_handoff_running_timer_mondphase"
/// final und pixelgenau. Sie sind in der View hardcoded und folgen dem
/// `colorScheme` (Light/Dark), analog zum bestehenden Pattern in
/// `CardRowBackground`.
struct MoonPhaseView: View {
    // MARK: Internal

    /// Sitzungs-Fortschritt: 0 = Neumond (Schatten deckt Mond), 1 = Vollmond.
    let progress: Double
    let reduceMotion: Bool
    /// Mond-Durchmesser in Punkten. Halo-Container ist `outerSize × 1.6`.
    var outerSize: CGFloat = 220

    var body: some View {
        ZStack {
            self.halo

            ZStack {
                self.moonDisc
                self.shadowDisc
            }
            .frame(width: self.outerSize, height: self.outerSize)
            .mask(Circle())
        }
        .frame(width: self.containerSize, height: self.containerSize)
        .accessibilityHidden(true)
    }

    // MARK: Private

    @Environment(\.colorScheme)
    private var colorScheme

    private var clampedProgress: Double {
        max(0, min(1, self.progress))
    }

    private var containerSize: CGFloat {
        self.outerSize * 1.6
    }

    /// Linear, kein Easing — wie im Handoff spezifiziert. Die `200/180`-Skalierung
    /// raeumt am Ende den Bildausschnitt: bei progress=1 liegt der Schatten
    /// vollstaendig links ausserhalb des Mond-Clips.
    private var shadowOffset: CGFloat {
        -CGFloat(self.clampedProgress) * self.outerSize * (200.0 / 180.0)
    }

    /// Smoothstep `x²·(3 − 2x)`: Halo bleibt in der ersten Sitzungshaelfte
    /// unauffaellig (≈ 0.02–0.16) und waechst zum Sitzungsende auf 0.5.
    private var haloAlpha: Double {
        let progress = self.clampedProgress
        let eased = progress * progress * (3 - 2 * progress)
        return 0.02 + eased * 0.48
    }

    private var shadowAnimation: Animation? {
        self.reduceMotion ? nil : .linear(duration: 1.0)
    }

    private var haloAnimation: Animation? {
        self.reduceMotion ? nil : .easeInOut(duration: 1.0)
    }

    // MARK: - Layers

    private var halo: some View {
        Circle()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: self.haloFromColor.opacity(self.haloAlpha), location: 0),
                        .init(color: self.haloToColor.opacity(self.haloAlpha * 0.5), location: 0.4),
                        .init(color: .clear, location: 0.7)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: self.containerSize / 2
                )
            )
            .frame(width: self.containerSize, height: self.containerSize)
            .animation(self.haloAnimation, value: self.progress)
    }

    private var moonDisc: some View {
        Circle()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: self.discFromColor, location: 0),
                        .init(color: self.discMidColor, location: 0.6),
                        .init(color: self.discToColor, location: 1.0)
                    ],
                    center: UnitPoint(x: 0.35, y: 0.35),
                    startRadius: 0,
                    endRadius: self.outerSize * 0.8
                )
            )
            .frame(width: self.outerSize, height: self.outerSize)
    }

    private var shadowDisc: some View {
        Circle()
            .fill(self.shadowColor)
            .frame(width: self.outerSize, height: self.outerSize)
            .offset(x: self.shadowOffset)
            .animation(self.shadowAnimation, value: self.progress)
    }

    // MARK: - Colors (Handoff: claude_code_handoff_running_timer_mondphase)

    private var discFromColor: Color {
        switch self.colorScheme {
        case .light: Color(red: 255 / 255, green: 243 / 255, blue: 221 / 255) // #FFF3DD
        default: Color(red: 244 / 255, green: 226 / 255, blue: 200 / 255) // #F4E2C8
        }
    }

    private var discMidColor: Color {
        switch self.colorScheme {
        case .light: Color(red: 232 / 255, green: 200 / 255, blue: 150 / 255) // #E8C896
        default: Color(red: 229 / 255, green: 200 / 255, blue: 168 / 255) // #E5C8A8
        }
    }

    private var discToColor: Color {
        switch self.colorScheme {
        case .light: Color(red: 154 / 255, green: 106 / 255, blue: 66 / 255) // #9A6A42
        default: Color(red: 184 / 255, green: 148 / 255, blue: 120 / 255) // #B89478
        }
    }

    private var shadowColor: Color {
        switch self.colorScheme {
        case .light: Color(red: 58 / 255, green: 36 / 255, blue: 24 / 255) // #3A2418
        default: Color(red: 26 / 255, green: 16 / 255, blue: 12 / 255) // #1A100C
        }
    }

    private var haloFromColor: Color {
        switch self.colorScheme {
        case .light: Color(red: 252 / 255, green: 232 / 255, blue: 200 / 255) // #FCE8C8
        default: Color(red: 242 / 255, green: 200 / 255, blue: 168 / 255) // #F2C8A8
        }
    }

    private var haloToColor: Color {
        switch self.colorScheme {
        case .light: Color(red: 184 / 255, green: 95 / 255, blue: 70 / 255) // #B85F46
        default: Color(red: 199 / 255, green: 125 / 255, blue: 99 / 255) // #C77D63
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Moon — Neumond (Dark)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        MoonPhaseView(progress: 0.0, reduceMotion: false)
    }
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Moon — Halbmond (Dark)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        MoonPhaseView(progress: 0.5, reduceMotion: false)
    }
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Moon — Vollmond (Dark)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        MoonPhaseView(progress: 1.0, reduceMotion: false)
    }
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Moon — Neumond (Light)") {
    ZStack {
        Color(red: 1.00, green: 0.89, blue: 0.84).ignoresSafeArea()
        MoonPhaseView(progress: 0.0, reduceMotion: false)
    }
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Moon — Halbmond (Light)") {
    ZStack {
        Color(red: 1.00, green: 0.89, blue: 0.84).ignoresSafeArea()
        MoonPhaseView(progress: 0.5, reduceMotion: false)
    }
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Moon — Vollmond (Light)") {
    ZStack {
        Color(red: 1.00, green: 0.89, blue: 0.84).ignoresSafeArea()
        MoonPhaseView(progress: 1.0, reduceMotion: false)
    }
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Moon — Compact (180 pt)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        MoonPhaseView(progress: 0.5, reduceMotion: false, outerSize: 180)
    }
    .preferredColorScheme(.dark)
}
#endif
