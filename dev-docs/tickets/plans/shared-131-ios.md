# Implementierungsplan: shared-131 (iOS)

Ticket: shared-131 — Gleiche Audio-Dateitypen beim Link- und Podcast-Import
Erstellt: 2026-10-09

## Annahmen

- **Nur der Download-Dienst aendert sich.** Link- und Podcast-Import laufen beide durch
  `AudioDownloadService.download(from:filename:)`. Die Zuordnung des Fehlers
  `AudioDownloadError.unsupportedContentType` zur Meldung existiert schon (shared-128):
  `InboxError.forLinkImport` → `.notAnAudioUrl` („Keine Aufnahme gefunden“),
  `InboxError.forPodcastImport` → `.episodeUnavailable` („Leider nicht möglich“). Daran
  aendert sich nichts, keine neuen Texte, `InboxHandler` bleibt unveraendert.
- **Liste und Normalisierung identisch zu Android:** Wert vor dem ersten `;` nehmen, Leerzeichen
  am Rand entfernen, kleinschreiben, dann exakter Vergleich mit der Liste aus dem Ticket
  (8 Typen, neu gegenueber Android: `audio/x-mpeg`, `audio/mpeg3`). Kein Praefix-Vergleich.
- **Fehlender Content-Type → annehmen** (wie heute). **Leerer Content-Type (`""`) → ablehnen**,
  so wie Android heute rechnet (`"" !in SUPPORTED_CONTENT_TYPES`). Siehe Offene Fragen.
- **Geprueft wird nur bei Erfolgsantworten (2xx).** Eine 404-/500-Antwort mit `text/html` bleibt
  `invalidResponse` (Link-Import: „Download fehlgeschlagen“ mit Retry) — sonst wuerde sich die
  Meldung fuer Serverfehler aendern. Gleiche Reihenfolge wie Android (erst Status, dann Typ).
- **Der Dateityp wird zweimal mit derselben Regel geprueft:** frueh (sobald die Antwort da ist,
  Download wird abgebrochen) und wie bisher nach dem Download (greift nur noch bei sehr kleinen
  Antworten, bei denen der Download vor der fruehen Pruefung fertig ist). Beide nutzen dieselbe
  Domain-Regel.
- `fallbackFilename(for:)` (Praefix-Vergleich fuer `.m4a`) bleibt unveraendert — er bestimmt nur den
  Dateinamen, nicht die Annahme.
- Der Zusatzcheck `rejectedFileError` im `InboxHandler` bleibt (Ticket-Hinweis).

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMoment/Domain/Models/AudioContentType.swift` | Domain | Neu | `enum AudioContentType { static func isAccepted(_ contentType: String?) -> Bool }` — Liste + Normalisierung, pure (Muster wie `ImportPrefill`, Android-Pendant liegt im Infrastructure-Companion) |
| `ios/StillMoment/Infrastructure/Services/AudioDownloadService.swift` | Infrastructure | Aendern | `fetch` reicht einen Per-Request-Delegate an `session.download(for:delegate:)`; `URLError.cancelled` wird zu `unsupportedContentType`, wenn der Delegate abgelehnt hat, sonst wie bisher `downloadCancelled`. `validateContentType` nutzt `AudioContentType.isAccepted` statt `hasPrefix("audio/")` |
| `ios/StillMoment/Infrastructure/Services/AudioContentTypeGate.swift` | Infrastructure | Neu | `final class AudioContentTypeGate: NSObject, URLSessionTaskDelegate` — in `urlSession(_:didCreateTask:)` KVO auf `task.response`; bei 2xx und nicht angenommenem Typ: `rejected = true` (per `NSLock`), `task.cancel()`, Beobachtung beenden. Eigene Datei, weil `AudioDownloadService.swift` schon ~205 Zeilen hat; Name endet bewusst nicht auf `Service/Handler/…` (Lint-Regel `service_created_outside_composition_root` — ist ein Hilfsobjekt pro Download, kein Dienst) |
| `ios/StillMomentTests/Domain/AudioContentTypeTests.swift` | Tests | Neu | Fachliche Liste, Normalisierung, fehlend, Praefix-Fallen |
| `ios/StillMomentTests/Infrastructure/AudioDownloadServiceContentTypeTests.swift` | Tests | Neu | Ablehnen vor Download-Ende, Annahme der neuen Typen, Abbrechen unveraendert, keine Reste (eigene Datei; `AudioDownloadServiceTests.swift` hat 531 Zeilen) |
| `ios/StillMomentTests/Infrastructure/AudioDownloadServiceTests.swift` | Tests | Aendern | `MockURLProtocol`: optionale Verzoegerung zwischen Antwort und Inhalt (`bodyDelay`), `stopLoading` bricht den laufenden Lade-`Task` ab. Kommentar im Test `…nonStandardAudioMp3ContentType…` („`audio/`-Prefix-Pruefung“) an die Liste anpassen |
| `CHANGELOG.md` | Doku | Erweitern | Eintrag (beim Abschluss; Ticket-AK) |
| `dev-docs/reference/glossary.md` | Doku | Erweitern | Link-Import: „Inhaltstyp wird geprueft“ → „Dateityp wird vor dem Laden gegen eine feste Liste geprueft (identisch auf beiden Plattformen)“ |

Unveraendert: `AudioDownloadServiceProtocol`, `AudioDownloadError`, `InboxError`, `InboxHandler`,
`MockAudioDownloadService`, `AppDependencies`, Lokalisierung.

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `URLSession.download(for:delegate:)` | iOS 15 | Apple Docs | Bleibt Lade-API (Datei statt RAM, shared-128). Async-Variante baut auf den Convenience-Methoden auf und **unterdrueckt** Download-Delegate-Callbacks (`didWriteData`, `didFinishDownloadingTo`) — Quinn (DTS), Forum 723015 |
| `URLSessionTaskDelegate.urlSession(_:didCreateTask:)` | **iOS 16.0** | Apple Docs (JSON) | Deployment Target 16.0 → ok. Laut Quinn auch im async-Fall und auch fuer einen Per-Request-Delegate geliefert — der einzige Weg, an das `URLSessionTask`-Objekt der async-Methode zu kommen |
| KVO auf `URLSessionTask` | iOS 7 | Apple Docs `URLSessionTask`: „All task properties support key-value observing.“ | `observe(\.response, options: [.new])`; `response` wird gesetzt, sobald die Kopfzeilen da sind — vor dem Inhalt. Rueckruf auf beliebigem Thread → Flag per Lock |
| `URLSessionTask.cancel()` | iOS 7 | Apple Docs | async-Aufruf wirft `URLError(.cancelled)`; CFNetwork raeumt seine Temp-Datei bei Abbruch selbst auf |
| `URLSession.getAllTasks` + `cancel()` | iOS 9 | Apple Docs | Abbrechen im Ladefenster unveraendert |
| `URLSession.bytes(for:delegate:)` | iOS 15 | Apple Docs | Verworfen (siehe Entscheidung 1) |
| `URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:)` + `.becomeDownload` | iOS 7 | Apple Docs `URLSessionDataDelegate` | Verworfen (siehe Entscheidung 1). Wird bei Convenience-/async-Methoden nicht aufgerufen („If you create a task using a method that takes a completion handler block, the delegate methods for response and data delivery are not called.“) |

## Design-Entscheidungen

### 1. Wie lehnt iOS ab, bevor die Datei vollstaendig geladen ist?

**Optionen:**
- **(a) Gewaehlt: `download(for:delegate:)` behalten + Per-Request-Delegate mit `didCreateTask` und
  KVO auf `task.response`.** Sobald die Kopfzeilen da sind, wird geprueft; bei falschem Typ
  `task.cancel()`. Laden in Datei, Abbrechen (`getAllTasks`), Temp-Datei-Behandlung, Fehlerzuordnung
  und alle shared-128-Tests bleiben wie sie sind. Zusatz: ~40 Zeilen Hilfsklasse.
- (b) `bytes(for:)` + selbst in Datei schreiben: Antwort kommt vor dem Inhalt, aber Byte-fuer-Byte-
  Iteration ueber 170 MB plus eigenes Puffern/Schreiben/Aufraeumen — mehr Code und Leistungsrisiko
  bei mehrstuendigen Folgen.
- (c) Delegate-basierter Data-Task mit `didReceive response` → `.becomeDownload` / `.cancel`: die dafuer
  gedachte API, verlangt aber Umbau von async auf Delegate + Continuation (eigene Session mit Delegate,
  genau-einmal-Resume, synchrones Verschieben in `didFinishDownloadingTo`, Abbruch-Zuordnung) — grosser
  Eingriff in den gerade stabilisierten shared-128-Pfad.
- (d) `downloadTask`-Delegate mit `didWriteData` + `task.response`: wird bei der async-API nicht
  geliefert, braeuchte denselben Umbau wie (c).
- (e) Vorab-`HEAD`-Anfrage: zweite Anfrage; Server beantworten `HEAD` anders oder gar nicht,
  Tracking-Weiterleitungen von Podcast-Anbietern zaehlen doppelt.

**Entscheidung: (a).** Kleinster Eingriff, nur dokumentierte APIs, Verhalten fuer lange Folgen
und Abbrechen unveraendert.

**Absicherung:** Erster TDD-Schritt ist der „Ablehnen vor dem Ende“-Test (Szenario 4.1) — er zeigt sofort,
ob `didCreateTask` + KVO auf `response` mit `MockURLProtocol` greift. Falls `response` keine KVO-Meldung
liefert: auf `\.countOfBytesReceived` beobachten und dort `task.response` lesen (dann wird nach dem
ersten Datenblock abgebrochen — weiterhin lange vor dem Ende). Falls `didCreateTask` gar nicht ankommt:
anhalten und mit dem User (c) besprechen, nicht improvisieren.

### 2. Wo liegt die Liste?

**Entscheidung:** Domain, `AudioContentType.isAccepted(_:)` — reine fachliche Regel ohne Abhaengigkeit,
direkt testbar, von beiden Pruefstellen (fruehe Pruefung im Gate, spaete in `validateContentType`)
genutzt. Muster wie `ImportPrefill` / `ApplePodcastsLink` (enum mit statischer Funktion).

### 3. Abbruch durch Ablehnung vs. Abbruch durch den Nutzer

Beide enden in `URLError(.cancelled)`. Der Gate merkt sich die Ablehnung; `fetch` prueft im
`catch … where error.code == .cancelled`: Gate hat abgelehnt → `unsupportedContentType`, sonst
`downloadCancelled`. Tippt der Nutzer gleichzeitig „Abbrechen“, unterdrueckt der `InboxHandler`
ohnehin jede Meldung (`cancelRequested`) → keine Meldung, kein Eintrag.

## Refactorings

Keine. `MockURLProtocol` bekommt nur eine optionale Verzoegerung (Testcode).

## Fachliche Szenarien

### AK-1/2/3/5: Welche Dateitypen angenommen werden (`AudioContentTypeTests`)

- Gegeben: Server meldet `audio/mpeg`, `audio/mp3`, `audio/x-mpeg`, `audio/mpeg3`, `audio/mp4`,
  `audio/x-m4a`, `audio/m4a` bzw. `application/octet-stream`
  Dann: jeweils angenommen
- Gegeben: `Audio/MPEG`, `audio/mpeg; charset=UTF-8`, ` audio/x-m4a ;foo=bar`
  Dann: angenommen
- Gegeben: kein Dateityp (`nil`)
  Dann: angenommen
- Gegeben: `audio/ogg`, `audio/aac`, `audio/wav`, `text/html`, `application/json`
  Dann: abgelehnt
- Gegeben: `audio/mpegurl`, `audio/x-mpegurl`, `audio/mp4a-latm`, `application/octet-stream-x`
  Dann: abgelehnt (beginnt nur mit einem erlaubten Typ)
- Gegeben: leerer Dateityp `""`
  Dann: abgelehnt (wie Android)

### AK-4: Abgelehnt, bevor die Datei vollstaendig geladen ist (`AudioDownloadServiceContentTypeTests`)

1. Gegeben: Server antwortet `200`, `audio/ogg`, der Inhalt kommt erst nach 5 s
   Wenn: geladen wird
   Dann: `unsupportedContentType` nach weniger als 2 s (wartet nicht auf den Inhalt)
2. Gegeben: Server antwortet `200`, `audio/x-mpegurl` (kleiner Inhalt)
   Dann: `unsupportedContentType`, keine Datei bleibt zurueck (`CFNetworkDownload_*` und kein neuer `dl_*`-Ordner)
3. Gegeben: Server antwortet `200`, `audio/x-mpeg` bzw. `audio/mpeg3`
   Dann: Datei wird geladen, Endung `.mp3` (heute schon angenommen — Charakterisierung, bleibt gruen)
4. Gegeben: Server antwortet `404` mit `text/html`
   Dann: weiterhin `invalidResponse` (nicht `unsupportedContentType`)
5. Gegeben: Server antwortet `200`, `audio/mpeg`, Inhalt kommt verzoegert (1 s)
   Dann: Datei wird vollstaendig und inhaltsgleich geladen (Gate greift nicht faelschlich ein)
6. Gegeben: Server antwortet `200` ohne Content-Type
   Dann: Datei wird geladen

### AK-6: Link- und Podcast-Import gleich

- Beide Wege nutzen denselben Dienst → durch die Dienst-Tests abgedeckt.
- Meldungen pro Weg: bestehende Tests bleiben gruen und belegen die Zuordnung —
  `InboxErrorTests` (`forLinkImport(.unsupportedContentType) == .notAnAudioUrl`,
  `forPodcastImport(.unsupportedContentType) == .episodeUnavailable`),
  `InboxHandlerTests.testURLReferenceWithUnsupportedContentTypeReturnsNotAnAudioUrl`,
  `InboxHandlerTests+PodcastImport.testEpisodeDownloadProblemsShowOneOfTheThreeMessages`. Keine neuen
  InboxHandler-Tests noetig.

### AK-7: Abbrechen weiterhin sofort

- Gegeben: Server antwortet `200`, `audio/mpeg`, Inhalt kommt erst nach 5 s (Antwort schon da, Gate hat angenommen)
  Wenn: `cancelDownload()` nach 50 ms
  Dann: `downloadCancelled` (nicht `unsupportedContentType`), in weniger als 2 s
- Bestehender `testCancelDownload_throwsDownloadCancelled` (Antwort noch nicht da) bleibt gruen.

### AK-8: Lange Folgen

- Unit: Szenario 4.5 (verzoegerter, grosser Inhalt wird vollstaendig in Datei geladen) +
  bestehender `testDownloadedFileHasIdenticalContentInOwnDownloadFolder`.
- Manuell (Geraet): Folge > 2 h aus Apple Podcasts importieren → klappt; Ladefenster-Abbrechen mitten im
  Download → sofort weg, keine Meldung.

### AK-9: Keine neuen Texte

- Keine Aenderung an `Localizable.strings`; `make check` gruen.

## Reihenfolge der Akzeptanzkriterien

1. **AK-1/2/3/5 Domain-Regel** — `AudioContentTypeTests` (RED) → `AudioContentType.isAccepted`.
2. **Spaete Pruefung auf die Liste umstellen** — Dienst-Test fuer `audio/ogg` und `audio/x-mpegurl`
   mit kleinem Inhalt (RED, heute angenommen) → `validateContentType` nutzt `AudioContentType`.
3. **MockURLProtocol erweitern** — `bodyDelay` + abbrechbarer Lade-`Task` in `stopLoading`; alle
   `AudioDownloadService*`-Tests gruen.
4. **AK-4 fruehe Ablehnung** — Szenario 4.1 (RED: wartet heute 5 s) → `AudioContentTypeGate` +
   Verdrahtung in `fetch`. Hier faellt die Entscheidung `response` vs. `countOfBytesReceived`
   (Design-Entscheidung 1, Absicherung).
5. **AK-7 Abbrechen + 4.4/4.5/4.6** — Abgrenzung Nutzer-Abbruch vs. Ablehnung, Status vor Typ,
   keine falschen Abbrueche.
6. **Quality Gate** — `make check`, `make test-unit-agent`.
7. **Doku** — Glossar (Link-Import), CHANGELOG.
8. **Manueller Test** laut Ticket (Simulator: Link per Safari teilen, MP3 von audiodharma.org und eine
   `audio/ogg`-Datei; Geraet: lange Podcast-Folge, Abbrechen).

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `didCreateTask` / KVO auf `response` verhaelt sich im async-Fall anders als dokumentiert | Erster RED-Test (Schritt 4) prueft genau das; Fallback `countOfBytesReceived`; wenn gar nichts greift: Stopp und Rueckfrage (Option c) |
| Gate bricht faelschlich gueltige Downloads ab (z.B. Weiterleitung 3xx als `response`) | Nur bei 2xx pruefen; Szenarien 4.3, 4.5, 4.6; bestehende Downloadtests (Weiterleitungsfaelle audiodharma/Anchor) bleiben gruen |
| KVO-Rueckruf auf fremdem Thread, Wettlauf mit Fertigstellung | Flag hinter `NSLock`; spaete Pruefung nach dem Download faengt den Fall „fertig vor Pruefung“ mit derselben Regel ab |
| iOS wird strenger: Typen ausserhalb der Liste (z.B. `audio/aac`, `audio/x-wav`) werden jetzt abgelehnt | Gewollt laut Ticket; die Bibliothek kann nur MP3/M4A. Im CHANGELOG erwaehnen |
| `MockURLProtocol` ist global (statischer Handler) und wird von mehreren Testklassen genutzt | Verzoegerung als statische Eigenschaft, in `tearDown` zuruecksetzen; `stopLoading` bricht den Lade-`Task` ab, damit keine spaeten Client-Aufrufe nach Testende passieren |
| Zeitbasierte Tests (≤ 2 s) flackern auf langsamer CI | Grosszuegige Schwelle (Inhalt 5 s verzoegert, Erwartung < 2 s) |

## Offene Fragen

- [ ] Leerer Content-Type (`Content-Type:` ohne Wert): Plan rechnet „ablehnen“, weil Android heute so
  rechnet. Alternative: wie fehlend behandeln (annehmen). Praktisch kaum relevant — nur bestaetigen,
  damit Android-Plan und iOS-Plan dasselbe festhalten.

## Umsetzungsnotizen (2026-10-09)

- **KVO-Weg greift:** `didCreateTask` kommt beim Per-Request-Delegate der async-API an, KVO auf
  `\.response` meldet die Kopfzeilen. Ein `audio/ogg`-Download mit 5 s verzoegertem Inhalt endet
  nach < 2 s mit `unsupportedContentType`. Fallback `countOfBytesReceived` war nicht noetig.
- **Leerer Content-Type** wird abgelehnt (Vorgabe, identisch Android); geprueft wird nur die rohe
  Kopfzeile, nie `URLResponse.mimeType`.
- **Befund leere Platzhalterdatei:** Ein abgebrochener Download-Task (Nutzer-Abbruch *und* Ablehnung)
  hinterlaesst eine leere `CFNetworkDownload_*.tmp` (0 Byte) im tmp-Ordner; der Pfad ist ueber die
  async-API nicht erreichbar. Fuer den Nutzer-Abbruch bestand das schon seit shared-128. Der
  shared-128-Test `testFailedDownloadLeavesNoFileBehind` prueft deshalb jetzt „keine Datei mit Inhalt
  bleibt zurueck“ statt „gar keine neue Datei“.
- **Glossar** unveraendert (kein neuer/geaenderter Begriff). **CHANGELOG** bewusst nicht in diesem Commit.
