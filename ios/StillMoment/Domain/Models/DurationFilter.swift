//
//  DurationFilter.swift
//  Still Moment
//
//  Domain - Dauer-Stufen zum Filtern der Bibliothek (shared-081).
//

import Foundation

/// Eine der fuenf Dauer-Stufen, nach denen die Bibliothek gefiltert werden kann.
///
/// Gefiltert wird die **effektive** Dauer (`GuidedMeditation.effectiveDuration`),
/// also die Zahl, die in der Liste steht — eine getrimmte Meditation faellt in die
/// Stufe ihrer getrimmten Laenge, nicht in die ihrer Dateilaenge.
///
/// Die Reihenfolge der Cases ist die Anzeige-Reihenfolge der Filterzeile.
enum DurationFilter: String, CaseIterable, Equatable {
    case all
    case upTo5
    case from5To15
    case from15To30
    case over30

    /// Halboffenes Sekunden-Intervall der Stufe — `[lowerBound, upperBound)`.
    ///
    /// Die obere Grenze ist bewusst exklusiv, damit jede Dauer genau einer Stufe
    /// gehoert: 4:59 liegt in `upTo5`, 5:00 in `from5To15`.
    var secondsRange: Range<TimeInterval> {
        switch self {
        case .all:
            0..<TimeInterval.infinity
        case .upTo5:
            0..<Self.fiveMinutes
        case .from5To15:
            Self.fiveMinutes..<Self.fifteenMinutes
        case .from15To30:
            Self.fifteenMinutes..<Self.thirtyMinutes
        case .over30:
            Self.thirtyMinutes..<TimeInterval.infinity
        }
    }

    /// Ob die Dauer dieser Meditation in die Stufe faellt.
    func matches(_ meditation: GuidedMeditation) -> Bool {
        self.secondsRange.contains(meditation.effectiveDuration)
    }

    /// Behaelt nur die Meditationen, die in die Stufe fallen — Reihenfolge bleibt erhalten.
    func apply(to meditations: [GuidedMeditation]) -> [GuidedMeditation] {
        meditations.filter { self.matches($0) }
    }

    /// Die Stufen, in die mindestens eine der Meditationen faellt.
    ///
    /// `all` ist immer enthalten — auch bei leerer Liste. Stufen, die hier fehlen,
    /// stellt die Filterzeile blass und nicht antippbar dar.
    static func availableSteps(in meditations: [GuidedMeditation]) -> Set<DurationFilter> {
        let occupied = Self.allCases.filter { step in
            step != .all && meditations.contains { step.matches($0) }
        }
        return Set(occupied).union([.all])
    }

    // MARK: Private

    private static let fiveMinutes: TimeInterval = 5 * 60
    private static let fifteenMinutes: TimeInterval = 15 * 60
    private static let thirtyMinutes: TimeInterval = 30 * 60
}
