# Critical Code Test Cases

Konkrete Testfälle für kritischen Code. Nutze diese Liste bei Code Reviews und neuen Features.

---

## Domain Layer (MUST TEST ≥85%)

### MeditationTimer + TimerReducer

State Machine - alle Timer-Funktionen hängen davon ab.

**State Transitions:**
- idle → countdown → running → paused → completed
- Pause/Resume aus jedem aktiven State
- Reset aus jedem State zurück zu idle

**Edge Cases:**
- Tick bei remainingSeconds = 0
- Pause bei remainingSeconds = 0
- Resume nach mehrfachem Pause
- Countdown → Running Übergang exakt bei 0

**Interval Gongs:**
- Gong bei exakt 3/5/10 Minuten-Marken
- Kein doppelter Gong bei gleichem Intervall
- lastIntervalGongAt wird korrekt gesetzt

### AudioSessionCoordinator

Verhindert Audio-Konflikte zwischen Timer und Guided Meditation.

**Exclusive Access:**
- Nur eine Source kann Session gleichzeitig halten
- Zweite Anfrage übernimmt von erster
- Release gibt Session frei

**Publisher:**
- activeSource emittiert bei jeder Änderung
- nil nach release

---

## Application Layer (MUST TEST ≥80%)

### TimerViewModel

**Controls:** start, pause, resume, reset
**State Sync:** ViewModel.state spiegelt Timer.state
**Formatting:** formattedTime zeigt MM:SS korrekt
**Settings:** Interval-Gongs und Background-Audio werden angewendet
**Cleanup:** Audio Session wird bei Completion freigegeben

### GuidedMeditationPlayerViewModel

**Playback:** play, pause, skipForward, skipBackward
**Progress:** currentTime und duration aktualisieren korrekt
**Seek:** Seeking zu beliebiger Zeit funktioniert
**NowPlaying:** Lock Screen Info wird aktualisiert
**Cleanup:** Resources bei stop/deinit freigegeben

### GuidedMeditationsListViewModel

**Import:** MP3 Import erfolgreich
**Metadata:** ID3 Tags werden extrahiert
**Editing:** Manuelle Edits werden gespeichert
**Grouping:** Gruppierung nach Teacher
**Deletion:** Datei und Bookmark werden gelöscht
**Security Bookmarks:** Zugriff überlebt App-Neustart

---

## Infrastructure Layer (MUST TEST ≥70%)

### Error Handling

**GuidedMeditationService:**
- Datei extern gelöscht
- Permission verweigert
- Ungültiges Format
- Bookmark nicht auflösbar

**AudioService / AudioPlayerService:**
- Session-Aktivierung fehlgeschlagen
- Playback unterbrochen (Anruf)
- Datei korrupt/fehlend

---

## Integration (UI Tests / Manual)

**Background Audio:**
- Timer läuft bei gesperrtem Screen
- Gongs spielen im Hintergrund
- Completion-Gong spielt auch wenn App beendet

**Tab Navigation:**
- Timer-State bleibt bei Tab-Wechsel
- Player läuft bei Tab-Wechsel weiter
- Audio-Wechsel stoppt andere Quelle

---

## Niedriger Priorität

**UI Components:** SwiftUI Previews + manuelles Testen
**Simple Models:** Über ViewModel-Tests abgedeckt (MeditationSettings, GuidedMeditation)
