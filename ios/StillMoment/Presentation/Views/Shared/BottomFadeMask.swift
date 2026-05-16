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

import SwiftUI

struct BottomFadeMask: ViewModifier {
    func body(content: Content) -> some View {
        content.mask(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .black, location: 0.0),
                    Gradient.Stop(color: .black, location: 0.82),
                    Gradient.Stop(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

extension View {
    /// Weicher Alpha-Fade am unteren Rand (echte Transparenz, kein Color-Overlay).
    ///
    /// Verwenden auf einem Scroll-Container, der unter einer schwebenden
    /// Tabbar endet — der letzte Inhalt verblasst sanft in den
    /// Hintergrund, ohne Kante und ohne Lasur.
    func bottomFadeMask() -> some View {
        modifier(BottomFadeMask())
    }
}
