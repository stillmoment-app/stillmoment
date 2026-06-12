//
//  TrimEditorHeader.swift
//  Still Moment
//
//  Presentation Layer — title + big readout block of the trim editor (shared-107).
//

import SwiftUI

/// The block above the waveform: meditation title, teacher · file duration, the eyebrow
/// label for the active point ("BEGINNT BEI"/"ENDET BEI"), the large active-value readout
/// and the "Hörbar: {start} – {end} · {dauer}" line.
struct TrimEditorHeader: View {
    // MARK: Internal

    let title: String
    let teacher: String
    let fileDuration: TimeInterval
    let activePoint: TrimPoint
    let activeValue: TimeInterval
    let start: TimeInterval
    let end: TimeInterval

    var body: some View {
        VStack(spacing: 6) {
            Text(self.title)
                .textStyle(.section, color: \.textPrimary)
                .multilineTextAlignment(.center)
            Text(self.subtitle)
                .textStyle(.caption, color: \.textSecondary)

            VStack(spacing: 4) {
                Text(self.eyebrowKey)
                    .textStyle(.eyebrow, color: \.textSecondary)
                    .padding(.top, 20)
                DisplayNumeral(text: EditSheetState.formatTime(self.activeValue), containerDiameter: 180)
                    .foregroundColor(self.theme.interactive)
                    .accessibilityHidden(true)
                Text(self.audibleLine)
                    .textStyle(.caption, monospacedDigits: true, color: \.textSecondary)
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var subtitle: String {
        String(
            format: NSLocalizedString("trim_editor.subtitle", comment: "Teacher · file duration"),
            self.teacher,
            EditSheetState.formatTime(self.fileDuration)
        )
    }

    private var eyebrowKey: LocalizedStringKey {
        self.activePoint == .start ? "trim_editor.label.beginsAt" : "trim_editor.label.endsAt"
    }

    private var audibleLine: String {
        String(
            format: NSLocalizedString("trim_editor.audible", comment: "Audible range summary"),
            EditSheetState.formatTime(self.start),
            EditSheetState.formatTime(self.end),
            EditSheetState.formatTime(self.end - self.start)
        )
    }
}
