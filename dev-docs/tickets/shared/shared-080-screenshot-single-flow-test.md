# Ticket shared-080: Screenshot Single-Flow Test

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS M (~2-3h) | Android M (~2-3h)
**Abhaengigkeiten**: shared-079 (Screenshot-Pipeline Hardening)
**Phase**: 3-Implementation

---

## Was

Die 5 einzelnen Screenshot-Tests auf beiden Plattformen zu jeweils einem einzigen Flow-Test zusammenfuehren. Statt 5 App-Launches pro Sprache nur noch 1.

## Warum

Aktuell startet jeder der 5 Tests die App komplett neu. Bei 2 Sprachen = 10 App-Launches pro Plattform, inkl. Fixture-Seeding, View-Aufbau und Animation-Settle.

Ein Single-Flow-Test reduziert das auf 2 Launches (1 pro Sprache) — ca. 3x schneller. Das ist die Basis fuer shared-040 wo der Screenshot-Prozess iterativ ausgefuehrt wird.

---

## Plattform-Status

| Plattform | Status |
|-----------|--------|
| iOS       | [ ]    |
| Android   | [ ]    |

---

## Akzeptanzkriterien

### iOS — Test-Umbau

- [ ] Ein einziger Test `testAllScreenshots()` der durch alle Screens navigiert
- [ ] Reihenfolge: Timer idle -> Timer running -> Stop -> Library -> Player -> Back -> Settings
- [ ] Jeder `snapshot()` Call mit `timeWaitingForIdle: 0`
- [ ] Kein `Thread.sleep` — nur explizite `waitForExistence` Conditions
- [ ] Alte 5 Test-Methoden entfernt

### Android — Test-Umbau

- [ ] Ein einziger Test `screenshotAllScreens()` der durch alle Screens navigiert
- [ ] Reihenfolge: Timer idle -> Timer running -> Stop -> Library -> Player -> Back -> Settings
- [ ] Kein `Thread.sleep` — nur `waitUntil` / `waitForIdle` Conditions
- [ ] `@Before`/`@After` starten und beenden die Activity nur einmal
- [ ] Alte 5 Test-Methoden entfernt

### Navigation-Robustheit (beide Plattformen)

- [ ] Nach Timer-Stop zurueck in idle State bevor Library-Navigation
- [ ] Player dismiss bevor Settings-Navigation
- [ ] Jeder Navigationsschritt hat ein explizites Wait auf das Ziel-Element

### Performance

- [ ] iOS: Gesamtlaufzeit `make screenshots` unter 3 Minuten (vorher ~5-10 Min)
- [ ] Android: Gesamtlaufzeit `make screenshots` deutlich reduziert gegenueber aktuell

### Validierung

- [ ] iOS: Alle 10 Screenshots werden erzeugt (5 x 2 Sprachen)
- [ ] Android: Alle 10 Screenshots werden erzeugt (5 x 2 Sprachen)
- [ ] Screenshots sind visuell gleichwertig zu den bisherigen

---

## Manueller Test

### iOS
1. `cd ios && HEADLESS=false make screenshots` (mit sichtbarem Simulator)
2. Beobachten: App startet nur 1x pro Sprache, navigiert durch alle Screens
3. Pruefen: 10 Screenshots

### Android
1. `cd android && make screenshots`
2. Beobachten: Activity startet nur 1x pro Locale
3. Pruefen: 10 Screenshots

---

## Hinweise

- **Risiko:** Ein Fehler in der Navigation killt alle nachfolgenden Screenshots. Mitigation: `number_of_retries(2)` (iOS) aus shared-079 faengt das ab. Android hat kein Retry in Screengrab — ggf. Makefile-Wrapper.
- **iOS:** Timer muss nach Screenshot 2 gestoppt werden bevor Library-Navigation moeglich ist (Tab-Wechsel ist waehrend Timer gesperrt)
- **iOS:** `snapshot()` intern: Fastlane erkennt Screenshots ueber den Namen-Parameter, nicht ueber Test-Methoden. Ein Flow-Test mit 5 `snapshot()` Calls funktioniert.
- **Android:** `Screengrab.screenshot()` funktioniert analog — Name-basiert, nicht Test-Methoden-basiert.
- **Android:** `@FixMethodOrder` wird obsolet da nur noch 1 Test. `@Before`/`@After` bleiben fuer Setup/Teardown.
- Bestehende Helper-Methoden koennen auf beiden Plattformen wiederverwendet werden
