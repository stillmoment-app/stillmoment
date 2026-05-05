# Ticket shared-091: URL-Share akzeptiert Audio-URLs ohne .mp3/.m4a-Endung

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Fachliche Logik klein, aber UX-Fallback bei nicht-Audio-URLs muss sauber sein. Risiko: Downloads landen in einem Loading-Dialog, der vorher gar nicht sichtbar wurde.
**Phase**: 1-Quick Fix

---

## Was

URL-Share akzeptiert auch Audio-URLs ohne erkennbare Datei-Endung (z. B. `https://www.audiodharma.org/talks/25401/download`). Die finale Validierung erfolgt anhand des Server-Content-Types beim Download, nicht anhand der URL-Endung. Liefert der Server kein unterstuetztes Audio-Format, zeigt der Download-Dialog einen klaren Fehlerzustand statt stillem Abbruch.

## Warum

Viele Podcast-/Talk-Plattformen (audiodharma.org, Dharma Seed, vereinzelt SoundCloud-Mirrors) liefern MP3-Dateien hinter Redirect-URLs ohne Datei-Endung im Pfad. Der aktuelle Endung-only-Filter weist diese URLs stumm ab — der User teilt die URL, nichts passiert, kein Feedback. Das ist auch der primaere Use Case fuer den URL-Share: Audio aus dem Browser in die Bibliothek bekommen, ohne sich um Datei-Format-Details zu kuemmern.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Eine HTTP/HTTPS-URL ohne erkennbare Audio-Endung wird von der Share-Erkennung akzeptiert (Download-Modal oeffnet sich)
- [ ] Liefert der Server beim Download einen unterstuetzten Audio-Content-Type (audio/mpeg, audio/mp4, audio/x-m4a, application/octet-stream), wird die Datei importiert
- [ ] Liefert der Server einen nicht-unterstuetzten Content-Type (z. B. text/html), zeigt der Download-Dialog einen verstaendlichen Fehlertext und einen "Schliessen"-Pfad
- [ ] Konkrete Beispiel-URL `https://www.audiodharma.org/talks/25401/download` laesst sich erfolgreich teilen → Datei landet in der Meditations-Bibliothek
- [ ] Lokalisiert (DE + EN) — neuer Fehlertext fuer "kein Audio hinter URL"
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS — URL-Validator akzeptiert HTTP/HTTPS ohne Endung; Downloader weist nicht-Audio Content-Types ab
- [ ] Unit Tests Android — gleiche Bedingungen wie iOS

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Verhaltensaenderung)

---

## Manueller Test

1. Auf Android-Geraet im Chrome `https://www.audiodharma.org/talks/25401/download` aufrufen
2. Im Browser "Teilen → Still Moment" ausloesen
3. Erwartung: Download-Modal oeffnet sich, Fortschritt laeuft durch, Datei erscheint in der Meditations-Bibliothek
4. Gegenprobe: `https://www.example.com/` teilen → Modal oeffnet sich, scheitert mit verstaendlichem Hinweis "Hinter dieser URL liegt keine Audio-Datei" (oder Aequivalent), Schliessen-Pfad funktioniert
5. iOS-Gegenstueck: gleiche Schritte mit Safari Share Extension

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| URL ohne Endung mit Audio-Server | Modal + Import | Modal + Import |
| URL ohne Audio dahinter | Modal + Fehlertext | Modal + Fehlertext |

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/UrlAudioValidator.kt`, `infrastructure/network/UrlAudioDownloaderImpl.kt`, `MainActivity.kt` (Share-Intent-Handler)
- iOS: gleiche Logik in `ios/StillMoment/` — Share Extension / URL-Import (siehe shared-046)

---

## Hinweise

- Bei `audiodharma.org` antwortet die Original-URL mit `302 Redirect` auf eine S3-URL, die `Content-Disposition: filename="...mp3"` und `audio/mpeg` Content-Type liefert. Standard `HttpURLConnection` folgt Redirects automatisch — die existierende Content-Type-Pruefung in `UrlAudioDownloaderImpl` greift dann beim finalen GET.
- Kein vorgelagerter HEAD-Request: viele Storage-Backends (z. B. S3 hier) lehnen HEAD ab oder antworten anders als auf GET. Optimistischer Download mit Content-Type-Pruefung beim eigentlichen GET ist robuster.
- Fehlertext-Wording sollte mit dem Ton der App harmonieren — kein "ERROR 415", sondern z. B. "Hinter dieser URL liegt keine Audio-Datei" / "No audio file found at this URL".
