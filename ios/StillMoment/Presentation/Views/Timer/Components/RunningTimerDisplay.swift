//
//  RunningTimerDisplay.swift
//  Still Moment
//
//  Presentation Layer — Hauptphase des Timers: Zeit-Block oben, Mondphase
//  unten (shared-095).
//

import SwiftUI

/// Layout-Komponente fuer die laufende Sitzung: Zeit-Block (Eyebrow
/// „VERBLEIBEND", grosse MM:SS, kursives „von X Minuten") im oberen
/// Drittel, Mondphase im unteren Drittel.
///
/// Die Komponente liest die Anzeige-Werte vom uebergeordneten View und ist
/// rein praesentational. Layout folgt dem Mondphasen-Handoff: TextBlock zentriert
/// oben, MoonPhaseView ueber `Spacer(maxHeight: .infinity)` ins untere Drittel
/// gedrueckt. Mond-Durchmesser skaliert proportional (220 pt Standard, 180 pt
/// auf kompakten Geraeten).
struct RunningTimerDisplay: View {
    // MARK: Internal

    let progress: Double
    let remainingTimeText: String
    let durationLabel: String
    let accessibilityTimeValue: String
    let reduceMotion: Bool
    var isCompactHeight: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: self.topSpacing)
                .frame(maxHeight: self.topSpacing)

            self.textColumn

            Spacer(minLength: 16)

            MoonPhaseView(
                progress: self.progress,
                reduceMotion: self.reduceMotion,
                outerSize: self.moonSize
            )

            Spacer(minLength: self.bottomSpacing)
                .frame(maxHeight: self.bottomSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Private

    private var topSpacing: CGFloat {
        self.isCompactHeight ? 24 : 40
    }

    private var bottomSpacing: CGFloat {
        self.isCompactHeight ? 16 : 32
    }

    private var moonSize: CGFloat {
        self.isCompactHeight ? 180 : 220
    }

    private var textColumn: some View {
        VStack(spacing: 0) {
            Text("timer.running.remaining", bundle: .main)
                .themeFont(.cardLabel, color: \.textSecondary)
                .tracking(2.4)
                .accessibilityHidden(true)

            Text(self.remainingTimeText)
                .themeFont(.timerRunning)
                .monospacedDigit()
                .lineLimit(1)
                .padding(.top, 6)
                .accessibilityIdentifier("timer.display.time")
                .accessibilityLabel("guided_meditations.player.remainingTime")
                .accessibilityValue(self.accessibilityTimeValue)

            Text(self.durationLabel)
                .themeFont(.bodySecondary)
                .italic()
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
