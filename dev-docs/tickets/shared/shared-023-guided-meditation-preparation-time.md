# Ticket shared-023: Vorbereitungszeit fuer gefuehrte Meditationen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~M | Android ~M
**Phase**: 3-Feature

---

## Was

Gefuehrte Meditationen erhalten eine optionale Vorbereitungszeit (0-45s in 5s-Schritten),
die dem Benutzer Zeit gibt, das Handy beiseite zu legen und eine Haltung einzunehmen,
bevor die MP3 startet.

## Warum

Beim Starten einer gefuehrten Meditation muss man schnell das Handy weglegen und verpasst
oft die ersten Sekunden. Die Vorbereitungszeit ermoeglicht einen entspannten Start.

---

## UI-Konzept

```
Library View (Toolbar):

[+]    Gefuehrte Meditationen    [⚙]

Settings-Sheet (bei Tap auf ⚙):
┌────────────────────────────┐
│        Einstellungen       │
│                            │
│ Vorbereitungszeit    [On]  │
│ Dauer              [15s ▼] │
│                            │
│               [Fertig]     │
└────────────────────────────┘

Player View (unveraendert):

    [<<<]    [▶]    [>>>]

    (Countdown-Ring erscheint bei aktivierter Vorbereitungszeit)
```

**Begruendung fuer Settings in Library statt Player:**
- Player ist bereits ein Sheet - verschachtelte Sheets sind in iOS problematisch
- Konsistent mit Timer-Pattern (Settings-Button oeffnet Sheet)
- Einstellung gilt global fuer alle Meditationen

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | - |
| Android   | [x]    | - |

Legende: [x] fertig, [~] in Bearbeitung, [ ] offen

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Settings-Button (⚙) in Library-Toolbar oeffnet Settings-Sheet (iOS + Android)
- [x] Settings-Sheet zeigt Toggle fuer Vorbereitungszeit + Picker fuer Dauer (iOS + Android)
- [x] Picker-Optionen: 5s, 10s, 15s, 20s, 30s, 45s (nur sichtbar wenn Toggle an) (iOS + Android)
- [x] Bei deaktiviertem Toggle: MP3 startet sofort nach Play (iOS + Android)
- [x] Einstellung ist persistent (bleibt fuer alle MP3s erhalten) (iOS + Android)
- [x] Countdown zeigt Ring + Zahl (wie Timer, nur kleiner im Player) (iOS + Android)
- [x] Nach Countdown: Stiller Uebergang direkt zur MP3 (kein Gong) (iOS + Android)
- [x] Default: Aus (Toggle deaktiviert) (iOS + Android)
- [x] Lokalisiert (DE + EN) (iOS + Android)
- [x] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Unit Tests iOS (State-Machine, Persistence)
- [x] Unit Tests Android (State-Machine, Persistence)

### Dokumentation
- [x] CHANGELOG.md
- [x] GLOSSARY.md (iOS)

---

## Manueller Test

1. Library oeffnen (Gefuehrte Meditationen Tab)
2. Settings-Button (⚙) in Toolbar antippen
3. Settings-Sheet oeffnet sich
4. Toggle "Vorbereitungszeit" aktivieren
5. Picker erscheint, "15s" auswaehlen
6. "Fertig" antippen, Sheet schliesst
7. Meditation auswaehlen, Player oeffnet sich
8. Play druecken
9. Countdown erscheint (Ring fuellt sich, Zahl zaehlt runter)
10. Nach 15s: MP3 startet automatisch (ohne Ton-Signal)
11. App schliessen, neu oeffnen, andere Meditation waehlen
12. Erwartung: Settings zeigen weiterhin Toggle an + 15s

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/`
- Timer-Countdown als Inspiration: `ios/StillMoment/Presentation/Views/Timer/`

---

## Hinweise

- Settings-Sheet in Library (nicht im Player, da Player bereits ein Sheet ist)
- Konsistent mit Timer-Pattern: Settings-Button oeffnet Sheet mit Form
- Unabhaengig von Timer-Vorbereitungszeit (separate Einstellung)
- Countdown laeuft durch, kein Abbrechen moeglich
- iOS: Toggle + `.menu`-Style Picker | Android: Switch + DropdownMenu

---

## Geklaerte Anforderungen

- **Settings-Position**: Library View (nicht Player), da Player bereits ein Sheet ist und verschachtelte Sheets in iOS problematisch sind.
- **UI-Pattern**: Settings-Button in Toolbar oeffnet Sheet mit Form (konsistent mit Timer).
- **Settings-Icon**: `slider.horizontal.3` (SF Symbol) - identisch mit Timer.
- **Toggle + Picker**: Vorbereitungszeit ist ein Toggle. Wenn aktiviert, erscheint Picker fuer Dauer.
- **Countdown ersetzt Play-Button**: Waehrend des Countdowns wird der Play-Button durch den Countdown-Ring ersetzt. Kein Stop/Abbruch moeglich.
- **Skip-Buttons ausgeblendet**: Die [<<<] und [>>>] Buttons werden waehrend des Countdowns ebenfalls ausgeblendet.
- **Hintergrund-Verhalten**: Countdown laeuft im Hintergrund weiter und startet die MP3 automatisch.
- **iOS Picker-Style**: `.menu` (kompakter Dropdown, nicht Wheel-Picker)
