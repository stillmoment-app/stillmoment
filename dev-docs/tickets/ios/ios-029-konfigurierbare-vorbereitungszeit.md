# Ticket ios-029: Konfigurierbare Vorbereitungszeit

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 3-Feature

---

## Was

Die Vorbereitungszeit vor der Meditation (aktuell fix 15 Sekunden) soll konfigurierbar werden. User koennen die Vorbereitungszeit an/aus schalten und bei "an" zwischen 5s, 10s, 15s, 20s, 30s und 45s waehlen.

## Warum

Erfahrene Meditierende moechten direkt starten koennen, waehrend andere mehr Zeit zum Ankommen benoetigen. Die fixe 15-Sekunden-Vorbereitung passt nicht fuer alle User.

---

## Akzeptanzkriterien

### Feature

- [ ] Settings zeigt neue Section "Vorbereitungszeit" (oben, vor Sound-Settings)
- [ ] Toggle: An/Aus fuer Vorbereitungszeit
- [ ] Bei "An": Picker mit 5s, 10s, 15s, 20s, 30s, 45s
- [ ] Standard: An, 15 Sekunden (wie bisher)
- [ ] Bei "Aus": Timer startet ohne Countdown direkt
- [ ] Start-Gong spielt immer beim Beginn der Meditation (mit und ohne Vorbereitung)
- [ ] Einstellung wird persistent gespeichert
- [ ] Lokalisiert (DE + EN)

### Tests

- [ ] Unit Tests mit Mocks (effizient, kein Timer-Warten)
- [ ] Tests pruefen User-Verhalten, nicht technische Details (behavior-driven)
- [ ] Persistence-Test: Default-Werte bei Erstnutzung und Versions-Upgrade

### Dokumentation & Code

- [ ] GLOSSARY.md aktualisiert (preparationTimeEnabled, preparationTimeSeconds, TimerState.preparation)
- [ ] Refactoring "countdown" → "preparation" (Ubiquitous Language):
  - `MeditationTimer.countdownDuration` → `preparationTimeSeconds`
  - `MeditationTimer.countdownSeconds` → `remainingPreparationSeconds`
  - `TimerService.countdownDuration` → `preparationTimeSeconds`
  - `TimerDisplayState.countdownSeconds` → `remainingPreparationSeconds`
  - `TimerState.countdown` → `TimerState.preparation`
  - `TimerAction.countdownFinished` → `TimerAction.preparationFinished`

---

## Wording

| Kontext | Deutsch | Englisch |
|---------|---------|----------|
| Section-Titel | Vorbereitungszeit | Preparation time |
| Toggle An | An | On |
| Toggle Aus | Aus | Off |
| Beschreibung | Zeit zum Ankommen vor der Meditation | Time to settle in before meditation |
| Werte | 5/10/15/20/30/45 Sekunden | 5/10/15/20/30/45 seconds |

---

## Manueller Test

1. Settings oeffnen
2. "Vorbereitungszeit" Section sollte oben sichtbar sein
3. Toggle auf "Aus" stellen
4. Timer starten → Timer startet sofort ohne Countdown
5. Settings oeffnen, Toggle auf "An", 30s waehlen
6. Timer starten → 30 Sekunden Countdown, dann Meditation
7. App beenden und neu starten → Einstellung bleibt erhalten

---

## Referenz

- Bestehendes Pattern: Intervall-Gongs (Toggle + Picker)
  - `ios/StillMoment/Presentation/Views/Timer/SettingsView.swift`
- Settings-Model: `ios/StillMoment/Domain/Models/MeditationSettings.swift`
- Countdown-Logik: `ios/StillMoment/Domain/Models/MeditationTimer.swift` (countdownDuration)
- Glossar: `dev-docs/GLOSSARY.md`

---

## Hinweise

- `MeditationTimer` hat bereits `countdownDuration` als konfigurierbaren Parameter (wird zu `preparationTimeSeconds`)
- Neue Properties in `MeditationSettings`: `preparationTimeEnabled`, `preparationTimeSeconds`
- Ubiquitous Language: "preparation" durchgaengig im gesamten Code (Domain, Application, Infrastructure)
- Persistence-Default sicherstellen: Bestehende User ohne neue Keys → Standard-Verhalten (An, 15s)

---
