# Ticket shared-054: Preview-Audio von Timer-Lifecycle trennen

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~2h | Android ~1h
**Phase**: 2-Architektur

---

## Was

Neuer `AudioSource.preview`-Typ. Preview-Methoden (Gong-Vorhoeren, Hintergrund-Vorhoeren) registrieren sich als `.preview`, nicht als `.timer`. Keep-Alive-Audio ist an den `.timer`-Lifecycle gebunden und wird bei Preview nicht gestartet.

## Warum

Aktuell teilen Preview und Timer denselben Audio-Pfad (`configureAudioSession()`). Das startet Keep-Alive-Audio auch bei Previews — ein Bug. Es gibt kein Konzept fuer "Audio-Lifecycle" das Preview von Timer trennt.

**Bezug:** `dev-docs/architecture/meditation-session-aggregate.md` (Abschnitt 7), `dev-docs/architecture/timer-incremental-refactoring.md` (Schritt 4)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] `AudioSource.preview` existiert als neuer Enum-Case
- [ ] Preview-Methoden (`playGongPreview`, `playBackgroundPreview`) nutzen `.preview` statt `.timer`
- [ ] Preview startet KEIN Keep-Alive-Audio
- [ ] Timer-Start startet weiterhin Keep-Alive-Audio (unveraendert)
- [ ] Preview und Timer koennen nicht gleichzeitig laufen (Preview stoppt bei Timer-Start)

### Tests
- [ ] Unit Tests iOS: Preview registriert sich als `.preview`, nicht `.timer`
- [ ] Unit Tests iOS: Keep-Alive wird bei Preview nicht gestartet
- [ ] Unit Tests Android: Saubere Audio-Session-Trennung bei Preview

### Dokumentation
- [ ] CHANGELOG.md
- [ ] `dev-docs/architecture/audio-system.md` aktualisiert (neuer AudioSource.preview)
- [ ] Glossar aktualisiert falls noetig (`dev-docs/reference/glossary.md`)

---

## Manueller Test

1. Settings oeffnen, Gong-Preview abspielen
2. Erwartung: Gong spielt, kein Keep-Alive-Audio im Hintergrund
3. Timer starten
4. Erwartung: Keep-Alive-Audio laeuft (unveraendertes Verhalten)
5. Identisch auf iOS und Android

---

## Hinweise

- Vollstaendig unabhaengig von den anderen Timer-Refactoring-Tickets (shared-055, shared-056, shared-057)
- Android hat kein Keep-Alive-Problem (Foreground Service), aber die saubere Trennung ist trotzdem sinnvoll fuer konsistente Audio-Session-Verwaltung
- AudioSessionCoordinator-Logik bleibt unveraendert, nur neuer Enum-Case
