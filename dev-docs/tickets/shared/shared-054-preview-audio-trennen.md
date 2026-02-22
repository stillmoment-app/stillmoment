# Ticket shared-054: Preview-Audio von Timer-Lifecycle trennen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 2-Architektur

---

## Was

Neuer `AudioSource.preview`-Typ. Preview-Methoden (Gong-Vorhoeren, Hintergrund-Vorhoeren) registrieren sich als `.preview`, nicht als `.timer`. Preview bekommt eigene Identitaet im AudioSessionCoordinator.

## Warum

Nach shared-059 (Keep-Alive-Invariante) startet Keep-Alive nur noch ueber `activateTimerSession()` — der urspruengliche Bug (Preview startet Keep-Alive) ist damit geloest.

Es bleiben drei Probleme, weil Preview-Methoden weiterhin `requestAudioSession(for: .timer)` aufrufen:

1. **Falsches Conflict-Handling:** Wenn ein User waehrend einer gefuehrten Meditation einen Gong vorhoert, feuert der `.timer`-Conflict-Handler und koennte die Guided Meditation stoppen.
2. **Session-Lifecycle-Leck:** Preview ruft `requestAudioSession(for: .timer)` auf, aber nie `releaseAudioSession(for: .timer)`. Die Session bleibt als "Timer aktiv" registriert, obwohl kein Timer laeuft.
3. **Irreführende Semantik:** Wer den Code liest, sieht `.timer` bei einem Preview und muss sich fragen warum.

**Bezug:** `dev-docs/architecture/timer-incremental-refactoring.md` (Schritt 4)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-059    |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] `AudioSource.preview` existiert als neuer Enum-Case
- [ ] Preview-Methoden (`playGongPreview`, `playBackgroundPreview`) nutzen `requestAudioSession(for: .preview)` statt `.timer`
- [ ] Preview gibt Audio-Session nach Abschluss wieder frei (`releaseAudioSession(for: .preview)`)
- [ ] Preview loest keinen Conflict-Handler fuer `.timer` oder `.guidedMeditation` aus
- [ ] Timer-Start ist von Preview unbeeinflusst (Preview stoppt bei Timer-Start)

### Tests
- [ ] Unit Tests: Preview registriert sich als `.preview`, nicht `.timer`
- [ ] Unit Tests: Preview loest keinen Timer-Conflict-Handler aus
- [ ] Unit Tests: Preview gibt Audio-Session nach Abschluss frei
- [ ] Unit Tests Android: Saubere Audio-Session-Trennung bei Preview

### Dokumentation
- [ ] CHANGELOG.md
- [ ] `dev-docs/architecture/audio-system.md` aktualisiert (neuer AudioSource.preview)
- [ ] Glossar aktualisiert falls noetig (`dev-docs/reference/glossary.md`)

---

## Manueller Test

1. Settings oeffnen, Gong-Preview abspielen
2. Erwartung: Gong spielt, kein Einfluss auf Timer-Session
3. Timer starten waehrend Preview laeuft
4. Erwartung: Preview stoppt, Timer laeuft normal
5. Identisch auf iOS und Android

---

## Hinweise

- Abhaengig von shared-059 (iOS): Preview-Methoden rufen aktuell `configureAudioSession()` auf, das nach shared-059 bereinigt wird
- Vollstaendig unabhaengig von shared-055, shared-056, shared-057
- Android hat kein Keep-Alive-Problem (Foreground Service), aber die saubere Trennung ist trotzdem sinnvoll fuer konsistente Audio-Session-Verwaltung
- AudioSessionCoordinator-Logik bleibt weitgehend unveraendert, nur neuer Enum-Case und ggf. angepasste Conflict-Regeln
