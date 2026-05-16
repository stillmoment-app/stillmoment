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
///   Tiefe wird ueber einen Opacity-Verlauf erzeugt: oben transparenter,
///   unten kraeftiger.
/// - Glas-Material (Hintergrund-Tint, Border, Reflex) reagiert auf das
///   ColorScheme: im Light Mode dezenter dunkler Tint und dunkler Reflex
///   auf hellem Background, im Dark Mode warmes dunkles Material mit
///   hellem Reflex.
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
                .strokeBorder(self.glassBorder, lineWidth: 1)
        )
        .animation(self.fluidAnimation, value: self.progress)
        .accessibilityHidden(true)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @Environment(\.colorScheme)
    private var colorScheme

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
            .fill(self.glassFill)
            .frame(width: self.width, height: self.height)
    }

    /// Glas-Hintergrund passt sich dem ColorScheme an:
    /// - Light: dezenter dunkler Tint auf hellem Background (warmer
    ///   dunkler Schiefer-Ton, neutral genug fuer alle drei Themes).
    /// - Dark: warmes dunkles Material, das dem bisherigen Look folgt.
    /// Beide Stufen werden zusaetzlich ueber einen Opacity-Verlauf
    /// (oben transparenter, unten kraeftiger) raeumlich vertieft.
    private var glassFill: LinearGradient {
        switch self.colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 58 / 255, green: 32 / 255, blue: 26 / 255).opacity(0.40),
                    Color(red: 26 / 255, green: 13 / 255, blue: 9 / 255).opacity(0.60)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .light:
            return LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        @unknown default:
            return LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Border-Farbe: dezent, theme-getoned. `controlTrack` ist in beiden
    /// Modes ein mittlerer Ton — als 25 %-Opacity-Linie sichtbar, ohne
    /// laut zu werden.
    private var glassBorder: Color {
        self.theme.controlTrack.opacity(0.25)
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
    /// Im Dark Mode heller Schimmer (Weiss), im Light Mode dunklerer
    /// Glanz-Strich (`textPrimary`) — beides erzeugt die "Glas-Kante".
    private var glassReflex: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(
                    colors: [self.reflexColor.opacity(0.18), self.reflexColor.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 6)
            .padding(.vertical, 8)
            .frame(width: self.width, height: self.height, alignment: .leading)
            .padding(.leading, 12)
    }

    private var reflexColor: Color {
        switch self.colorScheme {
        case .dark: .white
        case .light: self.theme.textPrimary
        @unknown default: .white
        }
    }

    // MARK: - Material Constants

    private static let cornerRadius: CGFloat = 28

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

@available(iOS 17.0, *)
#Preview("Vessel — Light Mode, halb") {
    ZStack {
        Color(red: 1.00, green: 0.89, blue: 0.84).ignoresSafeArea()
        VesselView(progress: 0.5, reduceMotion: false)
    }
    .preferredColorScheme(.light)
}
#endif
