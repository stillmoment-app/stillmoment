//
//  RunningTimerDisplay.swift
//  Still Moment
//
//  Presentation Layer — Hauptphase des Timers: Zeit-Block oben, Mondphase
//  unten (shared-095).
//

import SwiftUI

/// Layout-Komponente fuer die laufende Sitzung: Zeit-Block oben,
/// Mondphase unten — vertikal nach dem Goldenen Schnitt verteilt
/// (Text-Mitte ~30 %, Mond-Mitte ~62 % der verfuegbaren Hoehe).
///
/// Die Komponente liest die Anzeige-Werte vom uebergeordneten View und
/// ist rein praesentational. Mond-Durchmesser skaliert proportional
/// (220 pt Standard, 180 pt auf kompakten Geraeten).
struct RunningTimerDisplay: View {
    // MARK: Internal

    let progress: Double
    let remainingTimeText: String
    let durationLabel: String
    let accessibilityTimeValue: String
    let reduceMotion: Bool
    var isCompactHeight: Bool = false

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                self.textColumn
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height * Self.textCenterRatio
                    )

                MoonPhaseView(
                    progress: self.progress,
                    reduceMotion: self.reduceMotion,
                    outerSize: self.moonSize
                )
                .position(
                    x: proxy.size.width / 2,
                    y: proxy.size.height * Self.moonCenterRatio
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    // MARK: Private

    /// Goldener Schnitt: 1/Phi ≈ 0.382. Komplementaer dazu 0.618.
    private static let textCenterRatio: CGFloat = 0.30
    private static let moonCenterRatio: CGFloat = 0.62

    private var moonSize: CGFloat {
        self.isCompactHeight ? 180 : 220
    }

    private var textColumn: some View {
        VStack(spacing: 0) {
            Text("timer.running.remaining", bundle: .main)
                .textStyle(.micro, color: \.textSecondary)
                .tracking(2.4)
                .accessibilityHidden(true)

            DisplayNumeral(text: self.remainingTimeText, containerDiameter: self.moonSize)
                .foregroundColor(self.theme.textPrimary)
                .padding(.top, 6)
                .accessibilityIdentifier("timer.display.time")
                .accessibilityLabel("guided_meditations.player.remainingTime")
                .accessibilityValue(self.accessibilityTimeValue)

            Text(self.durationLabel)
                .textStyle(.caption, color: \.textSecondary)
                .padding(.top, 12)
                .accessibilityHidden(true)
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Running — Start (Dark)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        RunningTimerDisplay(
            progress: 0.0,
            remainingTimeText: "10:00",
            durationLabel: "von 10 Minuten",
            accessibilityTimeValue: "10 Minuten verbleibend",
            reduceMotion: false
        )
    }
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Running — Halbzeit (Dark)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        RunningTimerDisplay(
            progress: 0.5,
            remainingTimeText: "05:00",
            durationLabel: "von 10 Minuten",
            accessibilityTimeValue: "5 Minuten verbleibend",
            reduceMotion: false
        )
    }
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Running — Ende (Light)") {
    ZStack {
        Color(red: 1.00, green: 0.89, blue: 0.84).ignoresSafeArea()
        RunningTimerDisplay(
            progress: 1.0,
            remainingTimeText: "00:00",
            durationLabel: "von 10 Minuten",
            accessibilityTimeValue: "Sitzung beendet",
            reduceMotion: false
        )
    }
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Running — kompakt (SE, Dark)") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
        RunningTimerDisplay(
            progress: 0.3,
            remainingTimeText: "07:00",
            durationLabel: "von 10 Minuten",
            accessibilityTimeValue: "7 Minuten verbleibend",
            reduceMotion: false,
            isCompactHeight: true
        )
    }
    .preferredColorScheme(.dark)
}
#endif
