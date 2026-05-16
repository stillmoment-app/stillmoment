//
//  SoftFadeOverlay.swift
//  Still Moment
//
//  Presentation Layer - Bottom fade between scroll content and tab bar
//  (shared-094 Kerzenschein 2.0).
//
//  Sits visually between the scroll region and the tab bar:
//  - Transparent at the top, fading through `fadeMid` into the gradient's
//    accent stop (`accentBackground`) at the bottom.
//  - Both modes share the same paint mechanism; only the colors differ.
//  - `allowsHitTesting(false)` so the fade never blocks taps on cards or
//    list rows behind it.
//

import SwiftUI

/// Bottom soft-fade overlay matching the gradient background's accent stop.
///
/// Use as `.overlay(alignment: .bottom) { SoftFadeOverlay() }` on a screen's
/// scroll-content container. The 140pt height comes from the design handover
/// and is intentionally not coupled to safe-area insets.
struct SoftFadeOverlay: View {
    @Environment(\.themeColors)
    private var theme

    /// Fixed handover height; not responsive to device size.
    private let height: CGFloat = 140

    var body: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: .clear, location: 0.0),
                Gradient.Stop(color: self.theme.fadeMid, location: 0.55),
                Gradient.Stop(color: self.theme.accentBackground, location: 0.92)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: self.height)
        .allowsHitTesting(false)
    }
}
