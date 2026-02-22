# Ticket shared-052: Timer Completion "Danke"

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 4-Polish

---

## Was

Nach Ablauf des Meditationstimers zeigt der Ring das Wort "Danke" statt "00:00". Der Statustext unterhalb des Rings entfaellt komplett. Der Screen bleibt stehen, bis der User ihn manuell schliesst.

## Warum

"00:00" ist eine tote Information - sie sagt dem User nichts Sinnvolles. "Danke" wuerdigt die Praxis ohne Achievement-Framing (kein Checkmark, kein "geschafft!", keine Stats). Es passt zur App-Philosophie: warmherzig, unaufdringlich, still. Kein Text darunter laesst den Bildschirm atmen - maximale Stille nach der Meditation.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Timer-Ring zeigt nach Ablauf "Danke" (DE) / "Thank you" (EN) statt "00:00"
- [ ] Kein Statustext unterhalb des Rings im Completed-State (kein "Meditation abgeschlossen", keine Affirmation, nichts)
- [ ] Ring bleibt voll (progress 100%), gleiche Farbe wie im Running-State
- [ ] Screen bleibt stehen bis User manuell schliesst (X-Button)
- [ ] Abschluss-Gong spielt weiterhin wie bisher
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (Reducer/ViewModel: Completed-State produziert korrekte Display-Werte)
- [ ] Unit Tests Android (Reducer/ViewModel: Completed-State produziert korrekte Display-Werte)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Timer auf beliebige Dauer stellen und starten
2. Warten bis Timer ablaeuft und Abschluss-Gong spielt
3. Erwartung: Ring ist voll, zeigt "Danke" in der Mitte, kein Text darunter
4. Screen bleibt stehen bis X getippt wird
5. Identisch auf iOS und Android

---

## Hinweise

- Reine Presentation-Aenderung. Kein neuer Timer-State noetig - der bestehende Completed-State wird nur anders dargestellt.
- Die Schriftgroesse von "Danke"/"Thank you" sollte zum Ring passen (aehnlich prominent wie die Zeitanzeige im Running-State, aber nicht zwingend gleiche Groesse).
