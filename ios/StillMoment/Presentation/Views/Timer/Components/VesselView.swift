//
//  VesselView.swift
//  Still Moment
//
//  Presentation Layer — vertikale Glas-Capsule mit warmem Verlauf (ios-046).
//

import SwiftUI

/// Akku-Vessel: vertikale Glas-Capsule mit Fluessigkeits-Pegel, der
/// linear ueber die Sitzungsdauer steigt — die Meditation laedt das
/// Glas auf.
///
/// - `progress = 0` → leer (unten), `progress = 1` → voll (oben).
/// - Der Farbverlauf ist an die Glas-Geometrie gebunden, nicht an die
///   Fluessigkeit: die helle Zone bleibt geometrisch oben, die Oberkante
///   schiebt sich beim Auffuellen nach oben durch den Verlauf hindurch.
/// - Pegel-Farbe nimmt die `interactive`-Akzentfarbe des aktiven Themes
///   auf (Kerzenschein/Wald/Mondlicht × Light/Dark). Die raeumliche
///   Tiefe wird ueber einen Opacity-Verlauf erzeugt: oben transparenter
///   (heller-wirkend auf dunklem Glas), unten kraeftiger.
struct VesselView: View {
    // MARK: Internal

    /// Fortschritt der Sitzung: 0 = Glas leer, 1 = Glas voll.
    let progress: Double
    let reduceMotion: Bool
    var width: CGFloat = 110
    var height: CGFloat = 360

    var body: some View {
        ZStack(alignment: .bottom) {
            self.glassBackground
            self.fluidLayer
            self.meniscus
            self.glassReflex
        }
        .frame(width: self.width, height: self.height)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(Self.glassBorder, lineWidth: 1)
        )
        .animation(self.fluidAnimation, value: self.progress)
        .accessibilityHidden(true)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var clampedProgress: CGFloat {
        CGFloat(max(0, min(1, self.progress)))
    }

    /// Hoehe der gefuellten Flaeche (vom Boden nach oben gemessen).
    private var fillHeight: CGFloat {
        self.height * self.clampedProgress
    }

    /// Abstand der Wasseroberflaeche vom oberen Glasrand.
    private var waterlineFromTop: CGFloat {
        self.height * (1 - self.clampedProgress)
    }

    private var fluidAnimation: Animation? {
        self.reduceMotion ? nil : .linear(duration: 1.0)
    }

    // MARK: - Layers

    private var glassBackground: some View {
        Rectangle()
            .fill(Self.glassFill)
            .frame(width: self.width, height: self.height)
    }

    /// Volle Hoehe Gradient, sichtbar nur unten via Mask — dadurch sitzt der
    /// Gradient geometrisch am Glas, die Oberkante der Fluessigkeit schiebt
    /// sich durch den Verlauf hindurch.
    private var fluidLayer: some View {
        LinearGradient(
            stops: self.fluidStops,
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: self.width, height: self.height)
        .mask(alignment: .bottom) {
            Rectangle()
                .frame(width: self.width, height: self.fillHeight)
        }
    }

    /// Theme-getoenter Pegel: die `interactive`-Akzentfarbe in drei
    /// Opacity-Stufen — oben transparenter, unten kraeftiger. Funktioniert
    /// konsistent in Light und Dark, weil sich der Tiefen-Effekt aus der
    /// Opacity gegen den dunklen Glas-Hintergrund ergibt.
    private var fluidStops: [Gradient.Stop] {
        [
            .init(color: self.theme.interactive.opacity(0.55), location: 0),
            .init(color: self.theme.interactive.opacity(0.80), location: 0.5),
            .init(color: self.theme.interactive.opacity(0.95), location: 1.0)
        ]
    }

    /// Heller Meniskus-Glanz auf der Oberflaeche der Fluessigkeit.
    /// Wird ausgeblendet, solange das Glas faktisch leer ist (< 2 px Fuellung),
    /// damit er nicht am Boden klebt, bevor die Sitzung begonnen hat.
    @ViewBuilder private var meniscus: some View {
        if self.fillHeight >= 2 {
            Ellipse()
                .fill(Self.meniscusColor)
                .frame(width: self.width * 0.84, height: 3)
                .frame(width: self.width, height: self.height, alignment: .top)
                .offset(y: self.waterlineFromTop)
        }
    }

    /// Schmaler vertikaler Glas-Reflex an der linken Innenseite.
    private var glassReflex: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 6)
            .padding(.vertical, 8)
            .frame(width: self.width, height: self.height, alignment: .leading)
            .padding(.leading, 12)
    }

    // MARK: - Material Constants

    private static let cornerRadius: CGFloat = 28

    /// Glas-Hintergrund: dunkle Tinte, oben transparenter, unten kraeftiger.
    private static let glassFill = LinearGradient(
        colors: [
            Color(red: 58 / 255, green: 32 / 255, blue: 26 / 255).opacity(0.4),
            Color(red: 26 / 255, green: 13 / 255, blue: 9 / 255).opacity(0.6)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private static let glassBorder = Color(
        red: 235 / 255,
        green: 226 / 255,
        blue: 214 / 255
    ).opacity(0.10)

    private static let meniscusColor = Color(
        red: 255 / 255,
        green: 230 / 255,
        blue: 210 / 255
    ).opacity(0.55)
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Vessel — leer (progress 0)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        VesselView(progress: 0.0, reduceMotion: false)
    }
}

@available(iOS 17.0, *)
#Preview("Vessel — halb (progress 0.5)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        VesselView(progress: 0.5, reduceMotion: false)
    }
}

@available(iOS 17.0, *)
#Preview("Vessel — fast voll (progress 0.9)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        VesselView(progress: 0.9, reduceMotion: false)
    }
}

@available(iOS 17.0, *)
#Preview("Vessel — voll (progress 1)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        VesselView(progress: 1.0, reduceMotion: false)
    }
}
#endif
