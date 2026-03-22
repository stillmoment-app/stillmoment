# Ticket shared-079: Screenshot-Pipeline Hardening

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS S (~1h) | Android S (~1h)
**Abhaengigkeiten**: -
**Phase**: 3-Implementation

---

## Was

Fastlane Screenshot-Konfiguration auf beiden Plattformen stabilisieren. Kein Umbau der Tests, nur Konfiguration und stabile Element-Identifier.

## Warum

Die Screenshot-Pipelines auf beiden Plattformen sind fragil:
- Kein Retry bei flaky Tests — ein Fehler killt den ganzen Run
- Kein sauberer App-State garantiert — Leftover-Daten vom letzten Run koennen Tests brechen
- Element-Suche per lokalisiertem Text statt stabiler Identifier — bricht bei Textaenderungen
- iOS: "Slide to Type"-Popup kann Screenshots ruinieren

Diese Probleme treten sporadisch auf und machen den Prozess unzuverlaessig.

---

## Plattform-Status

| Plattform | Status |
|-----------|--------|
| iOS       | [ ]    |
| Android   | [ ]    |

---

## Akzeptanzkriterien

### iOS — Snapfile

- [ ] `number_of_retries(2)` — automatischer Retry bei Test-Fehler
- [ ] `reinstall_app(true)` — saubere App-Installation pro Sprach-Run
- [ ] `disable_slide_to_type(true)` — kein Keyboard-Popup

### iOS — Accessibility Identifier

- [ ] Library-Tab hat einen stabilen `.accessibilityIdentifier("tab.library")` in der SwiftUI TabView
- [ ] `ScreenshotTests.swift` nutzt den Identifier statt lokalisierte Labels (`"Meditations"` / `"Meditationen"`)

### Android — Screengrabfile

- [ ] `reinstall_app(true)` — saubere App-Installation pro Sprach-Run (aktuell `false` wegen frueherer Probleme — erneut testen)
- [ ] `exit_on_test_failure(false)` — bei Fehler trotzdem restliche Screenshots erzeugen

### Android — Stabile Identifier

- [ ] Navigation per `testTag` statt lokalisierter `contentDescription` wo moeglich
- [ ] `localizedContentDescription`-Helper bleibt als Fallback wo `testTag` nicht greift

### Validierung (beide Plattformen)

- [ ] `cd ios && make screenshots` laeuft fehlerfrei durch (beide Sprachen)
- [ ] `cd android && make screenshots` laeuft fehlerfrei durch (beide Sprachen)
- [ ] Screenshots sind identisch zu vorher (kein visueller Unterschied)

---

## Manueller Test

### iOS
1. `cd ios && make screenshots`
2. Pruefen: 10 Screenshots (5 x 2 Sprachen)
3. Visueller Vergleich — keine Regression

### Android
1. `cd android && make screenshots`
2. Pruefen: 10 Screenshots (5 x 2 Sprachen)
3. Visueller Vergleich — keine Regression

---

## Hinweise

- **iOS:** `erase_simulator` bewusst NICHT gesetzt — Overkill, `reinstall_app` reicht
- **iOS:** `ios_version` in Snapfile pruefen — muss zum installierten Simulator passen
- **Android:** `reinstall_app` war auf `false` gesetzt wegen frueherer Probleme mit Test-APK-Erkennung. Erneut testen ob das inzwischen funktioniert — falls nicht, `false` belassen und dokumentieren warum.
- **Android:** Screengrab hat kein `number_of_retries` — Retry-Logik muesste ggf. im Makefile/Fastfile implementiert werden
