//
//  SecondWording.swift
//  Still Moment
//
//  Presentation Layer - Einzahl/Mehrzahl fuer Sekundenangaben (shared-145).
//
//  Liefert die Screenreader-Ansagen der Vorbereitungszeit: im Timer
//  („Preparation: 1 second") und im Player einer gefuehrten Meditation
//  („1 second until meditation starts"). Die Plural-Form waehlt die
//  `Localizable.stringsdict`, nicht eine Fallunterscheidung im Code.
//  Gegenstueck zu `MinuteWording` (shared-140).
//

import Foundation

enum SecondWording {
    /// Vorbereitungszeit im Timer: Ansage im Atemkreis und Wert des Dauer-Reglers.
    static func preparation(for seconds: Int, bundle: Bundle = .main) -> String {
        self.format("accessibility.preparation", seconds: seconds, bundle: bundle)
    }

    /// Vorbereitungszeit im Player einer gefuehrten Meditation.
    static func countdown(for seconds: Int, bundle: Bundle = .main) -> String {
        self.format("guided_meditations.player.countdown", seconds: seconds, bundle: bundle)
    }

    private static func format(_ key: String, seconds: Int, bundle: Bundle) -> String {
        String.localizedStringWithFormat(
            bundle.localizedString(forKey: key, value: nil, table: nil),
            seconds
        )
    }
}
