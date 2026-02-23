# Ticket shared-061: Einstellungen-Tab und 3-Tab-Navigation

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~3 | Android ~3
**Phase**: 2-Architektur
**Ursprung**: shared-051 (aufgeteilt)

---

## Was

Navigation von 2 auf 3 Tabs erweitern (Timer, Bibliothek, Einstellungen). Globale App-Einstellungen (Theme, Erscheinungsbild, Info) erhalten einen eigenen Tab statt im Timer-Settings-Sheet zu leben.

## Warum

Das Timer-Settings-Sheet ist aktuell ueberladen mit Timer-Konfiguration UND App-Einstellungen. Die Trennung schafft Platz fuer das kommende Praxis-System (shared-062 ff.) und gibt globalen Settings einen festen, intuitiven Ort.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Tab-Bar zeigt 3 Tabs: Timer, Bibliothek, Einstellungen
- [x] Icons: Timer und Bibliothek bleiben wie bisher. Einstellungen-Tab: `gearshape` (iOS) / `Icons.Outlined.Settings` (Android) — bewusst unterschiedlich vom Inline-Settings-Icon (`slider.horizontal.3` / `Icons.Filled.Tune`), um App-Einstellungen von Timer-Tuning zu unterscheiden
- [x] Einstellungen-Screen mit Sektion "Erscheinungsbild": Theme-Auswahl und Appearance-Mode (System/Hell/Dunkel)
- [x] Einstellungen-Screen mit Sektion "Info & Rechtliches": Sound Attributions, Datenschutz, App-Version
- [x] Theme/Appearance aus Timer-Settings-Sheet entfernt (lebt nur noch im Einstellungen-Tab)
- [x] Tab-Auswahl wird persistiert (letzter Tab bei Neustart wiederhergestellt)
- [x] Timer-Settings-Sheet funktioniert weiterhin fuer Timer-spezifische Settings (Gong, Background, etc.)
- [x] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android (iOS done, Android pending)

### Tests
- [x] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. App oeffnen → 3 Tabs sichtbar: Timer, Bibliothek, Einstellungen
2. Einstellungen-Tab antippen → Theme-Auswahl und Info-Bereich sichtbar
3. Theme aendern → wirkt sofort app-weit
4. Appearance-Mode aendern → wirkt sofort
5. Timer-Tab → Settings oeffnen → kein Theme/Appearance mehr, nur Timer-Settings
6. App beenden und neu starten → letzter Tab wird wiederhergestellt
7. Sound Attributions, Datenschutz antippen → oeffnet jeweiligen Screen/Link
8. App-Version wird korrekt angezeigt

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Tab-Bar Position | Bottom (UITabBar) | Bottom (NavigationBar) |
| Einstellungen-Layout | Grouped List / Form | Scrollable Column mit Cards |

---

## Referenz

- UI-Prototype: `dev-docs/ui-prototype.html` (SettingsScreen-Komponente)
- iOS: `ios/StillMoment/Presentation/` (bestehende SettingsView fuer Theme-Migration)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/` (bestehende SettingsSheet)

---

## Hinweise

- "Daten & Sync" (iCloud Backup) aus dem Prototype ist ein Platzhalter fuer die Zukunft — NICHT Teil dieses Tickets
- Sound Attributions und Datenschutz koennen zunaechst als statische Screens/Links umgesetzt werden
- Die General-Settings-Komponente (Theme/Appearance) existiert bereits auf beiden Plattformen — sie muss nur in den neuen Tab verschoben werden
