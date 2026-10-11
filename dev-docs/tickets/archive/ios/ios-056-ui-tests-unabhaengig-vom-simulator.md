---
id: ios-056
title: Tests nutzen eigenen Speicher statt der App-Daten
status: done
phase: 5-QA
priority: mittel
depends_on: [ios-055]
---

# Ticket ios-056: Tests nutzen eigenen Speicher statt der App-Daten

**Plan**: `dev-docs/tickets/plans/ios-056.md`

**Komplexitaet**: Überschaubar. Risiko: Der Test-Speicher gelangt versehentlich in den Store-Build, oder Screenshot-Tests mit Beispiel-Meditationen verlieren ihren Zustand.
**Abhaengigkeiten**: ios-055

---

## Was

Unit-Tests und UI-Tests arbeiten mit einem eigenen, leeren Speicher statt mit dem echten Datenbestand der App auf dem Simulator. Die Speicherorte (Basisverzeichnis, `UserDefaults`) werden nur noch in `AppDependencies.live()` festgelegt, die Dienste haben dafür keine Defaults mehr. Im Testlauf startet die App mit dem Test-Speicher. Der Schalter dafür existiert nur im Debug-Build.

## Warum

Beide Testarten benutzen heute den echten Speicher der App:

- **UI-Tests sind rot, obwohl die App richtig funktioniert.** Vier Bibliotheks-Tests erwarten eine leere Bibliothek, sorgen aber nicht dafür. Auf dem Simulator „iPhone 17“, den `make test-ui` automatisch wählt, liegt ein alter Eintrag („Achtsame Übung“ von „Melissa Gein“). Ein Testergebnis, das vom Zustand des Geräts abhängt, ist keine verlässliche Qualitätsprüfung.
- **Unit-Tests hinterlassen Reste.** Nach einem Lauf am 08.10.2026 lagen 96 leere Audio-Dateien im echten Meditations-Ordner. Der alte Bibliothekseintrag stammt sehr wahrscheinlich ebenfalls von einem Unit-Test (13.09.2026).

Ein eigener Test-Speicher behebt beides an einer Stelle. Er schont außerdem die Meditationen, die man von Hand auf dem Simulator angelegt hat.

---

## Akzeptanzkriterien

- [x] `make test-ui` ist grün, auch wenn auf dem Simulator Meditationen gespeichert sind. Diese Meditationen sind danach unverändert.
- [x] Nach `make test-unit-agent` liegen im echten App-Speicher keine neuen Dateien und keine neuen Einträge in den Einstellungen.
- [x] Im Release-Build lässt sich der Test-Speicher nicht einschalten.
- [x] Screenshot-Tests mit Beispiel-Meditationen verhalten sich wie bisher.
- [x] `ios/CLAUDE.md`: eine Zeile dazu, wie Tests ihren Speicher bekommen.

---

## Manueller Test

1. Auf dem Simulator „iPhone 17“ eine Meditation importieren, sodass die Bibliothek nicht leer ist.
2. `make test-unit-agent` und danach `make test-ui` ausführen.
3. Erwartung: Alles grün. Die App zeigt beim normalen Start dieselbe Bibliothek wie vorher, im Meditations-Ordner liegen keine neuen Dateien.

---

## Nachweise

Alle Läufe am 2026-10-11 auf „iPhone 17“, die Dev-App hatte dabei einen Eintrag in der Bibliothek.

- **UI-Tests (AK-1):** Gegenprobe ohne `-UseTestStorage` in `LibraryFlowUITests`: die vier Bibliotheks-Tests rot („Executed 4 tests, with 4 failures“). Mit dem Argument grün („Executed 4 tests, with 0 failures“). Danach `make test-ui`: „Executed 31 tests, with 16 tests skipped and 0 failures“, Bibliothek der Dev-App unverändert.
- **Unit-Tests (AK-2):** Vor und nach `make test-unit-agent` (1500 Tests grün) waren die Dateiliste in Application Support (763 Dateien, Größe und Änderungszeit) und die Einstellungen der Dev-App identisch. Neu sind nur die Einstellungsdateien des Test-Speichers (`StillMomentTestStorage`, `StillMomentTests.*`), einmalig mit festem Namen.
- **Screenshots (AK-4):** `make screenshots` Exit 0, je „Executed 16 tests, with 0 failures“ für de-DE und en-GB, Bilder inhaltlich identisch mit main. Leere Bibliothek separat per `make screenshot-single` geprüft.
- **Release-Schalter (AK-3):** `make build-release`, danach `strings -a` auf `Release-iphoneos/StillMoment.app/StillMoment`: `-UseTestStorage`, `StillMomentTestStorage` und `XCTestCase` kommen nicht vor. Gegenprobe: Debug-Build enthält `-UseTestStorage`, das Release-Binary enthält `-DisablePreparation`.

---

## Hinweise

- Recherche und Quellen: [ios-ui-test-isolation.md](../../../concepts/ios-ui-test-isolation.md). Empfehlung, kein Lösungszwang:
  - Feste Pfade auf `applicationSupportDirectory` heute in `GuidedMeditationService.swift:138`, `CustomAudioRepository.swift:149`, `WaveformCacheService.swift:77`. Basisverzeichnis übergebbar machen.
  - Defaults wie `UserDefaults = .standard` und `FileManager = .default` entfernen und die Speicherorte ausdrücklich in `live()` übergeben. Dann muss jeder Test schon beim Kompilieren einen Speicherort wählen, und `live()` lässt sich mit temporären Speicherorten testen.
  - UI-Tests: Launch-Argument in `setUp` (WWDC25-344), an genau einer Stelle im App-Einstieg ausgewertet. Erst leeren, dann bei Bedarf seeden (nicht „seeden nur wenn leer“ wie heute im `TestFixtureSeeder`).
  - Unit-Tests: Die Host-App erkennt den Testlauf (`NSClassFromString("XCTestCase")` oder Umgebungsvariable im Scheme, WWDC18-417) und startet ohne echte Dienste, Migrationen und Seeding.
  - Heutiger Screenshot-Mechanismus: `-EmptyLibrary` in `ios/StillMoment/StillMomentApp.swift` unter `#if SCREENSHOTS_BUILD`.
- Betroffene UI-Tests: `ios/StillMomentUITests/LibraryFlowUITests.swift` (`testLibraryHeaderHiddenInEmptyState`, `testGuideSheetShowsImportBanners`, `testFilesBannerPushesHowtoAndBackReturns`, `testBrowserBannerPushesHowtoAndBackReturns`).
- Nach der Umsetzung den alten Eintrag einmalig vom Simulator entfernen (ID `971897DA-48C6-495C-B031-3316A97FAA5D`). Der Test-Speicher verhindert neue Reste, löscht aber keine alten.
- **Nebenbefund Screenshots (unverifiziert):** `ios/fastlane/Snapfile:42` setzt `reinstall_app(true)` ohne `app_identifier`, `ios/fastlane/Appfile:2` nennt `com.stillmoment.StillMoment`. Vermutlich deinstalliert `make screenshots` die normale App statt `com.stillmoment.StillMoment.screenshots`. Vor dem Abhaken des Screenshot-AK im Fastlane-Log (`xcrun simctl uninstall …`) prüfen.
- ios-057 (Unit-Test-Reste) ist in dieses Ticket eingegangen.
