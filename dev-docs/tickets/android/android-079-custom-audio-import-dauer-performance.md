# Ticket android-079: Custom-Audio-Import langer Dateien beschleunigen

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: Performance/UX. Risiko liegt im reaktiven Nachtragen der Dauer (Liste muss sich aktualisieren, ohne die Auswahl/Wiedergabe zu stören). Vorbestehend, betrifft jeden Custom-Audio-Import (Soundscape und gefuehrte Meditationen), nicht nur den Hintergrundklang-Screen.
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der Import einer langen eigenen Audiodatei (z.B. 30 Minuten) dauert auf schwächeren Geräten (Fairphone) sehr lange (> 1 Minute), bevor die Datei in der Liste erscheint.

## Warum

Der Flaschenhals ist die Dauer-Erkennung via `MediaMetadataRetriever.setDataSource()`: Bei MP3s ohne sauberen VBR-Header scannt sie die ganze Datei, um die Spieldauer zu berechnen. Das blockiert den Import unnötig lange. Die Dauer ist nur eine sekundäre Anzeige-Information („nice to have") und sollte den Import nicht aufhalten. iOS ist nicht betroffen (nutzt `AVAudioPlayer.duration`, schnell).

---

## Akzeptanzkriterien

### Feature
- [ ] Nach Auswahl einer Datei erscheint diese **sofort** (ohne spürbare Verzögerung) in „Meine Klänge" bzw. der Meditations-Liste — auch bei einer 30-Minuten-Datei.
- [ ] Die **Spieldauer wird im Hintergrund** ermittelt und nachgetragen (die Zeile aktualisiert sich, sobald die Dauer vorliegt), ohne Auswahl oder laufende Wiedergabe zu unterbrechen.
- [ ] Schlägt die Dauer-Erkennung fehl oder dauert zu lange, bleibt die Datei trotzdem nutzbar (Dauer-Anzeige entfällt dann, kein Fehler).

### Tests
- [ ] Unit Tests für den Import-Flow (Datei sofort verfügbar; Dauer wird nachgetragen; Fallback bei fehlgeschlagener Erkennung).

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Verbesserung)

---

## Manueller Test

1. Android-App, Timer → Hintergrundklang → „Eigene Datei importieren".
2. Eine lange Datei (≈ 30 Minuten) wählen.
3. Erwartung: Die Datei erscheint sofort in der Liste; die Dauer erscheint kurz darauf. Kein minutenlanges Warten.

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/data/repositories/CustomAudioRepositoryImpl.kt` (`importFile`, `extractDuration` ~Zeile 175, `copyFileToInternalStorage`)
- iOS-Vergleich (schnell): `ios/StillMoment/Infrastructure/Services/CustomAudioRepository.swift` (`detectDuration` via `AVAudioPlayer`)

---

## Hinweise

- Aufgedeckt während shared-121 (Hintergrundklang-Redesign); dort bewusst ausgeklammert, weil vorbestehend und plattformübergreifend relevant.
- Die Datei-Kopie läuft bereits gepuffert auf `Dispatchers.IO` und ist nicht der dominante Kostenfaktor — der Scan in der Dauer-Erkennung ist es.
