# Implementierungsplan: shared-091 (iOS)

Ticket: [shared-091](../shared/shared-091-url-share-ohne-extension.md)
Erstellt: 2026-05-05

## Kurzfassung

Der bestehende iOS-Share-Flow (Share Extension → App-Group-Inbox → InboxHandler → AudioDownloadService → FileOpenHandler) blockiert URLs ohne `.mp3`/`.m4a`-Endung **vor dem Download**. Der Downloader selbst prueft den Content-Type bereits korrekt und folgt Redirects automatisch. Loesung in drei Schichten:

1. **Share Extension**: Endung-Filter auf "ist HTTP/HTTPS" lockern.
2. **AudioDownloadService**: Filename/Extension nicht mehr nur aus `URLReference.filename` ziehen. Reihenfolge fuer Filename: (1) `Content-Disposition: filename=...`-Header, (2) URL-Pfad falls Endung vorhanden, (3) Fallback `audio.mp3` / `audio.m4a` aus Content-Type. Damit hat die Datei beim Speichern immer eine Endung, die `FileOpenHandler.canHandle` akzeptiert.
3. **InboxHandler**: Bestehenden `AudioDownloadError.unsupportedContentType` als eigenen `InboxError.notAnAudioUrl` durchreichen — und **defensive Pruefung**, dass `FileOpenHandler.prepareImport` den Import wirklich angenommen hat (sonst silent fail). Faellt das Result negativ aus, ebenfalls `notAnAudioUrl` melden — kein silent fail-Pfad zwischen "Download gelang" und Import-Sheet.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMomentShareExtension/ShareViewController.swift` | Share Extension | Aendern | `handleURLAttachment` (Z. 106–141): Endung-Filter durch HTTP/HTTPS-Pruefung ersetzen |
| `ios/StillMoment/Infrastructure/Services/AudioDownloadService.swift` | Infrastructure | **Aendern** | `download(from:filename:)` (Z. 28–72): Filename-Ableitung erweitern. Wenn `filename`-Parameter keine Audio-Endung hat, in dieser Reihenfolge probieren: (1) `Content-Disposition: filename=...` parsen (regex auf `filename="..."` und `filename*=UTF-8''...`), (2) bestehenden `filename`-Parameter falls Endung dort vorhanden, (3) Fallback `audio.mp3` (Content-Type `audio/mpeg` + `application/octet-stream`) bzw. `audio.m4a` (Content-Type `audio/mp4`/`audio/x-m4a`/`audio/m4a`). Resultat: gespeicherte Datei hat **immer** eine Endung in `["mp3", "m4a"]`. |
| `ios/StillMoment/Application/InboxHandler.swift` | Application | Aendern | `processURLReference` (Z. 239–270): (1) `AudioDownloadError.unsupportedContentType` separat fangen und als neuer `InboxError.notAnAudioUrl` setzen. (2) **Defense-in-Depth:** Nach `prepareImport(url:)` pruefen, ob `fileOpenHandler.showImportTypeSelection == true` und `pendingImportURL != nil`. Wenn nein (Datei wurde vom Importer abgewiesen), `downloadError = .notAnAudioUrl` setzen und `.error(.notAnAudioUrl)` zurueckgeben. |
| `ios/StillMoment/Application/InboxHandler.swift` | Application | Erweitern | `InboxError`-Enum (Z. 30–54) um Case `notAnAudioUrl` mit eigener `errorDescription` |
| `ios/StillMoment/StillMomentApp.swift` | Presentation | Aendern | Alert-Block (Z. 195–211): Title/Message dynamisch aus dem konkreten `InboxError`-Case ableiten; Retry nur bei wiederholbaren Fehlern (downloadFailed), nicht bei `notAnAudioUrl` |
| `ios/StillMoment/Resources/de.lproj/Localizable.strings` | Resources | Erweitern | Neue Keys `share.download.error.not_audio.title` ("Keine Aufnahme gefunden") + `share.download.error.not_audio.message` ("Wir konnten unter diesem Link keine Aufnahme finden.") |
| `ios/StillMoment/Resources/en.lproj/Localizable.strings` | Resources | Erweitern | Gleiche Keys auf Englisch ("No recording found" / "We couldn't find a recording at this link.") |
| `ios/StillMomentTests/Application/InboxHandlerTests.swift` | Tests | Erweitern | (1) Test fuer URL-Reference die mit `unsupportedContentType` scheitert → erwartet `InboxError.notAnAudioUrl`. (2) Test: Mock liefert Datei ohne `.mp3`/`.m4a`-Endung → InboxHandler setzt `downloadError = .notAnAudioUrl` (Defense-in-Depth-Pfad). |
| `ios/StillMomentTests/Infrastructure/AudioDownloadServiceTests.swift` | Tests | Erweitern | (1) Download URL ohne Endung + `audio/mpeg` Content-Type → Datei hat `.mp3`-Endung. (2) Download URL ohne Endung + `Content-Disposition: filename="real.mp3"` → Datei heisst `real.mp3`. (3) Download URL ohne Endung + `application/octet-stream` ohne Content-Disposition → Datei hat `.mp3`-Endung (Fallback). (4) Download URL ohne Endung + `audio/mp4` → `.m4a`. |
| `ios/StillMomentTests/Mocks/MockAudioDownloadService.swift` | Tests | Pruefen | ggf. neuen Fehler-Pfad ergaenzen; zusaetzlich Mock muss eine real existierende Datei mit konfigurierbarer Endung zurueckgeben koennen, damit der Defense-in-Depth-Pfad testbar ist |

**Kein Handlungsbedarf:**
- `AudioDownloadService.swift` Content-Type-**Filter** (Z. 52–57) ist bereits korrekt: akzeptiert `audio/*` + `application/octet-stream`, wirft sonst `unsupportedContentType`. URLSession folgt 30x-Redirects automatisch — der konkrete `audiodharma.org`-Fall (302 → S3-MP3) funktioniert dadurch out-of-the-box.
- `AudioDownloadError`-Enum (Domain/Models/AudioDownloadError.swift) ist bereits vollstaendig.
- ShareExtension-Inbox-Schreibung (`writeURLReferenceToInbox`) ist filename-agnostisch.
- `FileOpenHandler.canHandle` / `prepareImport` (Z. 119–223) bleiben unveraendert: die Korrektur erfolgt upstream in `AudioDownloadService`. `prepareImport` aendert keine Signatur — die Defense-in-Depth-Pruefung in `InboxHandler` liest die `@Published` Properties (`showImportTypeSelection`, `pendingImportURL`).

## API-Recherche

- **`URLSession.data(for:)`** — folgt Redirects per Default. 302 → S3 funktioniert ohne Konfiguration. Verifiziert in der Apple-Doku zu `URLSessionConfiguration`.
- **`URL.scheme`** — geeignet fuer "ist das HTTP/HTTPS?" Check (`scheme?.lowercased() == "http" || == "https"`).
- **NSItemProvider `loadItem(forTypeIdentifier:)`** — liefert `URL` fuer `public.url`-Konformitaet zuverlaessig (bestehender Code).
- **`HTTPURLResponse.value(forHTTPHeaderField:)`** — case-insensitive Lookup, geeignet fuer `Content-Disposition`. Format laut RFC 6266: `attachment; filename="foo.mp3"` oder `attachment; filename*=UTF-8''foo.mp3`. Kein Apple-Built-in-Parser; einfache Regex auf `filename="..."` plus Decoding fuer `filename*=UTF-8''` reicht. Bei `audiodharma.org`-S3-Antworten sind beide Varianten vorhanden, der einfache `filename="..."`-Match ist ausreichend.

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

### 4. Filename-Reihenfolge: Content-Disposition vor URL-Pfad vor Content-Type-Fallback

**Trade-off:** Der einfachste Ansatz waere, immer aus dem Content-Type abzuleiten (`audio/mpeg` → `audio.mp3`). Aber damit verliert man jeden lesbaren Filename — `audiodharma.org/talks/25401/download` mit Server-`Content-Disposition: filename="20260504-David_Lorey-IMC-guided_meditation.mp3"` waere in der Bibliothek nur "audio.mp3".

**Entscheidung:** Strikte Praeferenz Content-Disposition > URL-Pfad-Endung > Content-Type-Fallback. Begruendung: User sehen den Filename in der Bibliothek (zumindest als initialen Vorschlag im Edit-Sheet); ein sprechender Name ist deutlich nuetzlicher als `audio.mp3`. Der Aufwand fuer den Header-Parser ist <30 Zeilen.

**Konsistenz mit Android:** Der Android-Plan verwendet die gleiche Reihenfolge (siehe `shared-091-android.md` Design-Entscheidung 2). Die beiden Plattformen sollen vergleichbare Filenames produzieren.

### 5. Defense-in-Depth: InboxHandler verifiziert, dass `prepareImport` den Import angenommen hat

**Trade-off:** Wenn die Filename-Ableitung in AudioDownloadService strikt korrekt ist, reicht das. Defensive Pruefung danach ist redundant.

**Entscheidung:** Trotzdem absichern. `FileOpenHandler.prepareImport` koennte aus anderen Gruenden ablehnen (zukuenftige Validierungen, leere Dateien, …) — und tut das heute schon stumm. Die ticket-AK "kein silent fail" ist nur dann wirklich erfuellt, wenn der `InboxHandler` den Import nachweislich erfolgreich angenommen sieht. Konkrete Pruefung: nach `prepareImport` muss `fileOpenHandler.showImportTypeSelection == true` (es wird gleich ein Sheet erscheinen) **oder** `pendingImportURL == url`. Wenn nicht: `downloadError = .notAnAudioUrl` setzen.

## Refactorings

Keine. Alle Aenderungen sind additiv (neuer Enum-Case, neuer Filter, neue Strings).

## Fachliche Szenarien

### AK-1: URL ohne Audio-Endung wird akzeptiert

- Gegeben: User teilt `https://www.audiodharma.org/talks/25401/download` aus Safari an Still Moment
  Wenn: Share Extension verarbeitet die URL
  Dann: JSON-Reference wird in den App-Group-Inbox geschrieben, Alert "Saved to Still Moment" erscheint

### AK-2: Server liefert Audio-Content-Type + Content-Disposition → Import mit echtem Filename

- Gegeben: JSON-Reference fuer `https://www.audiodharma.org/talks/25401/download` im Inbox, Server liefert nach Redirect `audio/mpeg` und `Content-Disposition: filename="20260504-David_Lorey-IMC-guided_meditation.mp3"`
  Wenn: Haupt-App wird aktiv, `InboxHandler.processInbox()` laeuft
  Dann: `AudioDownloadService.download(...)` liefert eine lokale Datei-URL deren Name `20260504-David_Lorey-IMC-guided_meditation.mp3` enthaelt (Endung `.mp3`), `FileOpenHandler.canHandle` akzeptiert die Datei, `prepareImport(url:)` setzt `showImportTypeSelection = true`, Import-Typ-Auswahl erscheint

### AK-2b: Server liefert Audio-Content-Type ohne Content-Disposition → Fallback-Filename mit korrekter Endung

- Gegeben: JSON-Reference fuer URL ohne Pfad-Endung, Server liefert `audio/mpeg` ohne `Content-Disposition`
  Wenn: Download laeuft
  Dann: lokale Datei wird unter Fallback-Filename `audio.mp3` gespeichert, Import-Pipeline akzeptiert sie, Import-Typ-Auswahl erscheint

### AK-2c: Defense-in-Depth — Importer weist Datei trotz Audio-Content-Type ab → User-Fehler

- Gegeben: AudioDownloadService liefert (theoretisch) eine Datei zurueck, deren Endung `FileOpenHandler.canHandle` nicht akzeptiert (z. B. weil eine zukuenftige Validierung greift)
  Wenn: `InboxHandler` ruft `prepareImport(url:)` und prueft danach `fileOpenHandler.showImportTypeSelection`
  Dann: Wert ist `false` → `downloadError = .notAnAudioUrl` wird gesetzt, "Keine Aufnahme gefunden"-Dialog erscheint statt silent fail

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

1. **AudioDownloadService — Filename/Extension-Ableitung** (AK-2 / AK-2b) — Tests rot: URL ohne Endung + `audio/mpeg` ergibt Datei mit `.mp3`-Endung; URL ohne Endung + `Content-Disposition: filename="x.mp3"` ergibt Datei `x.mp3`; URL ohne Endung + `application/octet-stream` Fallback. Dann implementieren: Content-Disposition-Parser + Content-Type-Fallback.
2. **AK-3: `InboxError.notAnAudioUrl` einfuehren + Mapping** — Pure Application-Layer-Aenderung, gut isoliert testbar.
3. **AK-2c: Defense-in-Depth in InboxHandler** — Test rot mit Mock, der eine Datei ohne `.mp3`/`.m4a`-Endung liefert. Dann `prepareImport`-Pruefung implementieren.
4. **AK-1 + AK-4: Share-Extension-Filter aendern** — Manueller Test (Share Extension hat keine Unit Tests; Verhalten ist trivial).
5. **AK-3 (Presentation): Alert-Block auf Error-Case-Differenzierung umbauen** — UI-seitige Aenderung; manuell + ggf. Snapshot.
6. **AK-2 + AK-5 (manuell)**: Smoke-Test mit der echten `audiodharma.org/talks/25401/download`-URL (erwartet: Import-Sheet mit echtem Filename) und einer nicht-Audio-URL `https://www.example.com/` (erwartet: "Keine Aufnahme gefunden"-Dialog).

## Hinweise

- **Cross-Platform-Konsistenz**: Die Android-Seite muss die gleiche Differenzierung vornehmen — siehe `shared-091-android.md`. Fehlertexte sollten zwischen iOS und Android wortgleich (modulo Plattform-Idiomen) sein.
- **Lokalisierungs-Test**: `make check` laeuft Localization-Linting; vor Commit sicherstellen, dass beide Sprachen die neuen Keys haben.
- **Review-Hinweis**: Der `AudioDownloadError.unsupportedContentType`-Pfad existiert seit shared-046, war aber bisher tot, weil die Share Extension URLs vor dem Download filterte. Nach dieser Aenderung wird er real erreichbar — Tests fuer diesen Pfad sind ein "shouldn't-have-been-untested"-Cleanup.

## Offene Fragen

Keine.
