# Ticket shared-093: Theme-System auf ein Theme reduzieren

**Status**: [~] IN PROGRESS (iOS DONE, Android offen)
**Prioritaet**: MITTEL
**Komplexitaet**: Mechanisches Aufraeumen ueber mehrere Layer (Domain, Presentation, Settings-UI, Localization, Tests). Persistierte Theme-Auswahl muss beim Update graceful ignoriert werden. Risiko: Kontrast-/Snapshot-Tests die ueber alle Themes iterieren; tote Localization-Keys; Screenshot-Fixtures die ein bestimmtes Theme erwarten.
**Phase**: 2-Architektur
**Plan (iOS)**: [Implementierungsplan](../plans/shared-093-ios.md)

---

## Was

Die Auswahl zwischen mehreren Color-Themes (Kerzenschein, Wald, Mondlicht) entfaellt. Es bleibt genau ein Theme, das die aktuellen Kerzenschein-Werte uebernimmt. Die Auswahl Light/Dark/System bleibt unveraendert bestehen.

## Warum

Drei Themes parallel pflegen kostet Energie ohne erkennbaren Nutzen fuer den User — Farbwerte feinjustieren, Kontrast-Tests, Picker-Vorschauen, Localization. Eine sorgfaeltig kuratierte Palette in Light + Dark passt besser zur App-Philosophie ("weniger ist mehr") und entlastet die folgende Refinement-Arbeit. Voraussetzung fuer ein Folge-Ticket, in dem die einzig verbleibende Palette gezielt verfeinert wird.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Einstellungen enthalten keinen Theme-Picker / keine Theme-Vorschau mehr
- [ ] App zeigt eine einzige Farbpalette — visuell identisch zum bisherigen Kerzenschein in Light und Dark
- [ ] Erscheinungsbild-Auswahl (Hell / Dunkel / System) funktioniert unveraendert
- [ ] Bestandskunden, die zuvor Wald oder Mondlicht gewaehlt hatten, sehen nach dem Update die neue (einzige) Palette ohne Crash oder Fehlermeldung
- [ ] Keine toten Localization-Keys fuer Theme-Namen oder Theme-bezogene Settings-Labels in DE und EN
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Kontrast-Tests (WCAG) decken die verbleibende Palette in Light und Dark ab
- [ ] Tests, die ueber alle Themes iteriert haben, sind sinnvoll reduziert (nicht nur auskommentiert)
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md — user-sichtbare Aenderung (Theme-Auswahl entfaellt)
- [ ] CLAUDE.md auf beiden Plattformen pruefen: Verweise auf Theme-Auswahl, ColorTheme-Enum oder Theme-Picker entfernen
- [ ] Memory-Notes auf `MEMORY.md` pruefen: gibt es Hinweise auf Theme-Switching, die ueberholt sind?

---

## Manueller Test

1. App mit zuvor gesetztem Theme "Wald" oder "Mondlicht" updaten (UserDefaults / SharedPreferences-Eintrag vorbelegen oder im Simulator/Emulator vorher einstellen)
2. App starten
3. Einstellungen oeffnen
4. Erwartung (beide Plattformen identisch):
   - Kein Theme-Picker / keine Theme-Sektion sichtbar
   - App zeigt die Kerzenschein-Farben in Light und Dark
   - Erscheinungsbild-Wechsel (Hell/Dunkel/System) funktioniert weiterhin
   - Kein Crash, kein leerer Slot, keine Fallback-Default-Farben (z.B. Schwarz auf Weiss)

---

## Referenz

- iOS Theme-Definitionen: `ios/StillMoment/Domain/Models/ColorTheme.swift`, `ios/StillMoment/Presentation/Theme/`
- Android Theme-Definitionen: `android/app/src/main/kotlin/com/stillmoment/.../theme/` (entsprechende Stelle)
- Vorgaenger-Tickets: shared-032 (Themes eingefuehrt), shared-033 (Paletten finalisiert), shared-034 (Theme-Vorschau), shared-035 (WCAG-Audit)
- Light/Dark/System-Auswahl: shared-041, shared-042 — diese bleibt unangetastet

---

## Hinweise

- Die Kerzenschein-Hex-Werte bleiben in diesem Ticket **unveraendert**. Verfeinerung der Palette erfolgt im Folge-Ticket, sobald das Design-Handover vorliegt.
- Persistierter `ColorTheme`-State (UserDefaults / DataStore): Beim Lesen alter Werte nicht versuchen zu migrieren — der Key ist obsolet und kann beim ersten Start einfach ignoriert/geloescht werden. Defensiv vorgehen, damit kein Crash entsteht, wenn der gespeicherte Wert nicht mehr existiert.
- Light/Dark/System-Auswahl ist eine andere Achse (`AppearanceMode`) und bleibt unangetastet.
- Auf den Folge-Refinement-Schritt referenzieren, sobald das entsprechende Ticket existiert.

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine separaten iOS/Android Subtasks mit Code
- Keine Dateilisten (Claude Code findet die Dateien)

Claude Code arbeitet shared-Tickets so ab:
1. Liest Ticket fuer Kontext
2. Implementiert iOS (oder Android) komplett
3. Portiert auf andere Plattform mit Referenz
-->
