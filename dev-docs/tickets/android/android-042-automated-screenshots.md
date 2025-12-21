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

- [x] 4 Screenshots pro Sprache generiert (8 total)
- [x] Gradle Task `./gradlew screenshots` funktioniert
- [x] Screenshots in docs/images/screenshots/android/ abgelegt
- [x] Namenskonvention wie iOS: timer-main.png, timer-main-de.png, etc.
- [x] Dokumentation in dev-docs/ANDROID_SCREENSHOTS.md
- [x] Test-Fixtures fuer konsistente Library-Inhalte

---

## Manueller Test

1. `cd android && ./gradlew screenshots`
2. Pruefe docs/images/screenshots/android/
3. Erwartung: 8 Screenshots (4 EN + 4 DE) vorhanden

---

## Referenz

- iOS-Implementierung: `dev-docs/SCREENSHOTS.md`
- iOS-Screenshots Ticket: `ios-025`

---

## Hinweise

- iOS nutzt Fastlane Snapshot + XCUITest
- Fuer Android bieten sich JVM-basierte Loesungen an (schneller, kein Emulator noetig)
- Library-Inhalte sollten mit iOS TestFixtureSeeder konsistent sein (5 Meditationen)

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
