//
//  ThemeColors+Palettes.swift
//  Still Moment
//
//  Presentation Layer - Concrete color values for the single theme in light + dark mode.
//
//  All colors are inline RGB (sRGB color space). Values match the
//  "Kerzenschein 2.0" handover (shared-094):
//  - Light: Sunrise Confident — saturated cream/peach/apricot gradient, warm earthy ink.
//  - Dark: Lifted Warm — warm card lift gegen alle drei Gradient-Stops, warmer Border.
//

import SwiftUI

extension ThemeColors {
    /// Sunrise Confident — gesaettigter Sonnenaufgang-Gradient mit warmer Tinte.
    static let light = ThemeColors(
        // textPrimary #3A2418 — warme Tinte (waermer als zuvor)
        textPrimary: Color(red: 0.227, green: 0.141, blue: 0.094),
        // textSecondary #7A4E3C — Erdbraun
        textSecondary: Color(red: 0.478, green: 0.306, blue: 0.235),
        // textOnInteractive #FFF6E6 — warmes Cream (= cardBackground)
        textOnInteractive: Color(red: 1.000, green: 0.965, blue: 0.902),
        // interactive #A2503E — Spur tiefer als vorher
        interactive: Color(red: 0.635, green: 0.314, blue: 0.243),
        // progress = interactive
        progress: Color(red: 0.635, green: 0.314, blue: 0.243),
        controlTrack: Color(red: 0.580, green: 0.490, blue: 0.435),
        // backgroundPrimary #FBEEDB — gesaettigter Cream
        backgroundPrimary: Color(red: 0.984, green: 0.933, blue: 0.859),
        // backgroundSecondary #F6CDA8 — echter Pfirsich
        backgroundSecondary: Color(red: 0.965, green: 0.804, blue: 0.659),
        // cardBackground #FFF6E6 — heller als bg-top, traegt den Lift
        cardBackground: Color(red: 1.000, green: 0.965, blue: 0.902),
        // cardBorder rgba(120, 55, 28, 0.11) — warmer Hauch
        cardBorder: Color(red: 120 / 255, green: 55 / 255, blue: 28 / 255, opacity: 0.11),
        ringTrack: Color(red: 0.784, green: 0.655, blue: 0.588),
        // accentBackground #E8A074 — warmer Apricot, fest (Akzent-Stop)
        accentBackground: Color(red: 0.910, green: 0.627, blue: 0.455),
        // divider rgba(120, 55, 28, 0.14) — warmer Trenner in Akzent-Familie
        divider: Color(red: 120 / 255, green: 55 / 255, blue: 28 / 255, opacity: 0.14),
        // playGradientTop #B85F46
        playGradientTop: Color(red: 0.722, green: 0.373, blue: 0.275),
        // playGradientBot #7E3A2D
        playGradientBot: Color(red: 0.494, green: 0.227, blue: 0.176),
        error: Color(red: 0.729, green: 0.102, blue: 0.102)
    )

    /// Lifted Warm — Karten heben sich gegen alle drei Gradient-Stops,
    /// warmer Border statt neutraler Edge.
    static let dark = ThemeColors(
        // textPrimary #E5DCCD (unchanged)
        textPrimary: Color(red: 0.898, green: 0.863, blue: 0.804),
        // textSecondary #A68A80 (unchanged)
        textSecondary: Color(red: 0.651, green: 0.541, blue: 0.502),
        // textOnInteractive #1A100C (unchanged)
        textOnInteractive: Color(red: 0.102, green: 0.063, blue: 0.047),
        // interactive #C77D63 (unchanged)
        interactive: Color(red: 0.780, green: 0.490, blue: 0.388),
        progress: Color(red: 0.780, green: 0.490, blue: 0.388),
        controlTrack: Color(red: 0.510, green: 0.412, blue: 0.376),
        // backgroundPrimary #1A100C (unchanged)
        backgroundPrimary: Color(red: 0.102, green: 0.063, blue: 0.047),
        // backgroundSecondary #321F19 (unchanged)
        backgroundSecondary: Color(red: 0.196, green: 0.122, blue: 0.098),
        // cardBackground #2E211A — warm, lifted (NEU)
        cardBackground: Color(red: 0.180, green: 0.129, blue: 0.102),
        // cardBorder #4E382C — warm (NEU)
        cardBorder: Color(red: 0.306, green: 0.220, blue: 0.173),
        ringTrack: Color(red: 0.632, green: 0.377, blue: 0.307),
        // accentBackground #5D3A2F (unchanged)
        accentBackground: Color(red: 0.365, green: 0.227, blue: 0.184),
        // divider rgba(242, 228, 211, 0.10) — verstaerkter Trenner
        divider: Color(red: 242 / 255, green: 228 / 255, blue: 211 / 255, opacity: 0.10),
        // playGradientTop #D68A6E
        playGradientTop: Color(red: 0.839, green: 0.541, blue: 0.431),
        // playGradientBot #B06A4F
        playGradientBot: Color(red: 0.690, green: 0.416, blue: 0.310),
        error: Color(red: 0.878, green: 0.380, blue: 0.318)
    )
}
