# Ticket ios-039: Gong-Vorschau: Automatisch → Expliziter Preview-Button

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die Gong-Vorschau auf iOS spielt aktuell automatisch ab, sobald der Nutzer im Picker einen anderen Sound auswaehlt. Stattdessen soll ein expliziter "Vorhoeren"-Button erscheinen.

## Warum

Automatische Vorschau beim Scrollen durch 4 Sounds bedeutet: jede Beruehrung spielt einen Sound ab. Wer nur schnell eine andere Option auswaehlt ohne vorhoeren zu wollen, wird trotzdem mit Audio konfrontiert. In einer Meditations-App ist ungewolltes Audio besonders stoerend. Android hat explizite Preview-Buttons — das ist die bewusstere, nutzerkontrolliertere Loesung.

---

## Akzeptanzkriterien

### Feature
- [ ] Gong-Picker loest kein Audio mehr automatisch bei Auswahl aus
- [ ] Neben dem Gong-Picker gibt es einen "Vorhoeren"-Button (z.B. Play-Icon)
- [ ] Antippen des Buttons spielt den aktuell ausgewaehlten Gong ab (ggf. stoppt laufendes Preview)
- [ ] Gleiches Muster fuer den Interval-Gong-Sound-Picker
- [ ] Gleiches Muster fuer den Background-Sound-Picker (falls dort auch Auto-Preview)

### Tests
- [ ] `testPlayGongPreview_delegatesToAudioService()` weiterhin gruen
- [ ] `make test-unit` gruen

### Dokumentation
- [ ] Keine

---

## Manueller Test

1. Settings oeffnen, Gong-Sektion
2. Gong-Picker antippen, verschiedene Sounds auswaehlen
3. Erwartung: Kein Audio-Autoplay
4. "Vorhoeren"-Button antippen
5. Erwartung: Aktuell ausgewaehlter Sound spielt ab

---

## Referenz

- iOS: `SettingsView.swift` — Gong-Preview-Callback
- Android: `SettingsSheet.kt` — `onGongSoundPreview` Callback mit explizitem Button
