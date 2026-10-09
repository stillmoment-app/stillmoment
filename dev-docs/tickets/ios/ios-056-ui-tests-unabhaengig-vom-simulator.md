---
id: ios-056
title: UI-Tests unabhängig vom Zustand des Simulators
status: todo
phase: 5-QA
priority: mittel
depends_on: [ios-055]
---

# Ticket ios-056: UI-Tests unabhängig vom Zustand des Simulators

**Komplexitaet**: Überschaubar. Das Risiko liegt darin, dass ein Test-Schalter für den Ausgangszustand versehentlich in den Store-Build gelangt oder bestehende UI-Tests, die mit Beispiel-Meditationen arbeiten, ihren Zustand verlieren. Beide Fälle müssen bewusst geprüft werden.
**Abhaengigkeiten**: ios-055

---

## Was

Die UI-Tests stellen den Zustand der Bibliothek, den sie brauchen, beim Start selbst her. Ein Test, der eine leere Bibliothek erwartet, bekommt eine leere Bibliothek, egal was vorher auf dem Simulator gespeichert war. Damit laufen die UI-Tests auf jedem Simulator gleich.

## Warum

Vier UI-Tests der Bibliothek gehen heute davon aus, dass die Bibliothek leer ist, sorgen aber nicht dafür. Auf dem Simulator „iPhone 17“, den `make test-ui` automatisch wählt, liegt noch ein alter Eintrag („Achtsame Übung“ von „Melissa Gein“). Deshalb sind diese Tests dort rot, obwohl die App richtig funktioniert. Ein Testergebnis, das vom zufälligen Zustand des Geräts abhängt, ist als Qualitätsprüfung nicht verlässlich. Rote Tests ohne echten Fehler verleiten außerdem dazu, echte Fehler zu übersehen.

---

## Akzeptanzkriterien

### Feature
- [ ] Jeder UI-Test, der eine leere Bibliothek voraussetzt, startet die App mit einer leeren Bibliothek, auch wenn auf dem Simulator vorher Meditationen gespeichert waren.
- [ ] Die vier betroffenen Tests (`testLibraryHeaderHiddenInEmptyState`, `testGuideSheetShowsImportBanners`, `testFilesBannerPushesHowtoAndBackReturns`, `testBrowserBannerPushesHowtoAndBackReturns`) sind auf einem Simulator mit vorhandenem Bibliothekseintrag grün.
- [ ] Die gespeicherten Meditationen eines echten Nutzers bleiben unberührt: Im Release-Build kann kein Startparameter die Bibliothek leeren.
- [ ] UI-Tests und Screenshot-Tests, die mit Beispiel-Meditationen arbeiten, verhalten sich wie bisher.

### Tests
- [ ] `make test-ui` ist auf dem automatisch gewählten Simulator „iPhone 17“ grün, ohne dass der Simulator vorher zurückgesetzt wird.
- [ ] `make test-ui` ist auch auf einem frisch zurückgesetzten Simulator grün.

### Dokumentation
- [ ] `ios/CLAUDE.md` bzw. die UI-Test-Doku: kurz festhalten, wie ein UI-Test seinen Bibliotheks-Ausgangszustand festlegt.

---

## Manueller Test

1. Auf dem Simulator „iPhone 17“ die App starten und eine Meditation importieren, sodass die Bibliothek nicht leer ist.
2. `make test-ui` ausführen.
3. Erwartung: Alle UI-Tests sind grün, auch die vier Tests mit leerer Bibliothek.

---

## Referenz

- Betroffene Tests: `ios/StillMomentUITests/LibraryFlowUITests.swift`
- Heutiger Mechanismus für den Screenshot-Lauf: `-EmptyLibrary` in `ios/StillMoment/StillMomentApp.swift`, nur aktiv unter `#if SCREENSHOTS_BUILD`
- Simulator-Auswahl: `ios/Makefile` (`DEVICE ?= iPhone 17`, erster passender Simulator)

---

## Hinweise

- Betroffener Simulator beim Befund: iPhone 17, ID `971897DA-48C6-495C-B031-3316A97FAA5D`.
- Der alte Eintrag stammt sehr wahrscheinlich von einem Unit-Test am 13.09.2026, der über einen damals noch per Default-Argument erzeugten Dienst in den echten Datenbestand geschrieben hat. Die Ursache solcher Reste behandelt ios-057. Dieses Ticket macht die UI-Tests unabhängig davon robust.
- ios-055 erleichtert die Umsetzung: Da Dienste dann nur im App-Einstieg entstehen, gibt es genau eine Stelle, an der der Ausgangszustand für einen Testlauf festgelegt werden kann.
- Lösung bewusst offen. Naheliegend ist, den vorhandenen Screenshot-Mechanismus auch für den UI-Test-Lauf verfügbar zu machen. Dabei gilt das AK zum Release-Build.
- **Empfehlung aus der Recherche** ([ios-ui-test-isolation.md](../../concepts/ios-ui-test-isolation.md)), kein Lösungszwang:
  - Jeder UI-Test legt seinen Ausgangszustand in `setUp` per Launch-Argument fest, wie Apple es in WWDC25-344 zeigt (`app.launchArguments = ["ClearFavoritesOnLaunch"]`).
  - Das Argument wird an genau einer Stelle im App-Einstieg ausgewertet (vor bzw. als Parameter für `AppDependencies.live()`), nur im Debug-Build kompiliert.
  - Reihenfolge: erst leeren, dann bei Bedarf seeden. Nicht „seeden nur wenn leer“ wie heute im `TestFixtureSeeder`.
  - Idealerweise eigener Test-Speicher (eigene `UserDefaults`-Suite und eigenes Verzeichnis), damit `make test-ui` die manuell angelegten Meditationen auf dem Simulator nicht löscht. Dafür braucht es dieselbe Vorarbeit wie ios-057 (Basisverzeichnis übergebbar).
  - Simulator zurücksetzen oder App deinstallieren bleibt höchstens ein optionales Sicherheitsnetz für CI, nicht die Lösung.
- **Nebenbefund Screenshots (unverifiziert):** `ios/fastlane/Snapfile:42` setzt `reinstall_app(true)` ohne `app_identifier`, `ios/fastlane/Appfile:2` nennt `com.stillmoment.StillMoment`. Vermutlich deinstalliert `make screenshots` deshalb die normale App statt `com.stillmoment.StillMoment.screenshots`. Im Fastlane-Log (`xcrun simctl uninstall … <bundle id>`) prüfen, bevor das AK „Screenshot-Tests verhalten sich wie bisher“ abgehakt wird.
