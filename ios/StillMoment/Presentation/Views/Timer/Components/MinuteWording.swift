//
//  MinuteWording.swift
//  Still Moment
//
//  Presentation Layer - Einzahl/Mehrzahl fuer Minutenangaben (shared-140).
//
//  Liefert die lokalisierte Einheit, die unter einer Minutenzahl steht
//  („Minute" bei 1, „Minutes"/„Minuten" ab 2), und die Screenreader-Ansage
//  der Dauer („1 minute"/„2 minutes"). Die Plural-Form waehlt die
//  `Localizable.stringsdict`. Grossschreibung kommt vom Text-Token, nicht
//  vom String. Gedacht zur Wiederverwendung, wenn der Atemkreis durch
//  „Zahl mit Einheit darunter" ersetzt wird (shared-125).
//

import Foundation

enum MinuteWording {
    /// Einheit unter der Zahl, ohne die Zahl selbst.
    static func unit(for minutes: Int, bundle: Bundle = .main) -> String {
        self.format("timer.dial.unit", minutes: minutes, bundle: bundle)
    }

    /// Gesprochene Dauer mit Zahl, z. B. fuer den Screenreader-Wert.
    static func spokenDuration(for minutes: Int, bundle: Bundle = .main) -> String {
        self.format("accessibility.dial.value", minutes: minutes, bundle: bundle)
    }

    private static func format(_ key: String, minutes: Int, bundle: Bundle) -> String {
        String.localizedStringWithFormat(
            bundle.localizedString(forKey: key, value: nil, table: nil),
            minutes
        )
    }
}
