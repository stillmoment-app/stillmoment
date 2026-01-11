# Ticket shared-023: Vorbereitungszeit fuer gefuehrte Meditationen

**Status**: [ ] TODO
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
Player-Controls Layout:

    [<<<]    [▶]    [>>>]
            [---]

[---] = Vorbereitungszeit-Label (Tap oeffnet Picker)
```

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Label unter Play-Button zeigt aktuelle Einstellung (z.B. "15s" oder "---" wenn aus)
- [ ] Tap auf Label oeffnet Picker mit Optionen: Aus, 5s, 10s, 15s, 20s, 30s, 45s
- [ ] Bei "Aus": MP3 startet sofort nach Play
- [ ] Einstellung ist persistent (bleibt fuer alle MP3s erhalten)
- [ ] Countdown zeigt Ring + Zahl (wie Timer, nur kleiner im Player)
- [ ] Nach Countdown: Stiller Uebergang direkt zur MP3 (kein Gong)
- [ ] Default: Aus
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (State-Machine, Persistence)
- [ ] Unit Tests Android (State-Machine, Persistence)

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md (falls neue Domain-Begriffe)

---

## Manueller Test

1. Player oeffnen (beliebige Meditation)
2. Label "---" unter Play-Button antippen
3. Picker erscheint mit Optionen: Aus, 5s, 10s, 15s, 20s, 30s, 45s
4. "15s" auswaehlen
5. Label zeigt jetzt "15s"
6. Play druecken
7. Countdown erscheint (Ring fuellt sich, Zahl zaehlt runter)
8. Nach 15s: MP3 startet automatisch (ohne Ton-Signal)
9. App schliessen, neu oeffnen, andere Meditation waehlen
10. Erwartung: Label zeigt weiterhin "15s"

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/player/`
- Timer-Countdown als Inspiration: `ios/StillMoment/Presentation/Views/Timer/`

---

## Hinweise

- Kein separates Settings-Menue noetig - Label unter Play-Button ist die Einstellung
- Unabhaengig von Timer-Vorbereitungszeit (separate Einstellung)
- Countdown laeuft durch, kein Abbrechen moeglich
- Standard-Picker verwenden (iOS: Wheel/Menu, Android: DropdownMenu)
