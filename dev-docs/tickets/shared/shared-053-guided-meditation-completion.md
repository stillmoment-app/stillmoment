# Ticket shared-053: Guided Meditation Completion Screen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 4-Polish

---

## Was

Nach Ende einer geführten Meditation wechselt der Player in einen Completion-Zustand: Die Player-Controls (Slider, Zeitanzeige, Skip-Buttons, Play/Pause, X-Button) verschwinden. Stattdessen erscheint derselbe Completion-Screen wie bei shared-052: Herz-Icon, "Vielen Dank", Untertitel, "Zurück"-Button. Der Button schliesst den Player und kehrt zur Bibliothek zurück.

## Warum

Nach Audio-Ende sind alle Player-Controls sinnlos. Der aktuelle Zustand ("pausiert bei 100%") ist nicht von einer echten Pause unterscheidbar – ein stiller, ungeklärter Endpunkt. Ein warmer Abschluss-Moment mit klarer Handlung ersetzt den mehrdeutigen Zustand. "Zurück" schliesst den Player bewusst. Visuell konsistent mit shared-052: Beide Meditation-Typen (still und geführt) teilen dieselbe Abschluss-Sprache – der Moment des Dankens gehört zur Praxis, nicht zur Meditationsform.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Wenn das Audio natürlich zu Ende spielt, wechselt die Player-View in den Completion-Zustand
- [ ] Übergang: Fade-in mit Slide-in-from-Bottom Animation
- [ ] Herz-Icon (gefüllt, Indigo-Ton) in kreisförmigem Container als visuelles Zentrum
- [ ] Headline "Vielen Dank" (DE) / "Thank you" (EN) – gross, leicht, zentriert
- [ ] Untertitel "Schön, dass du dir diese Zeit genommen hast." (DE) / passende EN-Übersetzung
- [ ] Einziger Button: "Zurück" – schliesst den Player, kehrt zur Bibliothek zurück
- [ ] Player-Controls (Slider, Zeitanzeige, Skip-Buttons, Play/Pause) im Completion-Zustand nicht sichtbar
- [ ] X-Button in der Toolbar entfällt im Completion-Zustand
- [ ] Tab-Bar bleibt ausgeblendet (identisch zum laufenden Player)
- [ ] Kein Meditationstitel im Completion-Zustand (Stille nach der Praxis)
- [ ] Bei manuellem Schliessen (X-Button während Playback) kein Completion-Screen – Verhalten unverändert
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (ViewModel: Completion-State nach Audio-Ende)
- [ ] Unit Tests Android (ViewModel: Completion-State nach Audio-Ende)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Geführte Meditation starten und bis zum Ende abspielen lassen
2. Erwartung: Completion-Screen erscheint mit Slide-in-Animation – Herz-Icon, "Vielen Dank", Untertitel, "Zurück"-Button
3. Kein Player-Control sichtbar, kein X-Button, keine Tab-Bar
4. "Zurück" tippen → Player schliesst sich, Bibliothek sichtbar
5. Geführte Meditation starten, während Playback X-Button tippen → kein Completion-Screen, Verhalten wie bisher
6. Identisch auf iOS und Android

---

## Hinweise

- Referenz-Design: Prototype `dev-docs/ui-prototype.html`, `PlayerOverlay` → State 2 "Completed"
- Konsistenz mit shared-052: Beide Completion-Screens sind visuell identisch (selbes Icon, selbe Texte, selber Button-Stil)
- Der Completion-Zustand wird nur erreicht wenn das Audio natürlich zu Ende spielt, nicht bei manuellem Abbruch.
