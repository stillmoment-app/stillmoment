# Ticket android-076: file:// URIs aus URL-Download werden beim Import abgewiesen

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Klein (Special-Case in zwei Helper-Funktionen + Tests)
**Abhaengigkeiten**: android-075 (Loading-Dialog-Hang)
**Phase**: 1-Quick Fix

---

## Was

Nach dem Hotfix android-075 erreicht der Share-Flow die Type-Auswahl. Sobald „Importieren als Meditation" gewaehlt wird, schlaegt der Import mit „Die Datei konnte nicht importiert werden" fehl. Der Download produziert eine `file://`-URI im App-Cache, die `FileOpenHandler.canHandle()` als „Unsupported format" abweist.

## Warum

`FileOpenHandler.getFileName()` und `GuidedMeditationRepositoryImpl.getFileName()` benutzen `ContentResolver.query(uri, ...)` als Quelle fuer den Filename. Seit Android 7+ liefert ContentResolver fuer `file://`-URIs `null` zurueck. Folge:
- fileName = "Unknown" → extension = "" → `canHandle()` returnt false → IMPORT_FAILED.

Logcat-Beleg:
```
UrlDownload: Downloaded 13978209 bytes ... to dl_1777813092239_Moment-mal-01Atem.mp3
FileOpen: Processing file URI: file:///data/user/0/com.stillmoment/cache/dl_1777813092239_Moment-mal-01Atem.mp3
FileOpen: Rejected file with unsupported format: file:///...
```

---

## Akzeptanzkriterien

### Bug Fix
- [ ] file://-URIs (aus dem URL-Download) durchlaufen den Import erfolgreich
- [ ] content://-URIs (Document-Picker, Share-Intent mit File) verhalten sich unveraendert
- [ ] Importierte Meditation hat den Dateinamen aus dem URI-Path

### Tests
- [ ] Neuer Unit-Test: `FileOpenHandler.canHandle()` akzeptiert file://-URI mit `.mp3`/`.m4a`-Endung
- [ ] Neuer Unit-Test: `FileOpenHandler.canHandle()` weist file://-URI mit unbekannter Endung ab
- [ ] Bestehende content://-Tests bleiben gruen

### Dokumentation
- [ ] CHANGELOG.md (Bug Fix Android)

---

## Manueller Test

1. Chrome → direkten MP3-Link aufrufen
2. Long-Press auf den Audio-Player → "Link teilen" → Still Moment
3. Loading-Dialog → Type-Auswahl → "Meditation"
4. Erwartet: Datei wird in die Bibliothek importiert, Edit-Sheet (oder gewuenschter Folge-Screen) erscheint

---

## Hinweise

- Special-Case fuer `uri.scheme == "file"`: `uri.lastPathSegment` liefert den Filename, `File(uri.path).length()` die Groesse.
- Der heruntergeladene Filename hat den Cache-Prefix `dl_<timestamp>_` — visuell unschoen, aber nicht Teil dieses Tickets (kann der User im Edit-Sheet aendern; ggf. spaeter eigenes Cleanup-Ticket).
