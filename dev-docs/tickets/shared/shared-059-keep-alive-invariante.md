# Ticket shared-059: Keep-Alive strukturell absichern (Always-On waehrend Timer-Session)

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: iOS ~1-2h | Android ~1h (nur Konzept-Uebernahme)
**Phase**: 2-Architektur

---

## Was

Keep-Alive (lautlose Audio-Datei) laeuft durchgehend von Timer-Start bis Timer-Ende. Kein Stoppen, kein Neustarten, keine Koordination mit anderen Audio-Playern. Zwei Methoden: `activateTimerSession()` und `deactivateTimerSession()`. Alle verstreuten `startKeepAliveAudio()`/`stopKeepAliveAudio()`-Aufrufe in anderen Methoden werden entfernt.

## Warum

Keep-Alive wird heute durch verstreute `startKeepAliveAudio()`/`stopKeepAliveAudio()`-Aufrufe gesteuert (6 Stellen die starten, 4 die stoppen). Jedes neue Feature das eine Audio-Transition hinzufuegt kann eine Luecke erzeugen, in der kein Audio-Player aktiv ist — und iOS die App im Background suspendiert.

4 dokumentierte Brueche mit diesem Muster:
- Nov 2025: Countdown-Freeze bei gesperrtem Bildschirm
- Jan 2026: Luecke zwischen stiller Audio und MP3-Start
- Feb 2026: Introduction-Transition-Luecke (Background-Audio startet nicht nach Introduction bei gesperrtem Bildschirm)
- Feb 2026: Timer-State-Sync nach Introduction-Port

**Kernproblem:** Das bisherige Design versucht, Keep-Alive "intelligent" zu steuern — stoppen wenn echtes Audio uebernimmt, starten wenn eine Luecke entsteht. Diese Koordination ist die Fehlerquelle. Die lautlose Audio-Datei auf Volume 0.01 stoert kein anderes Audio. Es gibt keinen Grund, sie zwischendurch zu stoppen.

**Bezug:** `dev-docs/architecture/timer-incremental-refactoring.md` (Schritt 5)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## API-Aenderung

```swift
// VORHER: Verstreute Start/Stop-Aufrufe (fragil)
func configureAudioSession() throws {
    _ = try coordinator.requestAudioSession(for: .timer)
    startKeepAliveAudio()  // versteckter Seiteneffekt
}

func startBackgroundAudio(...) throws {
    try configureAudioSession()
    stopKeepAliveAudio()  // manuell stoppen — kann vergessen werden
    // ...
}

func stopBackgroundAudio() {
    backgroundAudioPlayer?.stop()
    stopKeepAliveAudio()  // warum hier stoppen?
    // ...
}

// NACHHER: Always-On
func activateTimerSession() throws {
    _ = try coordinator.requestAudioSession(for: .timer)
    startKeepAliveAudio()  // AN — bleibt an bis deactivate
}

func deactivateTimerSession() {
    stopKeepAliveAudio()   // AUS — einzige Stelle die Keep-Alive stoppt
    coordinator.releaseAudioSession(for: .timer)
}

func startBackgroundAudio(...) throws {
    // Keep-Alive? Nicht anfassen. Laeuft parallel, stoert nicht.
    // ...
}

func stopBackgroundAudio() {
    backgroundAudioPlayer?.stop()
    // Keep-Alive? Nicht anfassen. Laeuft weiter.
}
```

Guard in `startKeepAliveAudio()` vereinfachen:
```swift
// VORHER:
guard self.keepAlivePlayer == nil, self.backgroundAudioPlayer == nil else { return }

// NACHHER:
guard self.keepAlivePlayer == nil else { return }
```

---

## Akzeptanzkriterien

### Feature (iOS)
- [ ] `activateTimerSession()` startet Audio-Session und Keep-Alive
- [ ] `deactivateTimerSession()` stoppt Keep-Alive und gibt Audio-Session frei
- [ ] Keep-Alive laeuft durchgehend von Timer-Start bis Timer-Ende
- [ ] Keine `startKeepAliveAudio()`/`stopKeepAliveAudio()`-Aufrufe in anderen AudioService-Methoden
- [ ] `startKeepAliveAudio()` Guard entfernt Pruefung auf `backgroundAudioPlayer`
- [ ] Alle bisherigen `configureAudioSession()`-Aufrufe im Timer-Pfad durch `activateTimerSession()` ersetzt oder entfernt (redundante Aufrufe in `playStartGong`, `playIntroduction` etc. entfallen, weil Session bereits aktiv ist)
- [ ] Nach Audio-Interruption (Anruf, Siri): Keep-Alive wird im Interruption-Handler neu gestartet falls Timer aktiv
- [ ] `configureAudioSession()` bleibt nur fuer Nicht-Timer-Pfade (Preview, Guided Meditation) oder wird komplett durch spezifische Methoden ersetzt

### Feature (Android)
- [ ] Klare Session-Grenzen: `activateTimerSession()` / `deactivateTimerSession()` als Konzept uebernommen
- [ ] Kein Keep-Alive noetig (Foreground Service), aber sauberes Lifecycle-Management

### Tests
- [ ] Keep-Alive startet bei `activateTimerSession()`
- [ ] Keep-Alive stoppt bei `deactivateTimerSession()`
- [ ] Keep-Alive laeuft weiter wenn Background-Audio startet
- [ ] Keep-Alive laeuft weiter wenn Background-Audio stoppt
- [ ] Keep-Alive laeuft weiter wenn Gong spielt
- [ ] Keep-Alive laeuft weiter wenn Introduction spielt und endet
- [ ] Keine Keep-Alive-Aktivitaet nach `deactivateTimerSession()`
- [ ] Nach Audio-Interruption wird Keep-Alive neu gestartet falls Timer aktiv
- [ ] Tests sind fachlich formuliert (Domaen-Sprache, nicht technisch)

### Dokumentation
- [ ] CHANGELOG.md
- [ ] `dev-docs/architecture/audio-system.md` aktualisiert (Always-On Keep-Alive)
- [ ] ADR-004 referenziert oder ergaenzt

---

## Manueller Test

1. Stille Meditation starten, Bildschirm sperren, 2 Minuten warten
2. Erwartung: Timer laeuft weiter, Completion-Gong spielt am Ende
3. Timer mit Introduction starten, Bildschirm sperren
4. Erwartung: Introduction spielt, Background-Audio startet danach, Timer laeuft
5. Timer mit Hintergrundmusik starten, Bildschirm sperren
6. Erwartung: Musik spielt, Timer laeuft, Completion-Gong spielt
7. Timer starten, Anruf simulieren, Anruf beenden
8. Erwartung: Timer laeuft weiter nach Anruf
9. Timer starten, Kopfhoerer rausziehen/einstecken
10. Erwartung: Timer laeuft weiter nach Unterbrechung

---

## Hinweise

- Vollstaendig unabhaengig von shared-054 bis shared-058
- Sollte **vor shared-055 (endGong)** umgesetzt werden: endGong fuegt eine neue Audio-Transition hinzu, die mit Always-On automatisch abgesichert ist
- Keep-Alive-Mechanismus selbst (lautlose Audio-Datei, Volume 0.01, Loop) bleibt unveraendert
- Keep-Alive-Datei: `silence.mp3` (iOS), `silence.m4a` (Android)
- ADR-004 Grundsatz bleibt: Keep-Alive ist Infrastructure-Concern, Domain weiss nichts davon
- Android braucht kein Keep-Alive, aber `activateTimerSession()`/`deactivateTimerSession()` als Konzept ist sinnvoll fuer sauberes Lifecycle-Management
- Die bisherige Komplexitaet (6 Start-Stellen, 4 Stop-Stellen) entsteht durch den Versuch, Keep-Alive "intelligent" zu koordinieren. Die lautlose Datei auf Volume 0.01 stoert kein anderes Audio — es gibt keinen Grund, sie zwischendurch zu stoppen
