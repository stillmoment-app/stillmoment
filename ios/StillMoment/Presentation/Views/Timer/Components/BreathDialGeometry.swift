//
//  BreathDialGeometry.swift
//  Still Moment
//
//  Presentation Layer - Pure helpers fuer den Atemkreis-Picker (shared-086).
//
//  Keine SwiftUI-Imports — die Funktionen sind reine Mathematik und sollen
//  direkt per XCTest pruefbar sein. Genutzt vom BreathDial-View fuer
//  Drag-Geste, Tropfen-Position, Bogen-Fortschritt und Button-Layout.
//

import CoreGraphics
import Foundation

enum BreathDialGeometry {
    static let maxMinutes: Int = 60
    static let minMinutes: Int = 1

    /// Wandelt einen Beruehrungspunkt (im selben Koordinatensystem wie `center`)
    /// in einen Minutenwert um.
    ///
    /// - 12-Uhr-Position entspricht 0 (snap auf 1),
    ///   3-Uhr = 15, 6-Uhr = 30, 9-Uhr = 45.
    /// - Bogen wird im Uhrzeigersinn aufgespannt.
    /// - Wert wird auf `[1, 60]` geklemmt; 0 wird auf 1 gehoben.
    static func valueFromPoint(_ point: CGPoint, center: CGPoint) -> Int {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let degrees = atan2(dy, dx) * 180 / .pi
        var normalized = (degrees + 90).truncatingRemainder(dividingBy: 360)
        if normalized < 0 {
            normalized += 360
        }
        let raw = Int((normalized / 360 * Double(self.maxMinutes)).rounded())
        let value = raw == 0 ? self.minMinutes : raw
        return self.clampValue(value)
    }

    /// Klemmt einen Roh-Minutenwert auf das gueltige Intervall `[1, 60]`.
    /// Wird sowohl von Drag- als auch +/- Pfaden genutzt.
    static func clampValue(_ value: Int) -> Int {
        max(self.minMinutes, min(self.maxMinutes, value))
    }

    /// Anteil (0...1) fuer den Aktiv-Bogen.
    static func arcProgress(_ value: Int) -> Double {
        Double(value) / Double(self.maxMinutes)
    }

    /// Position des Drag-Tropfens auf dem Ring-Mittelradius bei `value` Minuten.
    /// 0 entspricht 12-Uhr, im Uhrzeigersinn.
    static func dropletPosition(value: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let progress = Double(value) / Double(self.maxMinutes)
        let angleRad = progress * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + cos(angleRad) * radius,
            y: center.y + sin(angleRad) * radius
        )
    }
}
