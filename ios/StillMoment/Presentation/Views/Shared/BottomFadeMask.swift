//
//  BottomFadeMask.swift
//  Still Moment
//
//  Presentation Layer - Bottom-edge mask fade (shared-094 Kerzenschein 2.0).
//
//  Macht den Listen-Inhalt am unteren Rand selbst transparent, sodass der
//  Seiten-Hintergrund direkt durchscheint. Im Gegensatz zu einem farbigen
//  Overlay-Gradient (der eine warm getoente Lasur ueber den Content gelegt
//  haette und dadurch eine sichtbare Kante + Spiegel-Eindruck erzeugt)
//  arbeitet diese Loesung als echte Alpha-Maske — farbneutral, ohne
//  Stop-Sprung. Apple-Standard fuer Edge-Fades unter schwebenden Tabbars.
//
//  Die Fade-Zone ist absolut (140pt am unteren Rand), nicht prozentual zur
//  Hoehe der maskierten View: Der Modifier liegt auf einem bildschirmhohen
//  Scroll-Container, dort haette ein prozentualer Gradient eine Uebergangs-
//  zone von ueber 100pt erzeugt und die letzte Listenzeile unlesbar gemacht.
//  Innerhalb der 140pt-Zone bleiben 82 % deckend, die restlichen 18 % sind
//  der eigentliche Uebergang — identisch zum Android-Pendant
//  `BottomFadeMask.kt` (`fadeHeight: Dp = 140.dp`).
//

import SwiftUI

struct BottomFadeMask: ViewModifier {
    /// Luft unter der letzten Zeile einer maskierten Liste — siehe
    /// `bottomFadeContentInset()`. Gehoert hierher, weil der Wert zur Fade-Zone
    /// passen muss: Beide Listen der Bibliothek liegen unter derselben Maske.
    static let contentInset: CGFloat = 80

    func body(content: Content) -> some View {
        content.mask(
            VStack(spacing: 0) {
                // Nimmt den gesamten Restplatz oberhalb der Fade-Zone ein.
                Color.black

                LinearGradient(
                    stops: [
                        Gradient.Stop(color: .black, location: 0.0),
                        Gradient.Stop(color: .black, location: 0.82),
                        Gradient.Stop(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Self.fadeZoneHeight)
            }
        )
    }

    // MARK: Private

    /// Hoehe der Fade-Zone am unteren Rand — spiegelt `fadeHeight` auf Android.
    private static let fadeZoneHeight: CGFloat = 140
}

extension View {
    /// Weicher Alpha-Fade am unteren Rand (echte Transparenz, kein Color-Overlay).
    ///
    /// Verwenden auf einem Scroll-Container, der unter einer schwebenden
    /// Tabbar endet — der letzte Inhalt verblasst sanft in den
    /// Hintergrund, ohne Kante und ohne Lasur. Die Fade-Zone ist 140pt hoch,
    /// unabhaengig von der Hoehe des Containers.
    func bottomFadeMask() -> some View {
        modifier(BottomFadeMask())
    }

    /// Gegenstueck zur Fade-Zone: Luft unter der letzten Zeile.
    ///
    /// Auf die Liste selbst anwenden, nicht auf den maskierten Container — sonst
    /// verschieben sich die Bounds, an denen die Maske haengt. Ohne diesen Abstand
    /// endet die Liste an der Bildschirmkante: Die letzte Zeile bleibt im
    /// Uebergang stecken und zusaetzlich hinter der schwebenden Tabbar, auch wenn
    /// man ganz nach unten scrollt. Spiegelt `contentPadding(bottom = 80.dp)`
    /// auf Android.
    func bottomFadeContentInset() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: BottomFadeMask.contentInset)
        }
    }
}
