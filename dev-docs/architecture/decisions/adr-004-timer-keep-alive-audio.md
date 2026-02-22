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

1. `AudioService.configureAudioSession()` startet intern einen stillen Audio-Loop (`silence.mp3`) der die Audio-Session am Leben haelt
2. `AudioService.startBackgroundAudio()` ersetzt den Keep-Alive-Loop durch den echten Background-Sound
3. `AudioService.stopBackgroundAudio()` und `stop()` beenden auch den Keep-Alive-Loop
4. Der Reducer emittiert keine Keep-Alive-bezogenen Effects — er drueckt nur fachliche Intention aus

```
Reducer:  configureAudioSession    startBackgroundAudio    stopBackgroundAudio
              │                         │                       │
AudioService: │                         │                       │
              ▼                         ▼                       ▼
         Session aktivieren      Keep-Alive stoppen        Alles stoppen
         Keep-Alive starten      Echtes Audio starten
```

### Audio-Player-Architektur

Drei unabhaengige AVAudioPlayer-Instanzen fuer drei unabhaengige Audio-Streams:

| Player | Lebenszyklus | Zweck |
|--------|-------------|-------|
| `keepAlivePlayer` | configureAudioSession → startBackgroundAudio | Haelt Audio-Session aktiv (Infrastructure) |
| `audioPlayer` | playGong → delegate fires | Start-Gong, Intervall-Gongs, Completion-Gong |
| `introductionPlayer` | playIntroduction → delegate fires | Gefuehrte Einleitung |
| `backgroundAudioPlayer` | startBackgroundAudio → stopBackgroundAudio | Hoerbarer Background-Sound |

Keep-Alive und Background-Audio sind **sequenziell** (nie gleichzeitig). Gong und Introduction spielen **parallel** zum jeweils aktiven Background-Player.

## Konsequenzen

### Positiv

- **Reducer bleibt rein**: Kein iOS-spezifisches Wissen im Domain-Layer
- **Erweiterbar**: Neue Timer-Phasen brauchen keine Keep-Alive-Logik — sie sind automatisch abgedeckt
- **Konsistent**: Gleiches Pattern wie Guided-Meditation-Countdown
- **Testbar**: Keep-Alive ist ein Implementierungsdetail das in AudioService-Tests geprueft wird, Reducer-Tests bleiben unveraendert

### Negativ

- **Implizites Verhalten**: `configureAudioSession()` hat jetzt einen Seiteneffekt (Keep-Alive starten) der nicht am API-Namen erkennbar ist

### Mitigationen

- Dokumentation in AudioService (Docstring auf `configureAudioSession`)
- Logging bei Keep-Alive-Start/Stop
- AudioService-Tests pruefen das Keep-Alive-Verhalten explizit

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
