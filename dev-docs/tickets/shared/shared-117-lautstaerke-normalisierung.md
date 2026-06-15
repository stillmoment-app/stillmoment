# Ticket shared-117: Lautstärke-Normalisierung gefuehrter Meditationen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Audio-Analyse (wahrgenommene Lautstaerke korrekt messen) + plattform-spezifische Gain-Anwendung beim Playback. Risiko liegt in der Mess-Methodik (Stille/Leise-Phasen duerfen nicht verzerren) und im clipping-sicheren Anheben leiser Aufnahmen.
**Phase**: 3-Feature

---

## Was

Importierte gefuehrte Meditationen sollen automatisch auf eine einheitliche, angenehme Lautstaerke gebracht werden — leise Aufnahmen werden angehoben, laute abgesenkt. Lange Stille-Phasen, leise Musik-Betten und sanftes Ausklingen am Ende duerfen die Lautstaerke-Bestimmung **nicht** verfaelschen.

## Warum

Die persoenliche Sammlung besteht aus MP3s unterschiedlichster Quellen mit stark schwankenden Pegeln. Der User muss heute bei jedem Wechsel der Aufnahme die Geraete-Lautstaerke nachregeln — das stoert die Stille und widerspricht dem "Handy weglegen"-Use-Case. Eine gleichmaessige Lautstaerke laesst die Sammlung wie aus einem Guss wirken.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | Waveform-Infrastruktur (iOS-Vorsprung) |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Nach dem Import wird pro Meditation ein Lautstaerke-Korrekturwert bestimmt und persistiert (einmalige Analyse, nicht bei jedem Playback)
- [ ] Beim Abspielen klingen unterschiedlich laut aufgenommene Meditationen aehnlich laut, ohne dass der User die Geraete-Lautstaerke nachregeln muss
- [ ] Eine Meditation mit langen Stille-Phasen oder leisem Ausklingen wird nach dem Pegel der gesprochenen Stimme normalisiert — nicht kuenstlich hochgezogen, weil grosse Teile leise sind
- [ ] Das Anheben leiser Aufnahmen erzeugt keine hoerbaren Verzerrungen/Clipping (clipping-sichere Begrenzung)
- [ ] Bestehende, bereits importierte Meditationen erhalten ihren Korrekturwert nachtraeglich (Migration oder Lazy-Berechnung beim ersten Oeffnen/Abspielen)
- [ ] Visuell/akustisch konsistentes Verhalten zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS: Korrekturwert-Berechnung gibt fuer eine laute Test-Aufnahme einen daempfenden, fuer eine leise einen anhebenden Wert; eine Aufnahme mit grossem Stille-Anteil ergibt denselben Wert wie ohne die Stille
- [ ] Unit Tests Android: identische Faelle

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Aenderung)
- [ ] GLOSSARY.md (Begriff "Lautstaerke-Normalisierung" / LUFS, falls als Domain-Begriff gefuehrt)

---

## Manueller Test

1. Zwei MP3s importieren: eine sehr leise, eine sehr laute Aufnahme.
2. Beide nacheinander abspielen, ohne die Geraete-Lautstaerke zu aendern.
3. Erwartung: Beide klingen aehnlich laut.
4. Eine Meditation importieren, die zur Haelfte aus Stille / leisem Ausklingen besteht.
5. Erwartung: Sie wird nicht uebermaessig laut — die Normalisierung richtet sich nach der gesprochenen Stimme, nicht nach dem Stille-Anteil.

---

## Referenz

- iOS: `ios/StillMoment/Infrastructure/Services/WaveformGenerationService.swift` (dekodiert bereits chunk-weise alle Samples — natuerlicher Ort fuer die Loudness-Messung im selben Durchlauf), `WaveformProvider.swift`, `AudioPlayerService.swift` (Playback), `Domain/Models/GuidedMeditation.swift` (Datenmodell), `WaveformAccumulator.swift` (liefert bereits den globalen Peak)
- Android: `android/app/src/main/kotlin/com/stillmoment/` — analoge Waveform-/Player-Services

---

## Hinweise

**Mess-Methodik — hier loest sich die Stille-Anforderung von selbst:**
Wahrgenommene Lautstaerke wird in **LUFS** gemessen (Standard **EBU R128 / ITU-R BS.1770**) — nicht ueber Peak-Amplituden (die aktuelle Waveform liefert nur Peak und ist dafuer nicht geeignet). Der Standard hat ein eingebautes **Gating**, das genau das gewuenschte Verhalten erzeugt:
- Absolutes Gate bei −70 LUFS → echte Stille faellt aus der Messung.
- Relatives Gate bei −10 LU unter dem ungaten Mittel → leise Musik-Betten, Pausen, sanftes Ausklingen werden ignoriert.
Das ist kein Workaround, sondern der Normalfall des Standards. Verfuegbare Bibliotheken/OS-APIs pruefen, bevor selbst implementiert wird.

**Zielwert:** Fuer ruhige Sprachinhalte ist ein leiser Zielwert (Richtung −16 bis −18 LUFS, vgl. Apple Podcasts −16) erwuenscht — kein "Radio-laut"-Effekt.

**Gain-Berechnung & Clipping:** `gain_dB = ziel_LUFS − gemessene_LUFS`. Beim Anheben darf ein einzelner lauter Peak (Huster, Tuer) nicht ueber 0 dBFS getrieben werden → Gain gegen den verfuegbaren Headroom deckeln. Der globale Peak wird bei der Waveform-Berechnung bereits ermittelt und kann dafuer wiederverwendet werden: `sicherer_gain = min(loudness_gain, headroom_bis_0dBFS)`.

**Playback-Integration (plattform-spezifisch):**
- iOS: `AVPlayer.volume` kann nur daempfen (0.0–1.0), **nicht** verstärken. Fuer echtes Anheben (Gain > 1.0) ist eine `AVAudioMix` (`AVAudioMixInputParameters`) auf dem `AVPlayerItem` oder eine `AVAudioEngine`-Stufe noetig.
- Android: ExoPlayer/MediaPlayer-Volume verhaelt sich analog — Boost ueber Audio-Processing-Stufe pruefen.

**Scope-Abgrenzung:** Die visuelle Waveform-Normalisierung (alle Buckets auf gleiche Hoehe skaliert) ist ein eigenstaendiger Concern und bleibt unveraendert. Dieses Ticket betrifft nur die hoerbare Lautstaerke.

**Kein UI-Schalter im ersten Wurf** (Less is more): Normalisierung laeuft automatisch. Ein Opt-out-Toggle ist bewusst nicht Teil dieses Tickets — nur ergaenzen, wenn sich im Test ein echter Bedarf zeigt.
