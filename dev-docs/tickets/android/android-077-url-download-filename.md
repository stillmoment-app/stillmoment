# Ticket android-077: URL-Download — Cache-Prefix aus Filename entfernen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein (Sub-Folder + Test-Anpassung)
**Abhaengigkeiten**: android-076
**Phase**: 1-Quick Fix

---

## Was

Wenn ein MP3-Link aus dem Browser geteilt und importiert wird, heisst die Meditation in der Bibliothek `dl_1777813092239_Moment-mal-01Atem.mp3` statt einfach `Moment-mal-01Atem.mp3`. Der Cache-Prefix `dl_<timestamp>_` ist nicht fuer Endnutzer gedacht, sondern war ein Implementation-Detail des Downloaders, um Filename-Kollisionen zu vermeiden.

## Warum

Visuell unschoen, schwer zu lesen in der Bibliothek. Der Nutzer kann den Namen zwar im Edit-Sheet anpassen — aber bei einem ersten Eindruck wirkt die Importierte Datei kaputt.

---

## Akzeptanzkriterien

### Bug Fix
- [ ] `UrlAudioDownloader.download()` erzeugt eine Datei mit Originalnamen aus der URL (z.B. `Moment-mal-01Atem.mp3`)
- [ ] Mehrfache Downloads derselben URL kollidieren nicht (Sub-Folder mit Timestamp oder UUID)
- [ ] Importierte Meditation in der Bibliothek hat den sauberen Originalnamen

### Tests
- [ ] Bestehende `UrlAudioDownloaderImplTest`-Tests gruen
- [ ] Test: Filename des heruntergeladenen Files entspricht `UrlAudioValidator.extractFilename(url)`

### Dokumentation
- [ ] CHANGELOG.md (Bug Fix Android, oder Polish)

---

## Manueller Test

1. Chrome → MP3-Link → Long-Press → Link teilen → Still Moment
2. Type-Auswahl → Meditation
3. Bibliothek: importierte Datei heisst `Moment-mal-01Atem.mp3` (kein `dl_…`-Prefix)
