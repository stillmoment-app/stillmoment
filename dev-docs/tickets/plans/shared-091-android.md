# Implementierungsplan: shared-091 (Android)

Ticket: [shared-091](../shared/shared-091-url-share-ohne-extension.md)
Erstellt: 2026-05-05

## Kurzfassung

Aktuell blockiert `UrlAudioValidator.isAudioUrl` URLs ohne `.mp3`/`.m4a`-Endung in `MainActivity.handleTextShareIntent` — der Download-Modal oeffnet sich erst gar nicht. Loesung: Validator auf "ist HTTP/HTTPS" lockern, im Downloader Content-Disposition-Header fuer den Filename heranziehen (Fallback: aus Content-Type ableiten) und den existierenden Fehlerdialog um eine zweite Variante "kein Audio dahinter" ohne Retry-Button erweitern.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `domain/models/UrlAudioValidator.kt` | Domain | Aendern | `isAudioUrl`: nur noch HTTP/HTTPS-Schema-Check; Endung-Filter entfaellt. `extractFilename`: erweitern um Audio-Endung-Erkennung (sonst Fallback auf `audio.mp3`) |
| `domain/models/UrlAudioDownloadError.kt` | Domain | **Neu** | Sealed class mit Cases `NotAudio`, `Network`, `Http(code)`, `Cancelled`. Bisher waren Fehler generische `Exception`s |
| `domain/services/UrlAudioDownloaderProtocol.kt` | Domain | Aendern | `download(...)` Rueckgabewert statt `Result<Uri>` → `Result<Uri>` mit typisierten Failure-Throwables aus `UrlAudioDownloadError` |
| `infrastructure/network/UrlAudioDownloaderImpl.kt` | Infrastructure | Aendern | (1) Bei nicht-supported Content-Type → `Result.failure(NotAudio)`. (2) Filename aus `Content-Disposition: filename=...` parsen, dann URL-Pfad, dann Content-Type-basierter Fallback |
| `MainActivity.kt` | Presentation | Aendern | `handleTextShareIntent` (Z. 149–155): Pruefung bleibt `UrlAudioValidator.isAudioUrl`, Logik in Validator selbst veraendert sich |
| `presentation/navigation/NavGraph.kt` | Presentation | Aendern | `DownloadUrlEffect` (Z. 649–697) + `DownloadErrorDialog` (Z. 700ff): zweistufige Fehler-UI — `NotAudio` zeigt eigenen Dialog ohne Retry, alle anderen Fehler verhalten sich wie heute |
| `res/values/strings.xml` | Resources | Erweitern | Neue Keys: `download_error_not_audio_title` ("No recording found"), `download_error_not_audio_message` ("We couldn't find a recording at this link."), `download_error_close` ("Close") |
| `res/values-de/strings.xml` | Resources | Erweitern | Gleiche Keys auf Deutsch: "Keine Aufnahme gefunden" / "Wir konnten unter diesem Link keine Aufnahme finden." / "Schliessen" |
| `test/.../UrlAudioValidatorTest.kt` | Tests | Erweitern | Tests fuer "HTTP/HTTPS ohne Endung wird akzeptiert", "non-HTTP weiter abgewiesen". Bestehende Endung-Tests werden teilweise gegenstandslos (URL ohne Endung war "false" — jetzt "true"); umformulieren statt ersatzlos streichen |
| `test/.../UrlAudioDownloaderTest.kt` | Tests | Erweitern | Tests fuer Content-Disposition-Filename, Content-Type-Fallback-Filename, `NotAudio`-Fehlertyp |

**Kein Handlungsbedarf:**
- HTTPS-Redirect-Verhalten: `HttpURLConnection.instanceFollowRedirects` ist per Default `true` — `audiodharma.org` 302 → S3 wird ohne Konfigurationsaenderung gefolgt.
- Inbox/JSON-Logik wie auf iOS gibt es auf Android nicht: Download laeuft direkt aus `LaunchedEffect` heraus.

## API-Recherche

- **`HttpURLConnection.instanceFollowRedirects`** — Default `true` (per Apple-aequivalenter Android-Doku). 302 → S3 funktioniert ohne expliziten Code.
- **`Content-Disposition`-Header** — RFC 6266. Format: `attachment; filename="foo.mp3"` oder `attachment; filename*=UTF-8''foo.mp3`. Beim audiodharma-Beispiel beide Varianten gesetzt. Es gibt kein Java-/Android-Built-in-Parser; einfache Regex auf `filename="..."` reicht fuer den Use-Case (RFC-konformes UTF-8-Decoding ist Optional). Vorhandene Lib `okhttp` parst das nicht out-of-the-box; eigener Parser ist <20 Zeilen.
- **`HttpURLConnection.getHeaderField("Content-Disposition")`** — verfuegbar ab API 1, kein Risiko fuer `minSdk = 26`.

## Design-Entscheidungen

### 1. Sealed Class `UrlAudioDownloadError` statt generische `Exception`-Strings

**Trade-off:** Bisher liefert `Result.failure(Exception("Unsupported content type: $contentType"))` einen String, den die UI nicht differenziert. Ein Sealed-Type-Refactoring beruehrt Protocol, Impl und Tests.

**Entscheidung:** Sealed class einfuehren. Andernfalls muesste die UI-Schicht Strings parsen oder `instanceof IOException`-Heuristiken verwenden — Anti-Pattern. Domain-Layer-Regeln (`android/CLAUDE.md`) fordern explizit "Sealed Classes for Type Safety" fuer State Machines und Union Types; Fehlerfaelle gehoeren dazu.

### 2. Content-Disposition vor URL-Pfad-Filename

**Trade-off:** Der URL-Pfad-Filename ist heute schon implementiert und einfach. Content-Disposition zu parsen ist Mehraufwand.

**Entscheidung:** Content-Disposition gewinnt, wenn vorhanden. Begruendung: Bei `audiodharma.org/talks/25401/download` ist der Pfad-Filename `download` — voellig inhaltsleer. Der Server liefert dagegen `filename="20260504-David_Lorey-IMC-guided_meditation_all_of_us.mp3"` — exakt der Name, den der User in der Library sehen will. Reihenfolge: (1) Content-Disposition, (2) URL-Pfad mit Audio-Endung, (3) Fallback `audio.mp3` (oder `audio.m4a` bei `audio/mp4`).

### 3. UI-Differenzierung: zwei Dialoge statt ein Dialog mit dynamischem Text

**Trade-off:** Ein Dialog mit Switch waere weniger Code. Zwei Dialoge sind klarer.

**Entscheidung:** Im `DownloadErrorDialog` zwischen `NotAudio` (kein Retry, nur "Schliessen") und allen anderen (Retry + Cancel) unterscheiden. Bei `NotAudio` ist Retry sinnlos — die URL aendert sich nicht.

## Refactorings

### 1. `UrlAudioDownloadError` Sealed Class einfuehren

- Risiko: Niedrig. Betrifft Protocol-Signatur (`Result<Uri>` bleibt, nur die `Throwable` im Failure wird typisiert), Impl, NavGraph (Error-Branch), Tests.
- Alternative: Nicht refactoren, in `NavGraph` per `Throwable.message`-Matching arbeiten — abgelehnt (siehe Design-Entscheidung 1).

### 2. Bestehende `UrlAudioValidator`-Tests umformulieren

- Risiko: Niedrig. Mehrere Tests pruefen heute, dass URLs **ohne** Audio-Endung **abgelehnt** werden. Nach der Aenderung werden sie akzeptiert. Die Tests werden zu "Kontrakt-Tests" fuer die neue Semantik umgeschrieben — nicht ersatzlos geloescht.

## Fachliche Szenarien

### AK-1: URL ohne Audio-Endung wird akzeptiert

- Gegeben: User teilt `https://www.audiodharma.org/talks/25401/download` aus Chrome an Still Moment
  Wenn: `MainActivity.handleTextShareIntent` verarbeitet das ACTION_SEND
  Dann: `pendingDownloadUrl` wird gesetzt, `DownloadUrlEffect` zeigt das `DownloadProgressModal`

### AK-2: Server liefert Audio Content-Type → Import erfolgreich, sinnvoller Filename

- Gegeben: `pendingDownloadUrl = "https://www.audiodharma.org/talks/25401/download"`, Server antwortet mit 302 → S3 (audio/mpeg, `Content-Disposition: filename="20260504-David_Lorey-IMC-guided_meditation_all_of_us.mp3"`)
  Wenn: `UrlAudioDownloaderImpl.download(url)` laeuft
  Dann: Datei landet in `cacheDir/dl_<ts>/20260504-David_Lorey-IMC-guided_meditation_all_of_us.mp3`, `onDownloadSuccess(uri)` wird gerufen

### AK-3: Server liefert kein Audio → klarer Dialog ohne Retry

- Gegeben: `pendingDownloadUrl = "https://www.example.com/"`, Server antwortet mit `text/html`
  Wenn: Download laeuft
  Dann: `Result.failure(UrlAudioDownloadError.NotAudio)`, `DownloadErrorDialog` erscheint mit Title "Keine Aufnahme gefunden" und Message "Wir konnten unter diesem Link keine Aufnahme finden.", einziger Button "Schliessen"

### AK-4: Netzwerk-Fehler weiterhin retry-bar

- Gegeben: `pendingDownloadUrl = "https://example.org/audio.mp3"`, Geraet ist offline
  Wenn: Download laeuft
  Dann: `Result.failure(UrlAudioDownloadError.Network)`, `DownloadErrorDialog` erscheint mit bisherigem Text und Retry+Cancel-Buttons

### AK-5: Filename-Fallback ohne Content-Disposition

- Gegeben: URL ohne Endung, Server liefert `audio/mpeg` ohne Content-Disposition
  Wenn: Download laeuft
  Dann: Datei wird unter `audio.mp3` abgelegt

### AK-6: Cancellation weiterhin still

- Gegeben: User tippt waehrend des Downloads auf Cancel im Modal
  Wenn: `urlAudioDownloader.cancel()` wird gerufen
  Dann: `Result.failure(CancellationException)`, kein Fehlerdialog (bestehendes Verhalten bleibt)

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **`UrlAudioDownloadError` Sealed Class + Protocol-Signatur** — pure Domain-Aenderung. Tests rein domainseitig.
2. **AK-3 + AK-4: `UrlAudioDownloaderImpl` mappt auf typisierte Errors** — Impl-Test. `NotAudio` wird gefeuert wenn Content-Type nicht passt.
3. **AK-5: Filename-Fallback** — Test: Content-Disposition vorhanden vs. Fehlt vs. URL-Pfad mit Endung vs. ueberhaupt nichts.
4. **AK-1: `UrlAudioValidator.isAudioUrl` lockern** — Trivialer Domain-Test.
5. **AK-2 + AK-3 + AK-4 + AK-6 (UI): `DownloadErrorDialog` differenzieren** — manueller Test im Emulator (Compose-Composables haben oft keinen Unit-Test-Coverage).
6. **End-to-End manuell** mit der echten audiodharma-URL und einer beliebigen Webseiten-URL.

## Hinweise

- **Cross-Platform-Konsistenz**: Fehlertexte abstimmen mit iOS-Plan (`shared-091-ios.md`). DE/EN-Wording sollte zwischen Plattformen identisch sein.
- **detekt**: `DownloadErrorDialog` koennte `LongMethod` (60 Zeilen) ueberschreiten, wenn beide Dialog-Varianten direkt eingebaut werden. Praeventiv in zwei separate Composables splitten (z. B. `NotAudioErrorDialog`, `RetryableErrorDialog`).
- **Backward-Compat**: Bestehende JSON-Inbox-Eintraege (gibt es auf Android nicht) sind irrelevant. Pending-URLs werden nicht persistiert — nichts in DataStore zu migrieren.

## Offene Fragen

- [ ] Soll der Filename-Fallback `audio.mp3` lokalisiert werden (DE: `Audio.mp3`)? Nein-Empfehlung: Filenames bleiben sprachneutral, der User benennt im Edit-Sheet sowieso um.
