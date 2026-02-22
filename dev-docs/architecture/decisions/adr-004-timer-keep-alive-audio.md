# ADR-004: Timer Keep-Alive Audio als Infrastructure-Concern

## Status

Akzeptiert

## Kontext

Der Meditation Timer durchlaeuft mehrere Phasen: Preparation → Start-Gong → [Introduction →] Running → Completed. iOS suspendiert Apps im Background wenn keine aktive Audio-Wiedergabe laeuft. Nicht jede Phase hat eigenes Audio:

- **Preparation**: Kein Audio (visueller Countdown)
- **Start-Gong → Introduction**: Kurze Luecke beim Uebergang
- **Introduction → Running**: Kurze Luecke beim Uebergang

Diese Luecken fuehren dazu, dass iOS die App suspendiert und der Timer haengt.

Das Guided-Meditation-Modul loest dasselbe Problem bereits mit `AudioPlayerService.startSilentBackgroundAudio()` waehrend des Countdowns. Der Timer braucht ein analoges Muster.

**Anforderungen:**
1. Die App muss waehrend aller Timer-Phasen im Background wach bleiben
2. Der Domain-Layer (Reducer) darf keine iOS-Workarounds kennen
3. Das Pattern muss erweiterbar sein fuer zukuenftige Timer-Phasen

## Entscheidung

Keep-Alive Audio wird als **internes Implementierungsdetail** der AudioService gehandhabt:

1. `AudioService.activateTimerSession()` startet Audio-Session + stillen Audio-Loop (`silence.mp3`)
2. Keep-Alive laeuft **durchgehend** — wird NICHT gestoppt wenn Background-Audio, Gong oder Introduction spielt
3. `AudioService.deactivateTimerSession()` ist die **einzige** Stelle die Keep-Alive beendet
4. Der Reducer emittiert `activateTimerSession` bei Start und `deactivateTimerSession` bei Reset/Completion

```
Reducer:  activateTimerSession    startBackgroundAudio    deactivateTimerSession
              │                         │                       │
AudioService: │                         │                       │
              ▼                         ▼                       ▼
         Session aktivieren      Echtes Audio starten     Keep-Alive stoppen
         Keep-Alive starten      (Keep-Alive laeuft       Session freigeben
                                  parallel weiter)
```

### Audio-Player-Architektur

Vier unabhaengige AVAudioPlayer-Instanzen:

| Player | Lebenszyklus | Zweck |
|--------|-------------|-------|
| `keepAlivePlayer` | activateTimerSession → deactivateTimerSession | Haelt Audio-Session aktiv (Always-On) |
| `audioPlayer` | playGong → delegate fires | Start-Gong, Intervall-Gongs, Completion-Gong |
| `introductionPlayer` | playIntroduction → delegate fires | Gefuehrte Einleitung |
| `backgroundAudioPlayer` | startBackgroundAudio → stopBackgroundAudio | Hoerbarer Background-Sound |

Keep-Alive und Background-Audio laufen **parallel** (nicht sequenziell). Die lautlose Datei bei Volume 0.01 stoert kein anderes Audio. Gong und Introduction spielen ebenfalls parallel.

## Konsequenzen

### Positiv

- **Keine Luecken**: Keep-Alive laeuft durch — egal welche Audio-Transitions passieren
- **Einfacher**: Zwei Methoden statt 6 Start-Stellen und 4 Stop-Stellen
- **Erweiterbar**: Neue Timer-Phasen/Audio-Features brauchen keine Keep-Alive-Koordination
- **Interruption-safe**: Keep-Alive wird nach Audio-Unterbrechung automatisch neu gestartet
- **Reducer bleibt rein**: Session-Grenzen als Effects, kein iOS-spezifisches Wissen

### Negativ

- **Zwei Audio-Streams gleichzeitig**: Keep-Alive und Background-Audio laufen parallel (minimal, da Volume 0.01)

### Mitigationen

- Dokumentation in AudioService (Docstrings auf `activateTimerSession`/`deactivateTimerSession`)
- Logging bei Keep-Alive-Start/Stop/Resume
- AudioService-Tests pruefen das Always-On-Verhalten explizit

## Alternativen (verworfen)

### Option A: Background Audio ab Start im Reducer (Volume 0 → Fade-In)

Reducer emittiert `.startBackgroundAudio(volume: 0)` in `startPressed`, `.fadeInBackgroundAudio(volume:)` bei Running-Uebergang.

**Verworfen weil:** iOS-Workaround (Volume 0 zum Keep-Alive) ist kein fachliches Konzept und gehoert nicht in den Domain-Layer. Neuer Effect `.fadeInBackgroundAudio` waere rein technisch motiviert.

### Option B: Wallclock-basierte Recovery

Timestamps speichern, bei App-Resume aus Background korrekte Phase berechnen.

**Verworfen weil:** Loest nicht das Audio-Problem (Gong/Introduction brauchen aktive Audio-Session). Guided Meditations haben Wallclock als Fallback, nicht als primaere Strategie. Hohe Komplexitaet fuer den Timer-Reducer.

### Option C: Relay-Pattern (Player-Staffeluebergabe)

Naechsten Player starten bevor aktueller endet.

**Verworfen weil:** Bei event-driven Uebergaengen (Gong-Ende, Introduction-Ende) ist das Audio-Ende der Trigger. "Vorher starten" ist nicht moeglich wenn man nicht weiss wann "vorher" ist.

---

**Datum**: 2026-02-22
**Autor**: Claude Code
