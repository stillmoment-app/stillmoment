# Implementierungsplan: shared-091 (iOS)

Ticket: [shared-091](../shared/shared-091-url-share-ohne-extension.md)
Erstellt: 2026-05-05

## Kurzfassung

Der bestehende iOS-Share-Flow (Share Extension → App-Group-Inbox → InboxHandler → AudioDownloadService) blockiert URLs ohne `.mp3`/`.m4a`-Endung **vor dem Download**. Der Downloader selbst prueft den Content-Type bereits korrekt und folgt Redirects automatisch. Loesung: Endung-Filter in der Share Extension auf "ist HTTP/HTTPS" lockern und den existierenden `AudioDownloadError.unsupportedContentType` als eigenen Inbox-Fehlerfall mit klarer Meldung an den User durchreichen.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMomentShareExtension/ShareViewController.swift` | Share Extension | Aendern | `handleURLAttachment` (Z. 106–141): Endung-Filter durch HTTP/HTTPS-Pruefung ersetzen |
| `ios/StillMoment/Application/InboxHandler.swift` | Application | Aendern | `processURLReference` (Z. 239–270): `AudioDownloadError.unsupportedContentType` separat fangen und als neuer `InboxError.notAnAudioUrl` setzen |
| `ios/StillMoment/Application/InboxHandler.swift` | Application | Erweitern | `InboxError`-Enum (Z. 30–54) um Case `notAnAudioUrl` mit eigener `errorDescription` |
| `ios/StillMoment/StillMomentApp.swift` | Presentation | Aendern | Alert-Block (Z. 195–211): Title/Message dynamisch aus dem konkreten `InboxError`-Case ableiten; Retry nur bei wiederholbaren Fehlern (downloadFailed), nicht bei `notAnAudioUrl` |
| `ios/StillMoment/Resources/de.lproj/Localizable.strings` | Resources | Erweitern | Neue Keys `share.download.error.not_audio.title` ("Keine Aufnahme gefunden") + `share.download.error.not_audio.message` ("Wir konnten unter diesem Link keine Aufnahme finden.") |
| `ios/StillMoment/Resources/en.lproj/Localizable.strings` | Resources | Erweitern | Gleiche Keys auf Englisch ("No recording found" / "We couldn't find a recording at this link.") |
| `ios/StillMomentTests/Application/InboxHandlerTests.swift` | Tests | Erweitern | Test fuer URL-Reference die mit `unsupportedContentType` scheitert → erwartet `InboxError.notAnAudioUrl` |
| `ios/StillMomentTests/Infrastructure/AudioDownloadServiceTests.swift` | Tests | Erweitern | Test fuer Download von URL ohne Endung mit Audio-Content-Type → erfolgreich |
| `ios/StillMomentTests/Mocks/MockAudioDownloadService.swift` | Tests | Pruefen | ggf. neuen Fehler-Pfad ergaenzen |

**Kein Handlungsbedarf:**
- `AudioDownloadService.swift` Content-Type-Pruefung (Z. 52–57) ist bereits korrekt: akzeptiert `audio/*` + `application/octet-stream`, wirft sonst `unsupportedContentType`. URLSession folgt 30x-Redirects automatisch — der konkrete `audiodharma.org`-Fall (302 → S3-MP3) funktioniert dadurch out-of-the-box.
- `AudioDownloadError`-Enum (Domain/Models/AudioDownloadError.swift) ist bereits vollstaendig.
- ShareExtension-Inbox-Schreibung (`writeURLReferenceToInbox`) ist filename-agnostisch.

## API-Recherche

- **`URLSession.data(for:)`** — folgt Redirects per Default (`URLSessionConfiguration.httpShouldUsePipelining` u. a. relevant). 302 → S3 funktioniert ohne Konfiguration. Verifiziert in der Apple-Doku zu `URLSessionConfiguration` (Field `httpMaximumConnectionsPerHost` etc.).
- **`URL.scheme`** — geeignet fuer "ist das HTTP/HTTPS?" Check (`scheme?.lowercased() == "http" || == "https"`).
- **NSItemProvider `loadItem(forTypeIdentifier:)`** — liefert `URL` fuer `public.url`-Konformitaet zuverlaessig (bestehender Code).

## Design-Entscheidungen

### 1. Kein vorgelagerter HEAD-Request

**Trade-off:** HEAD-Request waere "ehrlicher" (man weiss vorher, ob Audio dahinter liegt), erzeugt aber Probleme: viele Storage-Backends (z. B. S3 bei audiodharma.org) lehnen HEAD mit 403 ab oder verhalten sich anders als bei GET. Zusaetzlicher Roundtrip + zusaetzlicher Failure-Pfad.

**Entscheidung:** Optimistischer GET. Die existierende Content-Type-Pruefung im Downloader ist die Single Source of Truth. UX-Tradeoff: Bei nicht-Audio-URLs sieht der User kurz das Download-Modal, dann den Fehler — kein silent-fail wie heute. Das ist ehrlicher und fuehrt den User klar.

### 2. Eigener Inbox-Error-Case `notAnAudioUrl` statt generisches `downloadFailed`

**Trade-off:** Ein einziger generischer Fehler ist einfacher, mischt aber zwei sehr unterschiedliche User-Situationen — "Netzwerk schlaegt fehl, retry hilft" vs. "URL ist falsch, retry hilft nichts".

**Entscheidung:** Eigener Case mit eigener Meldung und ohne Retry-Button. Der bestehende Alert-Block erlaubt schon zwei Buttons (Retry + Cancel); fuer `notAnAudioUrl` zeigen wir nur "Schliessen".

### 3. Share Extension haelt Filter auf "HTTP/HTTPS" — nicht auf "irgendeine URL"

**Trade-off:** Komplettes Entfernen waere maximal liberal, fuehrt aber zu Aufrufen mit `file://`-, `mailto:`- oder Custom-Scheme-URLs, die der Downloader nicht behandeln kann.

**Entscheidung:** Nur HTTP/HTTPS akzeptieren — alles andere weiterhin still schliessen. Das ist die ehrlichste Untergrenze: alles was im Downloader theoretisch funktionieren kann, kommt durch.

## Refactorings

Keine. Alle Aenderungen sind additiv (neuer Enum-Case, neuer Filter, neue Strings).

## Fachliche Szenarien

### AK-1: URL ohne Audio-Endung wird akzeptiert

- Gegeben: User teilt `https://www.audiodharma.org/talks/25401/download` aus Safari an Still Moment
  Wenn: Share Extension verarbeitet die URL
  Dann: JSON-Reference wird in den App-Group-Inbox geschrieben, Alert "Saved to Still Moment" erscheint

### AK-2: Server liefert Audio-Content-Type → Import erfolgreich

- Gegeben: JSON-Reference fuer `https://www.audiodharma.org/talks/25401/download` im Inbox, Server liefert nach Redirect `audio/mpeg`
  Wenn: Haupt-App wird aktiv, `InboxHandler.processInbox()` laeuft
  Dann: `AudioDownloadService.download(...)` liefert eine lokale Datei-URL, `FileOpenHandler.prepareImport(url:)` wird gerufen, Import-Typ-Auswahl erscheint

### AK-3: Server liefert kein Audio → klarer Fehler

- Gegeben: JSON-Reference fuer `https://www.example.com/` im Inbox, Server liefert `text/html`
  Wenn: Haupt-App verarbeitet die Reference
  Dann: `AudioDownloadService` wirft `unsupportedContentType`, `InboxHandler` setzt `downloadError = .notAnAudioUrl`, Alert mit Title "Keine Aufnahme gefunden" und Message "Wir konnten unter diesem Link keine Aufnahme finden." erscheint, einziger Button "Schliessen"

### AK-4: Nicht-HTTP(S)-URL wird stumm verworfen

- Gegeben: User teilt `mailto:foo@bar` oder `file:///tmp/x.mp3` an Still Moment
  Wenn: Share Extension verarbeitet die URL
  Dann: ShareViewController schliesst still per `completeRequest()`, kein Inbox-Eintrag, kein Alert

### AK-5: Netzwerk-Fehler weiterhin retry-bar

- Gegeben: JSON-Reference im Inbox, Geraet ist offline
  Wenn: Haupt-App verarbeitet die Reference
  Dann: `AudioDownloadService` wirft `networkError`, `InboxHandler` setzt `downloadError = .downloadFailed`, Alert mit Retry- und Cancel-Button erscheint (bestehendes Verhalten)

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **AudioDownloadService-Test fuer URL ohne Endung** — Sanity-Check, dass der Downloader bereits funktioniert. Wenn ja, kein Code-Change im Downloader noetig.
2. **AK-3: `InboxError.notAnAudioUrl` einfuehren + Mapping** — Pure Application-Layer-Aenderung, gut isoliert testbar.
3. **AK-1 + AK-4: Share-Extension-Filter aendern** — Manueller Test (Share Extension hat keine Unit Tests; Verhalten ist trivial).
4. **AK-3 (Presentation): Alert-Block auf Error-Case-Differenzierung umbauen** — UI-seitige Aenderung; manuell + ggf. Snapshot.
5. **AK-2 + AK-5: Integrations-Test** — manueller Smoke-Test mit der echten audiodharma-URL und einer nicht-Audio-URL.

## Hinweise

- **Cross-Platform-Konsistenz**: Die Android-Seite muss die gleiche Differenzierung vornehmen — siehe `shared-091-android.md`. Fehlertexte sollten zwischen iOS und Android wortgleich (modulo Plattform-Idiomen) sein.
- **Lokalisierungs-Test**: `make check` laeuft Localization-Linting; vor Commit sicherstellen, dass beide Sprachen die neuen Keys haben.
- **Review-Hinweis**: Der `AudioDownloadError.unsupportedContentType`-Pfad existiert seit shared-046, war aber bisher tot, weil die Share Extension URLs vor dem Download filterte. Nach dieser Aenderung wird er real erreichbar — Tests fuer diesen Pfad sind ein "shouldn't-have-been-untested"-Cleanup.

## Offene Fragen

Keine.
