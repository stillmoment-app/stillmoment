# Plan shared-131 (Android): Gleiche Audio-Dateitypen beim Link- und Podcast-Import

Ticket: `dev-docs/tickets/shared/shared-131-gleiche-audio-dateitypen-beim-link-import.md`

## Befund

`UrlAudioDownloaderImpl.download()` prueft den Content-Type bereits nach der Server-Antwort und
vor `connection.inputStream` (Body), normalisiert per `substringBefore(";").trim().lowercase()`,
vergleicht exakt (kein Praefix-Match) und nimmt fehlenden Content-Type an. Link-Import und
Podcast-Import (`LinkImportHandler`) nutzen denselben Downloader; das Mapping
`NotAudio` → `LinkImportFailure.NotAudio` (Link) bzw. → `EpisodeUnavailable` (Podcast) existiert.

Es fehlen nur `audio/x-mpeg` und `audio/mpeg3` in der Annahme-Liste.

## Relevante Dateien

| Datei | Layer | Warum |
|---|---|---|
| `infrastructure/network/UrlAudioDownloaderImpl.kt` | Infrastructure | Annahme-Liste |
| `data/LinkImportHandler.kt` | Data | Fehler-Mapping je Importweg (unveraendert) |
| `test/.../UrlAudioDownloaderTest.kt` | Test | Annahme/Ablehnung je Typ |
| `test/.../data/LinkImportContentTypeTest.kt` (neu) | Test | Beide Importwege mit echtem Downloader |

## Ansatz

Ergaenzen, kein Refactoring. Liste um zwei Typen erweitern, Kommentar anpassen.

## Tests (fachlich)

Downloader:
- MP3 mit `audio/x-mpeg` / `audio/mpeg3` wird angenommen (Red vor der Aenderung)
- `AUDIO/MPEG; charset=…` wird angenommen
- Ogg (`audio/ogg`) wird abgelehnt, ohne den Inhalt zu laden
- Wiedergabelisten `audio/mpegurl`, `audio/x-mpegurl` werden abgelehnt

Importwege (echter Downloader, gemockte Verbindung):
- Link mit `audio/ogg` → Meldung „kein Audio"; Podcast-Folge mit `audio/ogg` → „Folge nicht verfuegbar"
- Podcast-Folge mit `audio/x-mpeg` wird importiert
- Wiedergabeliste beim Podcast-Import → „Folge nicht verfuegbar"

Abbrechen und lange Folgen: bestehende Tests bleiben unveraendert gruen.

## Annahmen

- Keine neuen Texte, keine UI-Aenderung.
