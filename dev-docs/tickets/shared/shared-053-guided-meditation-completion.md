# Ticket shared-053: Guided Meditation Completion Screen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 4-Polish

---

## Was

Nach Ende einer gefuehrten Meditation wechselt der Player in einen Abschluss-Zustand: Die Player-Controls (Slider, Zeitanzeige, Skip-Buttons, Play/Pause) verschwinden. Stattdessen zeigt der Screen "Vielen Dank", den Meditationstitel, und einen Button "Zurueck zur Bibliothek".

## Warum

Nach dem Audio-Ende sind alle Player-Controls sinnlos - Skip, Slider und Play/Pause haben keine Funktion mehr. Der aktuelle Zustand ("pausiert bei 100%") ist nicht von einer echten Pause unterscheidbar. Ein warmer Abschluss mit klarer Navigation ersetzt den mehrdeutigen Zustand durch eine eindeutige Handlung. "Zurueck zur Bibliothek" fuehlt sich bewusster an als der X-Button, der eher nach "abbrechen" wirkt.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Wenn das Audio zu Ende spielt, wechselt die Player-View in den Completion-Zustand
- [ ] Completion zeigt "Danke" (DE) / "Thank you" (EN) als zentrales Element
- [ ] Meditationstitel wird darunter angezeigt (gibt Kontext)
- [ ] Button "Zurueck zur Bibliothek" (DE) / "Back to Library" (EN) navigiert zurueck zur Mediathek
- [ ] Player-Controls (Slider, Zeitanzeige, Skip-Buttons, Play/Pause) sind im Completion-Zustand nicht sichtbar
- [ ] X-Button in der Toolbar entfaellt im Completion-Zustand (der neue Button ersetzt ihn)
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (ViewModel: Completion-State nach Audio-Ende)
- [ ] Unit Tests Android (ViewModel: Completion-State nach Audio-Ende)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Gefuehrte Meditation starten und bis zum Ende abspielen lassen
2. Erwartung: Player-Controls verschwinden, "Danke" erscheint mit Meditationstitel und Button
3. Button "Zurueck zur Bibliothek" tippen
4. Erwartung: Navigation zurueck zur Mediathek
5. Identisch auf iOS und Android

---

## Hinweise

- Der Completion-Zustand wird nur erreicht wenn das Audio natuerlich zu Ende spielt. Bei manuellem Schliessen (X-Button waehrend Playback) bleibt das bisherige Verhalten.
- Konsistenz mit shared-052 (Timer Completion "Danke"): Beide Features schaffen einen bewussten Abschlussmoment statt eines toten Endzustands.
