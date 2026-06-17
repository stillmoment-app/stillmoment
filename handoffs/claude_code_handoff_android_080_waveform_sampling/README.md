# Handoff: android-080 — Android-Waveform-Generierung beschleunigen (Sampling)

**Auftrag:** Ticket `dev-docs/tickets/android/android-080-waveform-generierung-beschleunigen.md` sauber (produktionsreif, mit Tests) umsetzen. Dieser Handoff enthält den verifizierten Spike-Stand, damit nichts aus der Explorationsphase verloren geht.

Lies **zuerst das Ticket** — es hat WAS/WARUM, Akzeptanzkriterien, die gemessene Ursache, die verworfenen Sackgassen und die Verifikations-Methodik. Dieser Handoff ergänzt es um den **funktionierenden Prototyp-Code** und den Umsetzungsplan.

---

## Worum es geht (Kurzfassung)

Die Waveform-Generierung für lange MP3s (~20 Min) dauert auf Android ~43 s (auch auf echter Fairphone-Hardware) — der MediaCodec-Software-Decoder dekodiert die ganze Datei. iOS ist schnell (anderer Decoder). Lösung: **nur ~4 Frames pro Sekunde dekodieren** statt aller ~47k, per Input-Dezimierung. Spike-Ergebnis: **~5,7 s** (Emulator), Waveform-Korrelation ~0,6 zur exakten Form.

**Wichtige Produkt-Entscheidung (User):** Es geht um eine *plausible UI-Waveform*, nicht um sample-genaues Audio-Schneiden. corr ~0,6 ist explizit ausreichend. iOS bleibt exakt — die Form-Abweichung zwischen den Plattformen ist bewusst akzeptiert (ein User sieht nur eine Plattform).

## Der Prototyp

`SamplingWaveformGenerationService.spike.kt` (hier im Ordner) ist der **verifizierte, lauffähige** Prototyp — er lief im Spike und erzeugte die Messwerte. Er ist NICHT eingecheckt/verdrahtet. Nutze ihn als Referenz für die subtilen Stellen, die ich jeweils erst falsch hatte und durch Messen korrigierte:

1. **FIFO-Timestamp-Zuordnung** — der `c2.android.mp3.decoder` reicht die Input-`presentationTimeUs` NICHT durch, sondern nummeriert Outputs fortlaufend nach Sample-Menge. Ohne FIFO landen alle Messungen in den ersten ~9 % der Timeline ("Waveform nur am Anfang", visuell bestätigt).
2. **Output-Drain mit Timeout 0** beim Füttern — `dequeueOutputBuffer(10ms)` pro übersprungenem Frame = 10 ms × 42k = ~7 Min ("dauert ewig", real passiert).
3. **Skip per `extractor.advance()`** ohne `queueInputBuffer` — das war der 37-%-Kostenpunkt.
4. **Peak direkt auf dem `ShortBuffer`** — kein `List<Float>`-Boxing (das war ohnehin nur 8 %, aber hier gratis vermeidbar).

## Was beim Sauber-Umsetzen zu tun ist

1. **Service produktionsreif** aus dem Spike ableiten: PERF-Instrumentierung (`wallStart`, `decodedFrames`, `PERF-SAMPLING`-Log) raus bzw. durch ein dezentes `Logger`-Statement ersetzen.
2. **Edge-Case kurze Dateien:** Fester 4/s-Takt gibt bei z. B. 60 s nur 240 Messpunkte für 2200 Bars → blockig. Unterhalb einer Schwelle (z. B. wenn `dauer * rate < 2 * SAMPLE_COUNT`) voll dekodieren — der bestehende exakte `WaveformGenerationService` bleibt dafür der Pfad, oder die Sampling-Rate wird adaptiv. Kurze Dateien sind ohnehin schnell.
3. **Tests:** Der MediaCodec-Decode ist device-only (nicht unit-testbar, wie der exakte Reader → Fake im Test). Aber die **FIFO-/Bucket-Zuordnung** lohnt sich zu extrahieren und mit synthetischen (timestamp, peak)-Sequenzen zu testen (analog zu `WaveformAccumulatorTest`).
4. **DI:** Sauber hinter `WaveformGenerationServiceProtocol` in `AppModule` binden (Spike hatte das per Hack ersetzt). Architektur-Seam (`AudioFrameReader` / `WaveformGenerationServiceProtocol`) bleibt. Cache (`WaveformCacheService`) + `precompute()` nach Import bleiben unverändert.
5. **`make check`** grün halten.
6. **On-Device verifizieren** (Methodik unten + im Ticket).

## Verifikation

- **Speed:** Generierungsdauer messen (temporäres Log wie im Spike, dann entfernen).
- **Genauigkeit objektiv:** Cache-JSON (`files/waveforms/{id}.json`, 2200 Werte) der Sampling-Variante gegen eine einmalig erzeugte EXAKTE Referenz (kurzzeitig den alten Service aktiv) numerisch vergleichen — mittlere abs. Abweichung + Pearson-Korrelation. Messlatte: corr ~0,6 reicht.
- **Visuell:** Editor/Player öffnen, Waveform muss über die ganze Breite plausibel sein (Sprechpausen als Täler), nicht nur am Anfang.

## Spike-Messdaten (Trade-off-Kurve, Emulator Pixel 8, ~20-Min-MP3)

| Variante | Zeit | Korrelation |
|---|---|---|
| Exakt (Ist-Zustand) | ~43 s | 1,0 |
| Seek-pro-Bar (verworfen) | ~16 s | 0,69 |
| **Dezimierung, kein Priming (gewählt)** | **~5,7 s** | **0,60** |
| Dezimierung + 1 Priming-Frame | ~8,9 s | 0,73 |
| Dezimierung + 2–3 Priming-Frames | ~17,6 s | 0,85 |

Priming-Frames (konsekutive Vorgänger gegen MP3-Overlap-Add-Artefakte) verbessern die Genauigkeit linear teuer — **bewusst weggelassen**, da die grobe Form für die UI genügt.
