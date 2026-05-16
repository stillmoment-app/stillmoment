//
//  PlayerCenterDisc.swift
//  Still Moment
//
//  Presentation Layer — statische Gluehscheibe als visueller Anker im Player.
//

import SwiftUI

/// Statische Gluehscheibe hinter dem Pause-Button im Atemkreis-Player.
///
/// Kein Skalieren, kein Pulsieren, kein Opazitaets-Wechsel — reine visuelle
/// Ruhezone, die den zentralen Bereich des Rings warm anhebt. Im Dark Mode
/// leicht waermer und sichtbarer, im Light Mode dezenter. Hex-Werte und
/// Opacities folgen dem KS-2.0-Player-Handoff.
struct PlayerCenterDisc: View {
    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: self.gradientStops),
                    center: .center,
                    startRadius: 0,
                    endRadius: 110
                )
            )
            .frame(width: 220, height: 220)
            .allowsHitTesting(false)
    }

    private var gradientStops: [Gradient.Stop] {
        switch self.colorScheme {
        case .dark:
            [
                Gradient.Stop(
                    color: Color(red: 214.0 / 255, green: 138.0 / 255, blue: 110.0 / 255, opacity: 0.10),
                    location: 0.0
                ),
                Gradient.Stop(
                    color: Color(red: 199.0 / 255, green: 125.0 / 255, blue: 99.0 / 255, opacity: 0.04),
                    location: 0.5
                ),
                Gradient.Stop(color: .clear, location: 0.8),
                Gradient.Stop(color: .clear, location: 1.0)
            ]
        default:
            [
                Gradient.Stop(
                    color: Color(red: 162.0 / 255, green: 80.0 / 255, blue: 62.0 / 255, opacity: 0.07),
                    location: 0.0
                ),
                Gradient.Stop(
                    color: Color(red: 162.0 / 255, green: 80.0 / 255, blue: 62.0 / 255, opacity: 0.03),
                    location: 0.5
                ),
                Gradient.Stop(color: .clear, location: 0.8),
                Gradient.Stop(color: .clear, location: 1.0)
            ]
        }
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Dark") {
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

        PlayerCenterDisc()
    }
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Light") {
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

        PlayerCenterDisc()
    }
    .preferredColorScheme(.light)
}
