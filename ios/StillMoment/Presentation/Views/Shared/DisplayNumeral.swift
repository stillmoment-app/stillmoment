//
//  DisplayNumeral.swift
//  Still Moment
//
//  Presentation Layer — container-relative Display-Numerik fuer Typografie 2.1.
//
//  Statt fixer pt-Werte (heute 100/64/62) berechnet die Zahl ihre Groesse aus
//  dem umgebenden Container (`containerDiameter × 0.32`). Floor 56 pt, Ceiling
//  120 pt. Bei AX2+ wird nicht weiter skaliert — der aufrufende Layout-Code
//  verschiebt die Numerik dann unter den Ring (siehe Plan-Section "A11y").
//

import SwiftUI

/// Display-Numerik (Timer-Idle, Timer-Running, Dial-Value). Container-relativ,
/// damit das gleiche View ohne Magic Numbers auf jeder Bildschirm-Klasse
/// stimmt — von SE 2022 (220 pt Mond) bis Pro Max (320 pt Ring).
struct DisplayNumeral: View {
    // MARK: Internal

    let text: String
    let containerDiameter: CGFloat

    var body: some View {
        Text(self.text)
            .font(.custom(
                "Newsreader16pt-Light",
                size: self.cappedSize,
                relativeTo: .largeTitle
            ))
            .monospacedDigit()
            .kerning(-1.5)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    // MARK: Private

    /// Skalierung relativ zur Apple-Skalentabelle fuer `.largeTitle`.
    /// Bei xSmall ~0.82, bei Large 1.0, bei AX1 ~1.35.
    @ScaledMetric(relativeTo: .largeTitle)
    private var scale: CGFloat = 1

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    /// Internal exposure fuer Unit-Tests — nicht von Views ausserhalb dieser Datei
    /// aufrufen.
    var cappedSize: CGFloat {
        Self.cappedSize(
            containerDiameter: self.containerDiameter,
            dynamicTypeScale: self.scale,
            dynamicTypeSize: self.dynamicTypeSize
        )
    }

    /// Pure Berechnungsfunktion — leichter zu testen als die Property auf der View.
    static func cappedSize(
        containerDiameter: CGFloat,
        dynamicTypeScale: CGFloat,
        dynamicTypeSize: DynamicTypeSize
    ) -> CGFloat {
        let raw = containerDiameter * 0.32
        let floored = max(raw, 56)
        let ceiled = min(floored, 120)
        // Plan-Regel: .display cappt bei AX1 — ab AX2 keine weitere Skalierung,
        // der Caller verschiebt die Numerik unter den Container.
        if dynamicTypeSize >= .accessibility2 {
            return ceiled
        }
        return ceiled * dynamicTypeScale
    }
}
