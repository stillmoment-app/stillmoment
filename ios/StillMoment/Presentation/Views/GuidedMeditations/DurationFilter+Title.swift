//
//  DurationFilter+Title.swift
//  Still Moment
//
//  Presentation - Lokalisierte Labels der Dauer-Stufen (shared-081).
//
//  Die Keys leben hier und nicht am Domain-Modell, damit `DurationFilter`
//  reine Fachlogik bleibt.
//

import Foundation

extension DurationFilter {
    /// Lokalisierungs-Key des Stufen-Labels.
    var titleKey: String {
        switch self {
        case .all:
            "library.filter.all"
        case .upTo5:
            "library.filter.upTo5"
        case .from5To15:
            "library.filter.5to15"
        case .from15To30:
            "library.filter.15to30"
        case .over30:
            "library.filter.over30"
        }
    }

    /// Aufgeloestes Label — fuer `String(format:)`-Einsetzungen in Saetzen.
    var localizedTitle: String {
        NSLocalizedString(self.titleKey, comment: "Duration filter step")
    }
}
