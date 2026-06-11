# Plan shared-105 (iOS): Trim-Punkte fuer gefuehrte Meditationen

## Architektur-Entscheidungen

1. **Nicht-destruktiv, Domain-zentriert.** `GuidedMeditation` bekommt zwei optionale
   Felder `trimStart`/`trimEnd` (TimeInterval, Sekunden, absolut zur Datei). Alle
   abgeleitete Logik lebt als computed properties im Domain-Modell:
   - `effectiveStart` (= `trimStart ?? 0`)
   - `effectiveEnd` (= `trimEnd ?? duration`)
   - `effectiveDuration` (= `effectiveEnd - effectiveStart`)
   - `hasValidTrim`-Validierung: `0 <= start < end <= duration`
2. **Codable abwaertskompatibel:** `decodeIfPresent`/`encodeIfPresent` — Legacy-JSON
   ohne Trim-Keys laedt unveraendert (nil = kein Trim).
3. **Ende-Erkennung im Service, nicht im ViewModel.** `AudioPlayerService` setzt bei
   gesetztem `trimEnd` einen `AVPlayer.addBoundaryTimeObserver` und behandelt das
   Erreichen wie `AVPlayerItemDidPlayToEndTime` (gleicher Completion-Pfad →
   Abschluss-Screen, Session-Release). Boundary-Observer funktioniert auf dem Lock
   Screen (kein UI-Polling). Cleanup entfernt den Observer.
4. **Start-Offset im Service:** `load()` seeked nach erfolgreichem Laden auf
   `effectiveStart` und sendet `currentTime`. `seek(to:)` clamped auf
   `[effectiveStart, effectiveEnd]` (gilt damit auch fuer Lock-Screen-Seek/Skip).
   Restart aus `.finished` (`seek(to: 0)`) landet durch Clamping auf `trimStart`.
5. **Anzeige-Mapping im ViewModel:** Published `currentTime`/`duration` bleiben
   absolut (Dateikoordinaten). Anzeige rechnet effektiv:
   `formattedRemainingTime = effectiveEnd - currentTime`, `progress` relativ zum
   Trim-Bereich, Skip ±10s clamped auf den Bereich.
6. **NowPlaying (Lock Screen):** Dauer = `effectiveDuration`, Elapsed =
   `currentTime - effectiveStart` (Mapping im Service via `currentMeditation`).
7. **Effektive Dauer in der Library:** `formattedDuration` formatiert
   `effectiveDuration`. Im Edit-Sheet-Footer (Datei-Info) zeigt ein neues
   `formattedFileDuration` weiterhin die echte Dateilaenge (Referenz beim Trimmen).
8. **Edit-Sheet minimal-UI:** Neue Section mit zwei Zeilen "Beginnen bei" /
   "Beenden bei": mm:ss-Textfeld (leer = kein Trim) + Vorhoer-Button ("ab hier
   anhoeren") pro Zeile. Vorhoeren nur im `.edit`-Modus (Import: Datei ggf. noch
   nicht in der Library, User kennt Trim-Punkte noch nicht). Vorhoeren laeuft ueber
   die bestehende Library-Preview-Infrastruktur (shared-098) via Closures vom
   List-View. Sheet-Dismiss stoppt die Preview.
9. **EditSheetState** erweitert: `editedTrimStartText`/`editedTrimEndText` (Strings,
   mm:ss), Parsing/Formatting-Helfer (pure Swift), `isValid` beruecksichtigt
   Trim-Konsistenz, `hasChanges` beruecksichtigt Trim-Aenderungen, `applyChanges()`
   uebertraegt geparste Werte.

## Reihenfolge (TDD pro Schritt)

1. **Domain:** Trim-Felder + effective* + Codable-Roundtrip/Legacy-Decode +
   formattedDuration/formattedFileDuration. Tests in GuidedMeditationTests (neu
   oder bestehend erweitern).
2. **EditSheetState:** mm:ss-Parsing, Validierung, hasChanges, applyChanges.
3. **Persistenz:** GuidedMeditationServiceTests: save/load-Roundtrip mit Trim,
   Legacy-Daten ohne Trim.
4. **PlayerViewModel:** Anzeige-Mapping (remaining, progress), Skip-Clamping —
   gegen MockAudioPlayerService.
5. **AudioPlayerService:** Start-Seek, Boundary-Observer, Seek-Clamping, NowPlaying-
   Mapping. (AVPlayer-Logik — nicht unit-testbar, Logik-Anteile stecken im Domain-
   Modell; manuelle Verifikation.)
6. **UI:** Edit-Sheet-Section + Lokalisierung (DE/EN) + Accessibility +
   Screenshot-Verifikation.

## Risiken

- Boundary-Observer-Verhalten bei Seek hinter trimEnd (Clamping verhindert das).
- `togglePlayPause` aus `.finished`: `seek(to: 0)` → Clamping auf trimStart noetig,
  sonst spielt das Intro wieder.
- Preview-Audio vs. Player-Audio: Views sind nie gleichzeitig aktiv (Projekt-
  Invariante), Edit-Sheet liegt ueber der Library — Preview nutzt `.preview`-Session.

## Nicht in Scope

- Dual-Handle-Slider / Wellenform-UI (spaeteres Ticket)
- Android (separater Durchlauf)
