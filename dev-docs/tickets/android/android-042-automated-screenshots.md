# Ticket android-042: Vollautomatische Screenshots

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Automatische Screenshot-Generierung fuer Play Store. Wie bei iOS (make screenshots)
sollen Screenshots automatisch generiert werden koennen.

## Warum

- Konsistente Screenshots bei jedem Release
- Zeiteinsparung gegenueber manueller Erstellung
- Beide Sprachen (DE/EN) automatisch generiert
- Paritaet mit iOS-Workflow

---

## Akzeptanzkriterien

- [x] 5 Screenshots pro Sprache generiert (10 total)
- [x] `cd android && make screenshots` funktioniert (via Fastlane Screengrab)
- [x] Screenshots in docs/images/screenshots/ abgelegt
- [x] Namenskonvention wie iOS: timer-main.png, timer-main-de.png, etc.
- [x] Dokumentation in dev-docs/guides/screenshots-android.md
- [x] Test-Fixtures fuer konsistente Library-Inhalte (TestFixtureSeeder)

---

## Manueller Test

1. `cd android && make screenshots`
2. Pruefe docs/images/screenshots/
3. Erwartung: 10 Screenshots (5 EN + 5 DE) vorhanden

---

## Referenz

- iOS-Implementierung: `dev-docs/SCREENSHOTS.md`
- iOS-Screenshots Ticket: `ios-025`

---

## Hinweise

- iOS nutzt Fastlane Snapshot + XCUITest
- Android nutzt Fastlane Screengrab (Emulator-basiert, authentische Screenshots)
- Library-Inhalte sind mit iOS TestFixtureSeeder konsistent (5 Meditationen)

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine Dateilisten (Claude Code findet die Dateien)
- Keine Architektur-Diagramme (steht in CLAUDE.md)
- Keine Test-Befehle (steht in CLAUDE.md)

Claude Code hat Zugriff auf:
- CLAUDE.md (Architektur, Commands, Patterns)
- Bestehenden Code als Referenz
- iOS-Implementierung fuer Android-Ports
-->
