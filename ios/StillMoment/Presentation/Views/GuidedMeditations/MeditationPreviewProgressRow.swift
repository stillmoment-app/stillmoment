//
//  MeditationPreviewProgressRow.swift
//  Still Moment
//
//  Presentation Layer — Slider mit Zeit-Labels fuer das Library-Vorhoeren (shared-098).
//

import SwiftUI

/// Schmaler Fortschritts-Slider mit Zeit-Labels. Erscheint unter einer Library-Zeile,
/// solange dort eine Preview-Wiedergabe laeuft.
///
/// Apple-Music-Style: waehrend des Drags folgt der Slider dem Finger ueber einen
/// lokalen State; beim Loslassen wird einmal `onSeek` aufgerufen und das Audio
/// springt zur neuen Position. Audio laeuft durchgehend weiter.
///
/// Pattern: der Slider haelt seinen eigenen `draftTime`-State und wird nur dann mit
/// dem extern eintreffenden `currentTime` synchronisiert, wenn der User gerade
/// NICHT draggt. Computed-Bindings auf einen optionalen Drag-Wert haben sich als
/// fragil erwiesen — der UISlider hat seinen Wert beim Loslassen festgehalten und
/// nicht mehr mit dem ViewModel mitgelaufen.
struct MeditationPreviewProgressRow: View {
    /// Aktuelle Wiedergabeposition in Sekunden (vom ViewModel).
    let currentTime: TimeInterval
    /// Gesamtdauer in Sekunden.
    let duration: TimeInterval
    /// Wird einmal beim Loslassen des Sliders mit der finalen Zielzeit aufgerufen.
    let onSeek: (TimeInterval) -> Void

    @Environment(\.themeColors)
    private var theme

    /// Aktueller Slider-Wert. Wird waehrend des Drags vom Slider gesetzt; ausserhalb
    /// des Drags vom `currentTime` getrieben (siehe `.onChange`).
    @State private var draftTime: TimeInterval = 0
    /// `true` waehrend einer aktiven Drag-Geste — blockt waehrenddessen Sync von aussen.
    @State private var isDragging: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(Self.formatTime(self.draftTime))
                .textStyle(.caption, monospacedDigits: true, color: \.textSecondary)
                .frame(minWidth: 36, alignment: .leading)

            Slider(
                value: self.$draftTime,
                in: 0...max(self.duration, 0.001)
            ) { editing in
                self.isDragging = editing
                if !editing {
                    self.onSeek(self.draftTime)
                }
            }
            .tint(self.theme.interactive)
            .accessibilityIdentifier("library.preview.slider")
            .accessibilityLabel("accessibility.library.preview.position")

            Text(Self.formatTime(self.duration))
                .textStyle(.caption, monospacedDigits: true, color: \.textSecondary)
                .frame(minWidth: 36, alignment: .trailing)
        }
        .padding(.top, 6)
        .onAppear {
            self.draftTime = self.currentTime
        }
        .onChange(of: self.currentTime) { newValue in
            if !self.isDragging {
                self.draftTime = newValue
            }
        }
    }

    private static func formatTime(_ time: TimeInterval) -> String {
        let safe = max(0, time)
        let hours = Int(safe) / 3600
        let minutes = (Int(safe) % 3600) / 60
        let seconds = Int(safe) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Mid playback") {
    MeditationPreviewProgressRow(
        currentTime: 42,
        duration: 691
    ) { _ in }
        .padding()
        .background(Color(red: 0.97, green: 0.93, blue: 0.86))
}

@available(iOS 17.0, *)
#Preview("Near start") {
    MeditationPreviewProgressRow(
        currentTime: 3,
        duration: 600
    ) { _ in }
        .padding()
}
