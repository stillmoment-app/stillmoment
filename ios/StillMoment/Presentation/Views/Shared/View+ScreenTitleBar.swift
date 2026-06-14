//
//  View+ScreenTitleBar.swift
//  Still Moment
//
//  Presentation Layer — gemeinsamer Screen-Titel fuer die Top-Bar.
//
//  Kapselt den `.principal`-Workaround, der bisher in mehreren Screens
//  dupliziert war. Wir nutzen bewusst NICHT `.navigationTitle()`: dieser
//  Modifier ist eine UIKit-Bridge und ignoriert die Theme-Farbe
//  (`@Environment(\.themeColors)`) — der Titel folgt dann System-Schwarz/
//  Weiss statt `textPrimary`, besonders in Sheets sichtbar. Der `.principal`-
//  ToolbarItem mit `.textStyle(.screenTitle, color: \.textPrimary)` ist die
//  korrekte Quelle und macht diese richtige Loesung zum Default — so kehrt
//  der Theme-Farb-Bug nicht stillschweigend zurueck, wenn ein Screen den
//  Workaround vergisst.
//

import SwiftUI

extension View {
    /// Setzt einen inline-Screen-Titel mit korrekter Theme-Farbe (`textPrimary`).
    ///
    /// Ersetzt das Paar aus `.navigationBarTitleDisplayMode(.inline)` und einem
    /// `.principal`-`ToolbarItem`. Weitere `.toolbar`-Modifier (z.B. ein Done-Button
    /// via `.confirmationAction`) koennen unveraendert daneben stehen — SwiftUI
    /// fuehrt mehrere `.toolbar`-Aufrufe additiv zusammen.
    ///
    /// - Parameter titleKey: Der Lokalisierungs-Schluessel des Titels. Wird wie bisher
    ///   ueber `Text(titleKey, bundle: .main)` aufgeloest.
    func screenTitleBar(_ titleKey: LocalizedStringKey) -> some View {
        modifier(ScreenTitleBarModifier(titleKey: titleKey))
    }
}

/// Bindet den Titel an den `.principal`-Slot und setzt `inline`-Darstellung.
/// Die Farbe wird von `.textStyle(.screenTitle, color: \.textPrimary)` aufgeloest,
/// das intern das `ThemeColors`-Environment liest — der Modifier selbst braucht
/// daher kein `@Environment`.
private struct ScreenTitleBarModifier: ViewModifier {
    let titleKey: LocalizedStringKey

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(self.titleKey, bundle: .main)
                        .textStyle(.screenTitle, color: \.textPrimary)
                }
            }
    }
}
