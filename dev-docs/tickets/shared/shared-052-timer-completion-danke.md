# Ticket shared-052: Timer Completion Screen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 4-Polish

---

## Was

Nach Ablauf des Meditationstimers ersetzt ein dedizierter Completion-Screen den laufenden Timer. Der Screen zeigt ein Herz-Icon, die Headline "Vielen Dank" und einen sanften Untertitel. Ein einzelner "Zurück"-Button schliesst den Screen. Tab-Bar bleibt ausgeblendet (wie im laufenden Timer).

## Warum

"00:00" im Ring ist ein toter Zustand - er sagt nichts Sinnvolles. Ein vollständiger Completion-Screen schafft einen bewussten Abschlussmoment: warmherzig, unaufdringlich, still. Das Herz-Icon wuerdigt die Praxis ohne Achievement-Framing (kein Checkmark, keine Stats, kein "Geschafft!"). Der Screen "atmet" - viel Weissraum, wenig Text. Konsistent mit shared-053 (Guided Meditation Completion): beide Features teilen dieselbe visuelle Sprache.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Nach Timer-Ablauf wechselt die View in den Completion-Zustand (vollständige Bildschirmübernahme, kein Ring mehr sichtbar)
- [ ] Übergang: Fade-in mit Slide-in-from-Bottom Animation
- [ ] Herz-Icon (gefüllt, Indigo-Ton) in kreisförmigem Container als visuelles Zentrum
- [ ] Headline "Vielen Dank" (DE) / "Thank you" (EN) – gross, leicht, zentriert
- [ ] Untertitel "Schön, dass du dir diese Zeit genommen hast." (DE) / passende EN-Übersetzung
- [ ] Einziger Button: "Zurück" – navigiert zurück zum Timer Idle Screen
- [ ] Kein X-Button, kein Close-Icon im Completion-Zustand
- [ ] Tab-Bar bleibt ausgeblendet (identisch zum laufenden Timer)
- [ ] Abschluss-Gong spielt weiterhin wie bisher (Trigger unverändert)
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (Reducer/ViewModel: Completed-State wird korrekt produziert)
- [ ] Unit Tests Android (Reducer/ViewModel: Completed-State wird korrekt produziert)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Timer auf beliebige Dauer stellen und starten
2. Warten bis Timer abläuft und Abschluss-Gong spielt
3. Erwartung: Completion-Screen erscheint mit Slide-in-Animation – Herz-Icon, "Vielen Dank", Untertitel, "Zurück"-Button
4. Kein Ring, keine Timer-Anzeige, kein X-Button, keine Tab-Bar sichtbar
5. "Zurück" tippen → Timer Idle Screen
6. Identisch auf iOS und Android

---

## Hinweise

- Referenz-Design: Prototype `dev-docs/ui-prototype.html`, `RunningTimerScreen` → State 2 "Completed"
- Konsistenz mit shared-053: Beide Completion-Screens teilen identische visuelle Sprache (selbes Icon, selbe Texte, selber Button-Stil)
- Reine Presentation-Aenderung. Kein neuer Domain-State noetig – der bestehende Completed-State wird nur anders dargestellt.
