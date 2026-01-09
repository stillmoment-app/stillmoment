# Ticket shared-020: Lautstaerkeregler fuer Gong-Sounds

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 4-Polish

---

## Was

Benutzer sollen die Lautstaerke von Gong-Sounds (Start-Gong, Ende-Gong, Intervall-Gong) ueber einen Slider in den Settings anpassen koennen.

## Warum

Manche Benutzer empfinden die Gong-Sounds als zu laut oder zu leise. Individuelle Vorlieben erfordern eine einstellbare Lautstaerke statt fest konfigurierter Werte.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Gong-Lautstaerke-Slider erscheint als eigene Zeile mit Label (immer sichtbar)
- [x] Slider-Bereich: 0% bis 100% (entspricht 0.0 - 1.0)
- [x] Standard-Wert: 100% (volle Lautstaerke)
- [x] Eine globale Einstellung gilt fuer alle Gong-Typen (Start, Ende, Intervall)
- [x] Lautstaerke bleibt bei Sound-Wechsel erhalten
- [x] Lautstaerke-Einstellung wird in UserDefaults/Preferences gespeichert
- [x] Erstnutzung: Default-Wert (100%) wird verwendet wenn kein gespeicherter Wert existiert
- [x] Update bestehender User: Fallback auf Default (100%) wenn Key nicht existiert
- [x] Gespeicherte Lautstaerke wird beim Gong-Abspielen verwendet
- [x] Preview in Settings spielt mit aktueller Slider-Lautstaerke
- [x] Lokalisiert (DE: "Lautstaerke", EN: "Volume")
- [x] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Unit Tests iOS (Settings-Persistierung, Audio-Lautstaerke)
- [x] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md (bei user-sichtbaren Aenderungen)

---

## Manueller Test

1. Settings oeffnen - Gong-Lautstaerke-Slider ist sichtbar
2. Slider auf ~50% stellen
3. Preview-Sound spielt mit reduzierter Lautstaerke
4. Anderen Gong waehlen - Lautstaerke bleibt bei 50%
5. Timer starten - Start-Gong spielt mit 50% Lautstaerke
6. Timer beenden - Ende-Gong spielt mit 50% Lautstaerke

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/SettingsView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt`

---

## Hinweise

- Eine globale Lautstaerke fuer alle Gong-Typen (Start, Ende, Intervall)
- Lautstaerke bleibt bei Sound-Wechsel erhalten (wird nicht zurueckgesetzt)
- Implementierung analog zu shared-019 (Background Volume Slider)
