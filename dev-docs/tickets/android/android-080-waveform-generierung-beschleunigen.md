# Ticket android-080: Waveform-Generierung langer Meditationen beschleunigen

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Prioritaet**: HOCH
**Komplexitaet**: Loesungsweg ist per Spike validiert (siehe Hinweise). Hauptarbeit: Prototyp produktionsreif machen (Tests, Edge-Case kurze Dateien, sauberes DI). Device-only Decode-Pfad, daher manuelle On-Device-Verifikation noetig.
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die Waveform-Generierung im Trim-/Meditation-Editor soll fuer lange Dateien (15+ Min) in wenigen Sekunden statt ~43s fertig sein.

## Warum

Beim Oeffnen des Editors einer langen Meditation laedt die Waveform sehr lange (gemessen ~43s fuer eine ~20-Min-MP3, auch auf echter Fairphone-Hardware). Der User sieht eine leere/ladende Waveform und wartet — das widerspricht "schnelle App = unaufdringliche App". iOS ist deutlich schneller (Hardware-naher AudioToolbox-Decoder); das Problem ist Android-spezifisch.

---

## Akzeptanzkriterien

### Feature
- [ ] Die Waveform einer ~20-Min-Meditation ist nach dem Import bzw. beim Oeffnen des Editors in wenigen Sekunden sichtbar (Spike erreichte ~5,7s statt ~43s auf dem Emulator).
- [ ] Die Waveform bleibt visuell brauchbar: Stille/laute Passagen sind klar unterscheidbar, die Gesamtform entspricht grob der Aufnahme. **Es geht um eine plausible UI-Waveform, nicht um sample-genaue Audio-Bearbeitung** — eine approximative Huellkurve (Spike: Korrelation ~0,6 zur exakten) ist explizit akzeptiert.
- [ ] Aufloesung bleibt bei 2200 Bars.
- [ ] Kurze Dateien werden weiterhin korrekt (und vollstaendig) dekodiert — bei festem Sampling-Takt (~4/s) hat eine kurze Datei zu wenige Messpunkte fuer 2200 Bars. Schwelle waehlen, unterhalb derer voll dekodiert wird (kurze Dateien sind ohnehin schnell).
- [ ] Nur Android. iOS bleibt exakt — die daraus folgende Abweichung der Waveform-Form zwischen den Plattformen ist bewusst akzeptiert (ein User sieht immer nur eine Plattform).

### Tests
- [ ] Unit Tests fuer die Sampling-Logik (deterministische Bucket-Zuordnung mit synthetischen Frames, analog zu den bestehenden `WaveformAccumulator`-Tests).

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbar: Waveform laedt schneller)

---

## Manueller Test

1. Eine lange Meditation (15+ Min) in die Dev-App importieren.
2. Editor der Meditation oeffnen.
3. Erwartung: Waveform ist in wenigen Sekunden da und sieht der Aufnahme aehnlich (Sprechpausen als Taeler erkennbar).

---

## Verifikation (so wurde der Spike gemessen)

**Trigger:** Waveform wird beim Oeffnen des Editors/Players generiert (Cache-Miss). Cache liegt unter `files/waveforms/{id}.json` (run-as zugaenglich, Dev-Build `com.stillmoment.dev`). Vor jeder Messung Cache loeschen + App force-stop, dann Meditation oeffnen.

**Speed:** Generierungsdauer per Log messen (Spike nutzte ein temporaeres `PERF-SAMPLING wall=...ms`-Log; im Produktionscode entfaellt das oder wird ein dezentes `Logger`-Statement).

**Genauigkeit (objektiv, ohne Augenmass):** Die Cache-JSON enthaelt die 2200 normalisierten Werte.
1. Einmal die EXAKTE Referenz erzeugen (kurzzeitig den bestehenden `WaveformGenerationService` aktiv lassen), JSON aus dem Cache ziehen.
2. Dann mit Sampling erneut generieren (gleiche Datei/ID), JSON ziehen.
3. Beide 2200-Wert-Arrays numerisch vergleichen: mittlere absolute Abweichung + Pearson-Korrelation. Spike-Referenzwerte fuer die finale Variante: corr ~0,6, mean abs diff ~0,11 — das ist die akzeptierte Messlatte fuer "plausible UI-Waveform".

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/MediaCodecAudioFrameReader.kt` (Decode-Loop)
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/WaveformGenerationService.kt` (treibt den Loop)
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/WaveformAccumulator.kt` (Peak-Bucketing)
- iOS-Gegenstueck (aktuell exakt, schnell genug): `ios/StillMoment/Infrastructure/Services/WaveformGenerationService.swift`

---

## Hinweise

**Gemessene Ursache (2026-06-17, temporaere Instrumentierung, ~20-Min-MP3, 54M Frames, ~43s gesamt):**
- `queueInputBuffer` (Codec-Submission-Overhead): 37 %
- `dequeueInputBuffer`: 14 %
- `dequeueOutputBuffer` (reiner MP3-Decode): 19 %
- `extractor.advance()`: 5 %
- `monoSamples` + `append` (Float-Boxing): 8 % zusammen
- `readSampleData` (I/O): 1 %

**Sackgassen (bereits ausprobiert/ausgeschlossen — nicht erneut versuchen):**
- `List<Float>` → `FloatArray` (Boxing eliminieren): gebaut + gemessen → **0 Effekt** (Boxing ist nur 8 %).
- Async-MediaCodec (`setCallback`): bringt nichts, da `empty=1` (keine Poll-Wartezeit); der Kostenpunkt ist Submission-Overhead, nicht Warten.
- Batch-Input (groesserer `KEY_MAX_INPUT_SIZE`): waere exakt, kaeme aber nur auf ~20s und hat ein multi-Access-Unit-Korrektheitsrisiko beim MP3-Decoder.

**Validierte Loesung (Spike 2026-06-17, Prototyp auf Branch `feature/android-080-waveform-sampling`): kontinuierliche Dezimierung, KEIN Seek.**

Die naheliegende Seek-pro-Bar-Variante wurde gebaut und verworfen: 2200 `seekTo()`+`flush()` kosten ~16s (Seek-Overhead ersetzt nur den Submission-Overhead) bei schlechter Genauigkeit. Stattdessen:

1. Decoder einmal starten, sequentiell durch die Datei laufen.
2. Pro Sekunde nur ~4 MP3-Frames an den Decoder geben (Messrate ~4/s); die uebrigen Frames per `extractor.advance()` billig ueberspringen — **ohne** `queueInputBuffer` (das war der 37%-Kostenpunkt).
3. Beim Ueberspringen NICHT pro Frame `dequeueOutputBuffer` mit Timeout aufrufen (10ms × 42k Frames = 7 Min Falle); in enger Skip-Schleife nur `advance()`, Output nur beim Fuettern drainen (Timeout 0).
4. **Output→Input-Zuordnung selbst per FIFO-Queue der gefuetterten Timestamps** tracken: Der `c2.android.mp3.decoder` reicht die Input-`presentationTimeUs` NICHT durch, sondern nummeriert Outputs fortlaufend nach Sample-Menge — sonst landen alle Messungen in den ersten ~9% der Timeline ("Waveform nur am Anfang").
5. Peak pro Bar direkt auf dem `ShortBuffer` (kein `List<Float>`).

Resultat im Spike: ~5,7s (statt 43s), Korrelation ~0,6 zur exakten Waveform — fuer eine UI-Huellkurve ausreichend. Priming-Frames (konsekutive Vorgaenger gegen Overlap-Add-Artefakte) heben die Korrelation auf ~0,73 (1 Frame) bzw. ~0,85 (2-3 Frames), kosten aber linear mehr Zeit (~9s bzw. ~18s) — **bewusst weggelassen**, da die grobe Form genuegt.

Cache (`WaveformCacheService`) + `precompute()` nach Import existieren bereits und bleiben unveraendert. Die Architektur-Seam (`AudioFrameReader`/`WaveformGenerationServiceProtocol`) bleibt; der Sampling-Service ersetzt nur die Android-Implementierung hinter `WaveformGenerationServiceProtocol`.
