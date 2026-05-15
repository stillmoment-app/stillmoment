//
//  RunningTimerDisplay.swift
//  Still Moment
//
//  Presentation Layer — Hauptphase des Timers: Vessel + Restzeit (ios-046).
//

import SwiftUI

/// Layout-Komponente fuer die laufende Sitzung: Sanduhr-Vessel links,
/// Restzeit-Block rechts (Eyebrow „VERBLEIBEND", grosse MM:SS, kursives
/// „von X Minuten").
///
/// Die Komponente liest die Anzeige-Werte vom uebergeordneten View und ist
/// rein praesentational. Layout-Maße folgen dem Handoff (110 × 360 pt
/// Vessel, 36 pt Gap, 64 pt Restzeit) und skalieren auf kompakten
/// Geraeten proportional.
struct RunningTimerDisplay: View {
    // MARK: Internal

    let progress: Double
    let remainingTimeText: String
    let durationLabel: String
    let accessibilityTimeValue: String
    let reduceMotion: Bool
    var isCompactHeight: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: self.horizontalSpacing) {
            VesselView(
                progress: self.progress,
                reduceMotion: self.reduceMotion,
                width: self.vesselWidth,
                height: self.vesselHeight
            )

            self.textColumn
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var vesselWidth: CGFloat {
        self.isCompactHeight ? 92 : 110
    }

    private var vesselHeight: CGFloat {
        self.isCompactHeight ? 304 : 360
    }

    private var horizontalSpacing: CGFloat {
        self.isCompactHeight ? 24 : 36
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                .padding(.top, 18)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Running — voll") {
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
}

@available(iOS 17.0, *)
#Preview("Running — halb") {
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
}

@available(iOS 17.0, *)
#Preview("Running — kompakt (SE)") {
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
}
#endif
