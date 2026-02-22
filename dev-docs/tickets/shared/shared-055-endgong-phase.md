# Ticket shared-055: endGong als eigene Phase

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~3h | Android ~3h
**Phase**: 3-Refactoring

---

## Was

Neuer Timer-State `.endGong`. Wenn der Meditations-Timer 0 erreicht, wechselt er zu `.endGong` statt direkt zu `.completed`. Erst wenn der Completion-Gong verklungen ist (Audio-Callback), wird `.completed` gesetzt.

## Warum

Aktuell zeigt die UI "Meditation beendet" waehrend der Gong noch spielt. Auf Android wird der Foreground Service gestoppt bevor der Gong verklingt. Es gibt einen Zustand "completed aber Audio laeuft noch" der fachlich nicht existieren sollte.

**Bezug:** `dev-docs/architecture/meditation-session-aggregate.md` (Abschnitt 3.2), `dev-docs/architecture/timer-incremental-refactoring.md` (Schritt 3)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Phasenmodell

```
VORHER:   running -> tick(0) -> .completed + Effect: playGong
          (UI zeigt "fertig", Gong spielt noch)

NACHHER:  running -> tick(0) -> .endGong   + Event/Effect: playCompletionGong
                                   |
                                   | Gong spielt...
                                   | endGongFinished() (Audio-Callback)
                                   v
                                 .completed
                                   (UI zeigt jetzt erst "fertig")
```

**Asymmetrie zu Start Gong:** Start Gong ist Teil der aktiven Meditation (Timer laeuft, Ring fuellt sich). End Gong passiert NACH dem Timer (Timer bei 0, Ring voll). Das ist korrekt und gewollt.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Neuer State `.endGong` in TimerState / SessionPhase
- [ ] Timer bei 0 wechselt zu `.endGong`, nicht `.completed`
- [ ] Completion-Gong wird in `.endGong`-Phase abgespielt
- [ ] Audio-Callback (`endGongFinished()`) wechselt von `.endGong` zu `.completed`
- [ ] UI zeigt waehrend `.endGong` den Timer bei 00:00 (Ring voll, kein "fertig"-Text)
- [ ] Android: Foreground Service bleibt aktiv bis `.completed`
- [ ] Reset waehrend `.endGong` funktioniert (zurueck zu `.idle`)
- [ ] `isActive` schliesst `.endGong` ein (Session gilt als aktiv)

### Tests
- [ ] Unit Tests: running -> tick(0) -> `.endGong` (nicht `.completed`)
- [ ] Unit Tests: `.endGong` + endGongFinished() -> `.completed`
- [ ] Unit Tests: endGongFinished() in falscher Phase ist No-Op
- [ ] Unit Tests: reset() aus `.endGong` -> `.idle`
- [ ] Unit Tests: `isActive` ist true in `.endGong`
- [ ] Unit Tests: Timer laeuft korrekt bei gesperrtem Bildschirm durch endGong-Phase (Keep-Alive aktiv, Audio-Callback kommt an)
- [ ] Tests sind fachlich formuliert (Domaen-Sprache, nicht technisch)

### Dokumentation
- [ ] CHANGELOG.md
- [ ] State-Machine-Diagramm in `dev-docs/architecture/meditation-session-aggregate.md` aktualisiert
- [ ] State-Machine-Diagramm in `dev-docs/architecture/timer-incremental-refactoring.md` aktualisiert (falls vorhanden)
- [ ] `dev-docs/reference/glossary.md` aktualisiert (endGong als Begriff)
- [ ] `dev-docs/architecture/overview.md` aktualisiert falls Phasenmodell dort referenziert

---

## Manueller Test

1. Timer auf 1 Minute stellen, starten, bis 00:00 warten
2. Erwartung: Completion-Gong spielt, Timer zeigt 00:00, Ring ist voll
3. Erwartung: Erst NACH dem Gong erscheint der Completion-Screen
4. Android: Notification bleibt sichtbar bis Gong fertig
5. Reset waehrend Gong spielt: Timer geht zurueck zu idle
6. Identisch auf iOS und Android

---

## Hinweise

- Vollstaendig unabhaengig von den anderen Timer-Refactoring-Tickets (shared-054, shared-056, shared-057)
- Audio-Timing ist sensibel — gruendliches Device-Testing noetig
- Falls shared-052 (Timer Completion "Danke") schon umgesetzt ist: der "Danke"-Screen erscheint erst nach `.endGong` -> `.completed`
