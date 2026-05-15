//
//  RingMetrics.swift
//  Still Moment
//
//  Presentation Layer — geteilte Ring-Konstanten fuer Idle (`BreathDial`) und
//  Running (`BreathingCircleView`). Aenderungen ziehen beide Komponenten
//  gemeinsam — damit Idle und Running garantiert dieselbe Ring-Sprache sprechen.
//

import CoreGraphics

enum RingMetrics {
    /// Strichstaerke fuer Track-Ring und Fortschritts-Bogen.
    static let lineWidth: CGFloat = 3

    /// Durchmesser des Bead/Punkt am Ring in Ruhegroesse.
    static let beadDiameter: CGFloat = 9

    /// Shadow-Radius des Bead — weicher Glow in Akzentfarbe.
    static let beadShadowRadius: CGFloat = 4
}
