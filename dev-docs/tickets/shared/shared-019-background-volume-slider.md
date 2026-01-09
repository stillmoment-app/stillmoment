# Ticket shared-019: Lautstaerkeregler fuer Hintergrundsounds

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 4-Polish

---

## Was

Benutzer sollen die Lautstaerke von Hintergrundsounds ueber einen Slider in den Settings anpassen koennen.

## Warum

Manche Sounds werden als zu laut empfunden (z.B. Waldatmosphaere bei 15%). Individuelle Vorlieben erfordern eine einstellbare Lautstaerke statt fest konfigurierter Werte.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Lautstaerke-Slider erscheint unterhalb der Sound-Auswahl
- [x] Slider nur sichtbar wenn ein Sound (nicht "Silence") gewaehlt ist
- [x] Slider-Bereich: 0% bis 100% (entspricht 0.0 - 1.0)
- [x] Standard-Wert: Aus Sound-Konfiguration (aktuell 15%)
- [x] Lautstaerke-Einstellung wird in UserDefaults/Preferences gespeichert
- [x] Gespeicherte Lautstaerke wird beim Timer-Start verwendet
- [x] Preview in Settings spielt mit aktueller Slider-Lautstaerke
- [x] Kein visuelles Label (Slider mit Speaker-Icons ist selbsterklaerend)
- [x] Accessibility-Labels lokalisiert (DE/EN) fuer VoiceOver/TalkBack
- [x] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Unit Tests iOS (Settings-Persistierung, Audio-Lautstaerke)
- [x] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md (bei user-sichtbaren Aenderungen)

---

## Manueller Test

1. Settings oeffnen, Sound "Waldatmosphaere" waehlen
2. Slider erscheint, auf ~50% stellen
3. Preview-Sound spielt mit reduzierter Lautstaerke
4. Timer starten - Hintergrundton spielt mit 50% Lautstaerke
5. "Silence" waehlen - Slider verschwindet

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Timer/SettingsView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt`

---

## Hinweise

- iOS: `AudioService.playBackgroundPreview(soundId:volume:)` akzeptiert bereits einen volume-Parameter
- iOS: `sounds.json` enthaelt Default-Volume pro Sound (als Fallback)
- Slider sollte beim Sound-Wechsel auf den Default-Wert des neuen Sounds zurueckgesetzt werden
