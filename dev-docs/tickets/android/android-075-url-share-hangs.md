# Ticket android-075: URL-Share haengt im Loading-Dialog

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Klein (1-Zeilen-Fix + Test)
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Was

Wird ein direkter MP3-Link aus Chrome via "Link teilen" → Still Moment geteilt, oeffnet sich die App, der Dialog "Meditation wird geladen" erscheint — und der Download laeuft nie zu Ende. Der Loading-Dialog bleibt fuer immer sichtbar.

## Warum

`DownloadUrlEffect` (NavGraph.kt) ruft `currentOnClearDownloadUrl()` **vor** dem Download auf. Das setzt `_pendingDownloadUrl.value = null`. Da `LaunchedEffect(downloadUrl)` den Wert als Key benutzt, wird die laufende Coroutine durch die State-Aenderung abgebrochen. `isDownloading` bleibt `true`, der Dialog bleibt sichtbar.

Self-Cancellation durch State-Mutation im selben Effect.

---

## Akzeptanzkriterien

### Bug Fix
- [ ] Geteilte MP3-URL fuehrt nach Download zur Type-Auswahl (oder zur Fehler-Meldung bei Network-Fehler)
- [ ] Loading-Dialog verschwindet zuverlaessig nach Download-Abschluss

### Tests
- [ ] Bestehende Tests laufen gruen
- [ ] Compose-Test oder Manual-Test, der den Effect-Lifecycle abdeckt (Download-Erfolg fuehrt zu erwartetem Folgezustand)

### Dokumentation
- [ ] CHANGELOG.md (Bug Fix Android)

---

## Manueller Test

1. In Chrome direkten MP3-Link oeffnen (z.B. https://zentrum-fuer-achtsamkeit.koeln/wp-content/uploads/Moment-mal-01Atem.mp3)
2. Long-Press auf den Audio-Player → "Link teilen" → Still Moment
3. App oeffnet sich → "Meditation wird geladen" → Type-Auswahl erscheint nach Download
4. Falls Network-Fehler: Error-Dialog mit Retry/Cancel

---

## Hinweise

- Eine-Zeilen-Fix: `currentOnClearDownloadUrl()` von vor dem Download auf nach dem `result.fold(...)` verschieben.
- Vorgaenger: shared-046 (Share Extension Android).
