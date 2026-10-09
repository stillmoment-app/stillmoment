# Implementierungsplan: shared-128 (iOS)

Ticket: shared-128 — Podcast-Folge aus Apple Podcasts importieren
Erstellt: 2026-10-09

## Annahmen

- **Aufloesung in der App, nicht in der Extension.** `ShareViewController` bleibt unveraendert (nimmt `http/https`-Links an, schreibt eine `URLReference` in die Inbox). Erkennen des Apple-Podcasts-Links, Lookup und Fehlerzuordnung passieren im `InboxHandler` vor dem Download — dort leben Ladefenster, Abbrechen und Meldungen.
- **Link-Erkennung:** Host `podcasts.apple.com` (Gross-/Kleinschreibung egal), Pfad `/<land>/podcast/<kurzname>/id<ziffern>`, Query `i=<ziffern>` → einzelne Folge. Ohne gueltiges `i` → ganzer Podcast. Land beliebig (zwei Buchstaben, auch `/us/`, `/de/`, `/gb/`). Kurzname wird ignoriert. Alles andere → kein Apple-Podcasts-Link → bestehender Link-Import unveraendert.
- **Lookup:** `GET https://itunes.apple.com/lookup?id=<PodcastID>&entity=podcastEpisode&limit=200&country=<land>`. `<land>` ist das erste Pfadsegment des Links (`de`, `us`, …) und wird von `ApplePodcastsLink` mitgeparst. Folge = Eintrag mit `trackId == i`. Audiodatei = `episodeUrl`, Titel = `trackName`. Lehrer:in = `artistName` des Podcast-Eintrags (`wrapperType == "track"`, `kind == "podcast"`), sonst `collectionName`. `episodeContentType == "video"` → nicht uebernehmbar. Fehlt `episodeUrl` oder ist es kein `http/https`-Link → nicht uebernehmbar. Eine `http://`-Adresse wird vor dem Download auf `https://` umgeschrieben (ATS blockiert `http`); scheitert der Download dann, gelten die normalen Fehlerzuordnungen.
- **Lookup-Vorschlaege haben Vorrang vor ID3-Tags** im Bearbeiten-Dialog. Nur wenn der Lookup fuer ein Feld nichts liefert (leer), greift die bestehende Kaskade (ID3 → Dateiname).
- **Folgentitel unveraendert** uebernehmen (nur Whitespace trimmen, wie `ImportPrefill.sanitize` es ohnehin tut). Kein Abschneiden von "(20:34 Min.)".
- **Drei Meldungen** (Texte identisch zu Android):
  1. Ganzer Podcast — Titel DE "Bitte eine einzelne Folge teilen" / EN "Please share a single episode"; Text DE "Dieser Link führt zu einem ganzen Podcast. Teile in deiner Podcast-App eine einzelne Folge mit Still Moment." / EN "This link leads to a whole podcast. In your podcast app, share a single episode with Still Moment."; nur "Schließen"/"Close".
  2. Gerade nicht erreichbar — Titel DE "Gerade nicht erreichbar" / EN "Not reachable right now"; Text DE "Bitte prüfe deine Internetverbindung und versuche es später erneut." / EN "Please check your internet connection and try again later."; Knoepfe "Erneut versuchen"/"Retry" (bestehender Key `share.download.error.retry`, unveraendert) + "Abbrechen"/"Cancel". Ausloeser: Netzfehler/Zeitueberschreitung bei Lookup **oder** Download (`AudioDownloadError.networkError`) sowie HTTP 403/429 vom Lookup-Dienst. Gilt auch fuer den bestehenden Link-Import (ersetzt dort "Download fehlgeschlagen" nur fuer reine Netzfehler).
  3. Leider nicht moeglich — Titel DE "Leider nicht möglich" / EN "Not possible"; Text DE "Diese Folge kann leider nicht übernommen werden." / EN "Unfortunately, this episode can't be imported."; nur "Schließen"/"Close". Ausloeser beim Podcast-Import: Folge nicht im Lookup, Video, kein `episodeUrl`, unerwartete Antwort (kein JSON, andere HTTP-Fehler vom Lookup), HTTP-Fehler beim Laden der Episode, falscher Content-Type, Datei vom Importer abgelehnt.
- **Bestehender Link-Import** behaelt fuer HTTP-Fehler und Schreibfehler "Download fehlgeschlagen" (mit Retry) und fuer falschen Inhaltstyp "Keine Aufnahme gefunden" (nur Schliessen).
- **Ladefenster unveraendert** (`DownloadOverlayView`). Es ist waehrend Lookup **und** Download sichtbar (ein `isDownloading`-Flag). Abbrechen bricht auch den Lookup ab; es entsteht kein Eintrag und keine Meldung.
- **Keine Kennungen:** Lookup und Download ohne eigenen User-Agent, ohne Cookies/Kennungen. `URLSession.shared` sendet den System-User-Agent (`StillMoment/<build> CFNetwork/… Darwin/…`) — enthaelt keine Geraete- oder Nutzerkennung, bleibt wie beim bestehenden Link-Import. `URLRequest` setzt keine zusaetzlichen Header.
- **Netz nur nach Nutzeraktion:** Lookup nur innerhalb von `processInbox()`/`retry()` — beides wird nur nach einem Teilen bzw. dem Retry-Knopf ausgeloest.
- **Download in Datei:** `AudioDownloadService` laedt per `session.download(for:)` statt `session.data(for:)`; damit sind Folgen > 2 h ohne RAM-Spitze importierbar. Gilt auch fuer den bestehenden Link-Import.
- **Keine Abstraktion fuer weitere Podcast-Apps.** Typen heissen bewusst `ApplePodcasts…`.
- **Geraetetest erledigt (2026-10-09):** Still Moment erscheint im Teilen-Menue einer Folge in Apple Podcasts. Die Share-Extension bleibt unveraendert.
- **Retry-Fix gehoert in dieses Ticket** (bestaetigt): `InboxHandler.retry()` merkt sich den geteilten Link (Design-Entscheidung 5).
- **Typnamen sind plattformuebergreifend** festgelegt: `ApplePodcastsLink`, `InboxError.notReachable` / `.podcastWithoutEpisode` / `.episodeUnavailable` — Android uebernimmt sie.

## Vorbereitung

- **Vorab-AK erledigt:** Geraetetest am 2026-10-09 — Still Moment erscheint im Teilen-Menue von Apple Podcasts. Bei der Implementierung im Ticket und in `dev-docs/concepts/podcast-import.md` festhalten (Doku-AK). Beim ersten manuellen Test per Log (`Received URL scheme` / Inbox-JSON) bestaetigen, dass der Folgenlink inkl. `?i=` ankommt.
- Test-URLs fuer Unit-Tests aus dem Konzept: `https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344` (Folge), dieselbe ohne `?i=` (Podcast). Lookup-Antworten als JSON-Fixture im Test (gekuerzt, echte Feldnamen).

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMoment/Domain/Models/ApplePodcastsLink.swift` | Domain | Neu | Pure Erkennung: `static func parse(_ url: URL) -> ApplePodcastsLink?` → `.episode(country:podcastId:episodeId:)` / `.podcast(country:podcastId:)` / `nil` (`country` = erstes Pfadsegment, kleingeschrieben) |
| `ios/StillMoment/Domain/Models/PodcastEpisode.swift` | Domain | Neu | Value: `audioURL`, `title: String?`, `podcastAuthor: String?`, `podcastName: String?`; berechnet `teacherSuggestion` (Autor, sonst Podcast-Name; leere Werte zaehlen als fehlend) |
| `ios/StillMoment/Domain/Models/PodcastEpisodeResolveError.swift` | Domain | Neu | `.notReachable`, `.unavailable`, `.cancelled` |
| `ios/StillMoment/Domain/Services/PodcastEpisodeResolverProtocol.swift` | Domain | Neu | `func resolveEpisode(country:podcastId:episodeId:) async throws -> PodcastEpisode`, `func cancel()` |
| `ios/StillMoment/Infrastructure/Services/ApplePodcastsEpisodeResolver.swift` | Infrastructure | Neu | Lookup per `URLSession` (`session: URLSession = .shared`), HTTP-Status-Zuordnung (403/429 → `.notReachable`, sonst non-2xx → `.unavailable`), `cancel()` wie `AudioDownloadService.cancelDownload()` |
| `ios/StillMoment/Infrastructure/Services/ApplePodcastsLookupResponse.swift` | Infrastructure | Neu | `Decodable`-DTOs fuer Apples JSON + `static func episode(withId:from data:) throws -> PodcastEpisode` — pure, ohne Netz testbar; schreibt `http://`-`episodeUrl` auf `https://` um |
| `ios/StillMoment/Infrastructure/Services/AudioDownloadService.swift` | Infrastructure | Aendern | `fetch` → `session.download(for:)`; Temp-Datei nach Status-/Content-Type-Pruefung per `moveItem` in `dl_<UUID>/<name>` verschieben; bei jedem Fehler Temp-Datei loeschen; Fehler-Zuordnung (`.cancelled` → `downloadCancelled`, sonst `networkError`) bleibt |
| `ios/StillMoment/Domain/Models/AudioMetadata.swift` | Domain | Erweitern | `func preferring(title: String?, artist: String?) -> AudioMetadata` — nicht-leere Vorschlaege ersetzen ID3-Werte, Rest bleibt |
| `ios/StillMoment/Application/FileOpenHandler.swift` | Application | Erweitern | `importFile(from:preferredTitle:preferredArtist:)` (Defaults `nil`); wendet `metadata.preferring(...)` nach dem ID3-Auslesen an. Bestehende Aufrufer unveraendert |
| `ios/StillMoment/Application/InboxError.swift` | Application | Neu (verschoben) | `InboxError` aus `InboxHandler.swift` herausloesen (file_length); neue Cases `.notReachable`, `.podcastWithoutEpisode`, `.episodeUnavailable`; neue Eigenschaften `isRetryable`, `alertTitleKey`, `alertMessageKey`; pure Zuordnungsfunktionen `forLinkImport(_ AudioDownloadError)`, `forPodcastImport(_ PodcastEpisodeResolveError)`, `forPodcastImport(_ AudioDownloadError)` |
| `ios/StillMoment/Application/InboxHandler.swift` | Application | Aendern | Neuer Init-Parameter `episodeResolver: PodcastEpisodeResolverProtocol`; `processURLReference` verzweigt nach `ApplePodcastsLink.parse`; Abbruch-Flag; Retry-Gedaechtnis + `retry()`; `cancelDownload()` bricht auch den Lookup ab |
| `ios/StillMoment/AppDependencies.swift` | Composition Root | Erweitern | Feld `episodeResolver: PodcastEpisodeResolverProtocol`, in `live()` `ApplePodcastsEpisodeResolver()` |
| `ios/StillMoment/StillMomentApp.swift` | Presentation | Aendern | `InboxHandler` mit `episodeResolver` bauen; Alert liest Titel/Text/Knoepfe aus `downloadError.alertTitleKey/alertMessageKey/isRetryable`; Retry-Knopf ruft `inboxHandler.retry()` statt `checkInbox()` |
| `ios/StillMoment/Resources/{de,en}.lproj/Localizable.strings` | Resources | Erweitern | Neue Keys (siehe unten); bestehende Keys unveraendert |
| `ios/StillMomentTests/Mocks/MockPodcastEpisodeResolver.swift` | Tests | Neu | Konfigurierbares Ergebnis/Fehler, `cancelCalled`, `requestedIds` |
| `ios/StillMomentTests/Helpers/MockedAppDependencies.swift` | Tests | Erweitern | `episodeResolver: MockPodcastEpisodeResolver()` |
| `ios/StillMomentTests/Mocks/MockAudioDownloadService.swift` | Tests | Erweitern | Optional `onDownload`-Hook (fuer Abbruch-Timing-Tests) |
| `ios/StillMomentTests/Domain/ApplePodcastsLinkTests.swift` | Tests | Neu | Erkennung Folge/Podcast/fremd, Laender-Varianten |
| `ios/StillMomentTests/Domain/PodcastEpisodeTests.swift` | Tests | Neu | Lehrer:in-Vorschlag inkl. fehlendem/leerem Autor |
| `ios/StillMomentTests/Domain/AudioMetadataPreferringTests.swift` | Tests | Neu | Vorrang der Vorschlaege vor ID3 |
| `ios/StillMomentTests/Infrastructure/ApplePodcastsLookupResponseTests.swift` | Tests | Neu | Folge finden, Video, fehlendes `episodeUrl`, Folge fehlt, kaputtes JSON, `http` → `https` |
| `ios/StillMomentTests/Infrastructure/ApplePodcastsEpisodeResolverTests.swift` | Tests | Neu | Request-URL, 403/429/500/Netzfehler/Abbruch (nutzt bestehendes `MockURLProtocol`) |
| `ios/StillMomentTests/Infrastructure/AudioDownloadServiceTests.swift` | Tests | Erweitern | Download in Datei, Temp-Aufraeumen bei Fehler, Abbruch weiter `downloadCancelled` (bestehender Test muss gruen bleiben) |
| `ios/StillMomentTests/Application/InboxErrorTests.swift` | Tests | Neu | Zuordnung jedes Fehlerfalls zu genau einer der drei Meldungen + Retry-Faehigkeit |
| `ios/StillMomentTests/Application/InboxHandlerTests+PodcastImport.swift` | Tests | Neu | Podcast-Flow end-to-end mit Mocks (eigene Datei; `InboxHandlerTests.swift` hat schon 528 Zeilen) |
| `ios/StillMomentTests/Application/InboxHandlerTests+Retry.swift` | Tests | Neu | Retry nach Netzfehler laedt erneut (Link- und Podcast-Import) |
| `ios/StillMomentTests/FileOpenHandlerTests.swift` (bzw. `FileOpenHandlerImportFlowTests.swift`) | Tests | Erweitern | Bevorzugte Werte landen im `pendingImportSignal.metadata` |
| `ios/StillMomentShareExtension/ShareViewController.swift` | Extension | **Unveraendert** | — |
| `CHANGELOG.md`, `dev-docs/reference/glossary.md`, `dev-docs/concepts/podcast-import.md` | Doku | Erweitern | Laut Doku-AKs; Glossar: Eintrag "Podcast-Import" (Abgrenzung: loest einen Apple-Podcasts-Folgenlink zur Audiodatei auf und nutzt danach den Link-Import) + Glossar-Text "Link-Import" um "laedt direkt in eine Datei" ergaenzen |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `URLSession.download(for:delegate:) async throws -> (URL, URLResponse)` | iOS 15 | Apple Docs (Foundation) | Deployment Target ist iOS 16 → verfuegbar. Laut WWDC21 "Use async/await with URLSession" wird die Datei **nicht** automatisch geloescht (anders als im Completion-Handler-Weg) → nach Erfolg verschieben, bei jedem Fehlerpfad (Status, Content-Type, Move-Fehler) selbst loeschen. Sofort verschieben, keine weiteren `await` dazwischen. |
| `URLSession.getAllTasks` + `cancel()` | iOS 9 | Apple Docs | Bricht auch Download-Tasks ab; async-Aufruf wirft `URLError(.cancelled)` → bleibt `AudioDownloadError.downloadCancelled`. |
| `URLSession.data(for:)` | iOS 15 | Apple Docs | Fuer den Lookup (kleine JSON-Antwort, RAM unkritisch). |
| `URLProtocol` mit Download-Tasks | — | Apple Docs | Das bestehende `MockURLProtocol` funktioniert grundsaetzlich auch fuer Download-Tasks (CFNetwork schreibt die gelieferten Daten in die Temp-Datei). In der RED-Phase verifizieren. |
| iTunes Lookup (`itunes.apple.com/lookup`) | — | Konzept `podcast-import.md` | Kein Schluessel; max. 200 Folgen; ca. 20 Abrufe/Minute; 403/429 bei Ueberlast. Antwort: `{"resultCount": n, "results": [...]}`, erster Eintrag ist der Podcast (`wrapperType: "track"`, `kind: "podcast"`), Folgen haben `wrapperType: "podcastEpisode"`. Nicht auf Reihenfolge verlassen — Podcast-Eintrag per `kind` suchen. `trackId` ist eine Zahl (Int64) → Vergleich numerisch, nicht als String. |
| `URLComponents` / `URL.pathComponents` | iOS 7 | Apple Docs | Fuer die Link-Erkennung; Foundation ist in Domain erlaubt (wie `ImportPrefill`). |

## Design-Entscheidungen

### 1. Wo liegen Link-Erkennung und Lookup-Parsing?

**Trade-off:** Alles in einen Infrastructure-Service packen ist einfach, macht aber die fachliche Regel "Folge vs. ganzer Podcast" nur ueber den Service testbar. Alles in Domain legen hiesse, Apples JSON-Format (Wire-Format eines Fremddienstes) in die Domain zu ziehen.

**Entscheidung:**
- **Link-Erkennung → Domain** (`ApplePodcastsLink`): reine Fachregel ueber eine URL ("ist das eine Folge, ein Podcast oder etwas anderes?"), keine Abhaengigkeit, wird vom `InboxHandler` (Application) gebraucht, um *vor* jedem Netzzugriff zu entscheiden (ganzer Podcast → sofort Meldung, kein Lookup).
- **Lookup-Antwort-Parsing → Infrastructure** (`ApplePodcastsLookupResponse`), aber als pure `static func` mit `Data` rein, `PodcastEpisode` raus — ohne Netz testbar. Analog zu `AudioDownloadService`, der Header-Parsing (`Content-Disposition`) ebenfalls in Infrastructure haelt.
- **Fachliche Vorschlagsregel "Autor, sonst Podcast-Name" → Domain** (`PodcastEpisode.teacherSuggestion`), damit sie unabhaengig vom JSON getestet ist und die Infrastructure nur Rohwerte liefert.

### 2. Wie fliessen Titel/Lehrer:in in den Bearbeiten-Dialog?

**Ist-Zustand:** `FileOpenHandler.importFile` liest ID3 (`AudioMetadata`) → `pendingImportSignal` → `GuidedMeditationsListView` → `viewModel.beginImport(url:metadata:)` → `ImportPrefill.compute(metadata:fileName:knownTeachers:)` (Kaskade: sanitized ID3-Titel/-Artist → Dateiname → bekannte Lehrer).

**Alternativen:**
- (a) Neues Feld `suggestion` in `IncomingFileImport` + `PendingImport` + Erweiterung von `ImportPrefill.compute` → beruehrt ViewModel, View, Domain-Prefill.
- (b) Die Lookup-Werte ersetzen im `FileOpenHandler` direkt nach dem ID3-Auslesen `title`/`artist` in `AudioMetadata` (`metadata.preferring(title:artist:)`). Alles dahinter (Signal, ViewModel, `ImportPrefill`) bleibt unveraendert.

**Entscheidung: (b).** Ein einziger Nahtpunkt, keine Aenderung an ViewModel/View/Prefill. Die bestehende `ImportPrefill`-Kaskade sorgt automatisch dafuer, dass ein fehlender Lookup-Wert auf ID3/Dateiname zurueckfaellt und dass Werte nur getrimmt, nicht gekuerzt werden. `duration`/`album` kommen weiter aus der Datei. `FileOpenHandler` bleibt podcast-agnostisch (Parameter heissen `preferredTitle`/`preferredArtist`, nicht "podcast…").

Bekannte Nebenwirkung: `ImportPrefill.sanitize` verwirft Platzhalter wie "Audio"/"Untitled"/reine Nummern ("42") auch aus dem Lookup — dann greift der Dateiname. Akzeptabel und konsistent.

### 3. Fehlermodell

**Trade-off:** Eine Meldung pro technischer Ursache wuerde viele Cases in der UI erzeugen; das Ticket will genau drei Meldungen nach Handlungsmoeglichkeit. Die Zuordnung muss aber testbar sein ("jeder Fehlerfall → genau eine Meldung").

**Entscheidung:**
- Domain-Fehler bleiben technisch-grob: `AudioDownloadError` unveraendert; neu `PodcastEpisodeResolveError { notReachable, unavailable, cancelled }` — der Resolver ordnet HTTP-Status und Parse-Ergebnisse bereits ein (403/429/Netz → `notReachable`; alles andere → `unavailable`).
- `InboxError` (Application) bekommt die nutzersichtbaren Faelle:
  - `.notReachable` (neu, Link- **und** Podcast-Import) — Meldung 2, retry-faehig
  - `.podcastWithoutEpisode` (neu) — Meldung 1, nicht retry-faehig
  - `.episodeUnavailable` (neu) — Meldung 3, nicht retry-faehig
  - `.downloadFailed` (bestehend: Link-Import HTTP-/Schreibfehler, kaputtes JSON) — "Download fehlgeschlagen", retry-faehig
  - `.notAnAudioUrl` (bestehend) — "Keine Aufnahme gefunden", nicht retry-faehig
  - `.containerNotAvailable` (bestehend) — unveraendert
- Zuordnung als pure statische Funktionen auf `InboxError` (`forLinkImport`, `forPodcastImport` fuer beide Fehlertypen), plus `isRetryable`, `alertTitleKey`, `alertMessageKey`. Damit verschwindet die Switch-Logik aus `StillMomentApp` (heute ungetestet) in testbaren Code. `InboxError` wandert dafuer in eine eigene Datei `InboxError.swift` (InboxHandler.swift naehert sich sonst der 400-Zeilen-Warnung).
- Kein "Retry" bei `.downloadFailed` aus kaputtem Inbox-JSON? → Bleibt wie heute (retry-faehig) — ausserhalb des Scopes.

### 4. Abbrechen waehrend Lookup

**Trade-off:** Der Lookup laeuft wie der Download auf `URLSession.shared`; `AudioDownloadService.cancelDownload()` bricht ohnehin *alle* Tasks dieser Session ab. Sich darauf zu verlassen, waere eine versteckte Kopplung. Zudem gibt es ein Zeitfenster *zwischen* Lookup-Ende und Download-Start, in dem kein Task laeuft.

**Entscheidung:** `InboxHandler.cancelDownload()` setzt ein Flag `cancelRequested`, ruft `episodeResolver.cancel()` **und** `downloadService.cancelDownload()`. `InboxHandler` (MainActor) prueft das Flag nach dem Lookup und nach dem Download; ist es gesetzt → Ergebnis verwerfen (geladene Temp-Datei loeschen), `.empty`, keine Meldung, kein Bearbeiten-Dialog. Flag wird zu Beginn jedes Vorgangs zurueckgesetzt. Der Resolver mappt `URLError.cancelled` auf `.cancelled`.

### 5. Retry muss tatsaechlich erneut laden (Befund)

**Befund:** Heute ruft "Erneut versuchen" `checkInbox()` auf. `processInbox()` loescht den Inbox-Eintrag aber nach jeder Verarbeitung — auch nach Fehler (`testDownloadFailureStillCleansUpInboxEntry`). Der Retry findet daher eine leere Inbox und tut **nichts**, ohne Rueckmeldung. Das verletzt die AKs "Erneut versuchen nur, wenn ein erneuter Versuch etwas aendern kann" und "Nie stilles Scheitern" — und betrifft die neue Meldung 2 direkt. Android merkt sich die URL fuer den Retry (`RetryableErrorDialog`).

**Entscheidung:** `InboxHandler` merkt sich bei einem retry-faehigen Fehler den geteilten Link (`retryableSharedURL`), neue Methode `retry() async -> InboxResult` verarbeitet genau diesen Link erneut (gleicher Weg inkl. Podcast-Erkennung und Ladefenster). Inbox-Aufraeumverhalten bleibt unveraendert. `processURLReference` wird dafuer in "JSON lesen" und "geteilten Link verarbeiten" (`processSharedLink(_:filename:)`) geteilt. Die App ruft im Retry-Knopf `inboxHandler.retry()` und behandelt das Ergebnis wie `checkInbox()` (Tab-Wechsel bei Erfolg). Vom User bestaetigt: Fix gehoert in shared-128.

### 6. Download in Datei

**Entscheidung:** `fetch` liefert `(tempFileURL, HTTPURLResponse)` statt `Data`. Ablauf: `download(for:)` → Status pruefen → Content-Type pruefen → Dateinamen bestimmen → `createDirectory(dl_<UUID>)` → `moveItem(temp → ziel)`. Jeder Fehler nach dem Download loescht die Temp-Datei (`defer`-artig, aber nur wenn nicht verschoben). Fehlerzuordnung unveraendert (`.cancelled` → `downloadCancelled`, uebrige `URLError` → `networkError`, non-2xx → `invalidResponse`, Move-Fehler → `downloadFailed`). Protokoll `AudioDownloadServiceProtocol` bleibt unveraendert.

## Refactorings

1. **`InboxError` in eigene Datei verschieben** und um Alert-Eigenschaften erweitern — noetig, weil die Fehlerzuordnung testbar sein muss (AK Tests) und `InboxHandler.swift` sonst Richtung `file_length`-Warnung waechst.
   - Risiko: Niedrig. Reiner Umzug + additive Properties; bestehende Tests nutzen nur die Cases.
2. **`processURLReference` aufteilen** in JSON-Lesen und `processSharedLink` — noetig fuer `retry()` und die Podcast-Verzweigung (sonst `function_body_length` > 40).
   - Risiko: Niedrig–mittel. 20+ bestehende `InboxHandlerTests` decken den Link-Import ab und muessen gruen bleiben.
3. **`AudioDownloadService.fetch` auf Datei umstellen** — AK-Pflicht.
   - Risiko: Mittel. 15 bestehende `AudioDownloadServiceTests` (inkl. Abbruch) sichern das Verhalten; zusaetzlich Temp-Datei-Aufraeumen pruefen.

## Fachliche Szenarien

### AK-0: Vorab-Pruefung (User, Geraet) — erledigt 2026-10-09 (Still Moment erscheint im Teilen-Menue)

- Gegeben: iPhone mit installierter Still-Moment-Build und Apple Podcasts
  Wenn: User teilt eine Folge in Apple Podcasts
  Dann: Still Moment erscheint im Teilen-Menue; uebergeben wird ein Link der Form `podcasts.apple.com/<land>/podcast/<kurzname>/id<n>?i=<n>` (Ergebnis im Ticket festhalten)

### AK-1: Folgenlink fuehrt zum Ladefenster und Bearbeiten-Dialog

- Gegeben: Inbox enthaelt einen geteilten Link `https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344`, der Lookup kennt Folge `1000792422344` mit `episodeUrl` `https://anbieter.example/folge.mp3`
  Wenn: Die App verarbeitet die Inbox
  Dann: Das Ladefenster ist waehrend Lookup und Download sichtbar, danach oeffnet der Bearbeiten-Dialog fuer die geladene Datei (Ergebnis `.downloadCompleted`)
- Gegeben: Derselbe Link
  Wenn: Die App verarbeitet ihn
  Dann: Der Lookup wird genau einmal mit Podcast-ID `1528936478` angefragt (`entity=podcastEpisode&limit=200&country=de`)

### AK-2: Vorschlaege fuer Titel und Lehrer:in

- Gegeben: Lookup liefert Folgentitel "Body Scan (20:34 Min.)", Podcast-Autor "Deutschlandfunk Nova", die Datei hat ID3-Titel "ep_123" und ID3-Artist "DLF"
  Wenn: Der Bearbeiten-Dialog oeffnet
  Dann: Titel ist "Body Scan (20:34 Min.)" (unveraendert, nichts abgeschnitten), Lehrer:in ist "Deutschlandfunk Nova"
- Gegeben: Podcast-Eintrag hat keinen oder einen leeren Autor, Podcast-Name ist "Achtsam"
  Wenn: Der Bearbeiten-Dialog oeffnet
  Dann: Lehrer:in ist "Achtsam"
- Gegeben: Lookup-Antwort enthaelt keinen Podcast-Eintrag (nur Folgen), Folge hat `collectionName` "Achtsam"
  Wenn: Der Bearbeiten-Dialog oeffnet
  Dann: Lehrer:in ist "Achtsam"
- Gegeben: Lookup liefert weder Autor noch Podcast-Name, die Datei hat ID3-Artist "Tara Brach"
  Wenn: Der Bearbeiten-Dialog oeffnet
  Dann: Lehrer:in ist "Tara Brach" (bestehende Kaskade greift)
- Gegeben: Normaler Link-Import (kein Podcast) einer MP3 mit ID3-Titel/-Artist
  Wenn: Der Bearbeiten-Dialog oeffnet
  Dann: Vorschlaege wie bisher aus ID3 (keine Regression)

### AK-3: Nach dem Speichern normale, offline spielbare Meditation

- Gegeben: Folge wurde geladen und im Bearbeiten-Dialog gespeichert
  Wenn: User oeffnet die Bibliothek
  Dann: Die Folge ist eine normale Meditation; es wird keine Podcast-Herkunft gespeichert (keine neuen Felder an `GuidedMeditation`). Abspielen ohne Netz ist durch den bestehenden Import-Weg gegeben (manueller Test im Flugmodus)

### AK-4: Audiodatei direkt beim Anbieter

- Gegeben: Lookup liefert `episodeUrl` `https://anbieter.example/folge.mp3`
  Wenn: Die App laedt die Folge
  Dann: Der Download-Dienst wird mit genau dieser Adresse aufgerufen (nicht mit dem Apple-Link)
- Gegeben: Lookup liefert `episodeUrl` `http://anbieter.example/folge.mp3`
  Wenn: Die App laedt die Folge
  Dann: Der Download-Dienst wird mit `https://anbieter.example/folge.mp3` aufgerufen (Rest der Adresse inkl. Query unveraendert)

### AK-5: Abbrechen bricht auch die Suche ab, kein Eintrag

- Gegeben: Der Lookup laeuft
  Wenn: User tippt "Abbrechen" im Ladefenster
  Dann: Lookup wird abgebrochen, Ladefenster schliesst, keine Meldung, kein Bearbeiten-Dialog, kein Download gestartet (Ergebnis `.empty`)
- Gegeben: Der Lookup ist fertig, der Download hat noch nicht begonnen
  Wenn: User tippt "Abbrechen"
  Dann: Download wird nicht gestartet, keine Meldung, kein Eintrag
- Gegeben: Der Download der Folge laeuft
  Wenn: User tippt "Abbrechen"
  Dann: Download endet, keine Meldung, kein Eintrag (bestehendes Verhalten auch fuer Podcast-Folgen)

### AK-6: Laender-Varianten

- Gegeben: Links mit `/de/`, `/us/`, `/gb/` und Grossbuchstaben im Host (`Podcasts.Apple.com`)
  Wenn: Der Link erkannt wird
  Dann: Jeweils `.episode(country:podcastId:episodeId:)` mit denselben IDs und dem jeweiligen Land (`de`, `us`, `gb`)
- Gegeben: Folgenlink mit `/us/`
  Wenn: Der Lookup angefragt wird
  Dann: Die Anfrage enthaelt `country=us`
- Gegeben: Link mit zusaetzlichen Query-Parametern (`?i=1000792422344&l=en`)
  Wenn: Der Link erkannt wird
  Dann: Folge `1000792422344` wird erkannt
- Gegeben: `https://example.com/podcast/x/id123?i=456` (fremder Host) oder ein MP3-Link
  Wenn: Der Link erkannt wird
  Dann: Kein Apple-Podcasts-Link → bestehender Link-Import ohne Lookup

### AK-7: Netz nur nach Nutzeraktion, ohne Kennungen

- Gegeben: Inbox ist leer
  Wenn: Die App wird aktiv
  Dann: Kein Lookup, kein Download
- Gegeben: Ein Folgenlink wird verarbeitet
  Wenn: Der Lookup-Request gebaut wird
  Dann: Er hat keine zusaetzlichen Header (kein eigener User-Agent, keine Kennung) und nur die Query `id`, `entity`, `limit`, `country`

### AK-8: Ladefenster unveraendert

- Gegeben: Folgenlink wird verarbeitet
  Wenn: Lookup laeuft
  Dann: `isDownloading == true` (dasselbe Ladefenster, keine neuen Texte); `DownloadOverlayView` wird nicht geaendert
- Gegeben: Link auf ganzen Podcast
  Wenn: Er verarbeitet wird
  Dann: Ladefenster erscheint nicht (Entscheidung ohne Netz), direkt Meldung 1

### AK-9: Folge > 2 h / Download in Datei

- Gegeben: Server liefert eine Audiodatei mit `audio/mpeg`
  Wenn: Der Download-Dienst laedt sie
  Dann: Sie liegt unter `tmp/dl_<UUID>/<name>.mp3` mit identischem Inhalt; die Temp-Datei von URLSession existiert nicht mehr
- Gegeben: Server antwortet 404 bzw. `text/html`
  Wenn: Der Download-Dienst laedt
  Dann: `invalidResponse` bzw. `unsupportedContentType`, und es bleibt keine heruntergeladene Datei zurueck
- Gegeben: Ein Download laeuft
  Wenn: `cancelDownload()` aufgerufen wird
  Dann: `downloadCancelled` (bestehender Test bleibt gruen)
- Manuell (Geraet): Folge > 2 h aus Apple Podcasts importieren → Import klappt

### AK-10: Meldung 1 — ganzer Podcast

- Gegeben: Geteilter Link `https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478` (ohne `i`, oder `i=` leer/nicht numerisch)
  Wenn: Die App verarbeitet ihn
  Dann: Meldung "Bitte eine einzelne Folge teilen" mit nur "Schließen"; kein Lookup, kein Download

### AK-11: Meldung 2 — gerade nicht erreichbar (Podcast-Import)

- Gegeben: Kein Internet / Zeitueberschreitung beim Lookup
  Wenn: Folgenlink wird verarbeitet
  Dann: Meldung "Gerade nicht erreichbar" mit "Erneut versuchen" und "Abbrechen"
- Gegeben: Lookup-Dienst antwortet HTTP 403 bzw. 429
  Wenn: Folgenlink wird verarbeitet
  Dann: Meldung "Gerade nicht erreichbar" (je ein Test pro Status)
- Gegeben: Lookup erfolgreich, Download der Folge scheitert mit Netzfehler
  Wenn: Folgenlink wird verarbeitet
  Dann: Meldung "Gerade nicht erreichbar"
- Gegeben: Meldung 2 wird angezeigt, Netz ist wieder da
  Wenn: User tippt "Erneut versuchen"
  Dann: Ladefenster erscheint, derselbe Folgenlink wird erneut aufgeloest und geladen, danach Bearbeiten-Dialog

### AK-12: Meldung 2 im bestehenden Link-Import

- Gegeben: Geteilter direkter MP3-Link, kein Internet
  Wenn: Die App verarbeitet ihn
  Dann: Meldung "Gerade nicht erreichbar" mit "Erneut versuchen"/"Abbrechen" (statt "Download fehlgeschlagen")
- Gegeben: Geteilter direkter MP3-Link, Server antwortet 500
  Wenn: Die App verarbeitet ihn
  Dann: weiterhin "Download fehlgeschlagen" mit Retry (unveraendert)
- Gegeben: Geteilter Link auf eine HTML-Seite
  Wenn: Die App verarbeitet ihn
  Dann: weiterhin "Keine Aufnahme gefunden", nur "Schließen" (unveraendert)
- Gegeben: "Gerade nicht erreichbar" beim MP3-Link, Netz wieder da
  Wenn: User tippt "Erneut versuchen"
  Dann: Derselbe Link wird erneut geladen (Download-Dienst ein zweites Mal mit derselben Adresse aufgerufen)

### AK-13: Meldung 3 — alles andere beim Podcast-Import

Jeweils: Folgenlink wird verarbeitet → Meldung "Leider nicht möglich" mit nur "Schließen", kein Eintrag.
- Gegeben: Folgen-ID nicht in der Lookup-Antwort (aeltere Folge)
- Gegeben: Lookup-Antwort `resultCount: 0`
- Gegeben: Folge hat `episodeContentType: "video"`
- Gegeben: Folge ohne `episodeUrl` bzw. mit nicht-`http(s)`-Adresse
- Gegeben: Lookup-Antwort ist kein gueltiges JSON / unerwartete Struktur
- Gegeben: Lookup-Dienst antwortet HTTP 404 bzw. 500
- Gegeben: Download der Folge antwortet HTTP 404/410 (`invalidResponse`)
- Gegeben: Download liefert `text/html` (`unsupportedContentType`)
- Gegeben: Geladene Datei wird vom Importer abgelehnt (keine MP3/M4A-Endung)

### AK-14: Retry nur, wenn sinnvoll

- Gegeben: Jeder `InboxError`-Fall
  Wenn: `isRetryable` abgefragt wird
  Dann: `true` genau fuer `.notReachable` und `.downloadFailed`; `false` fuer `.podcastWithoutEpisode`, `.episodeUnavailable`, `.notAnAudioUrl`, `.containerNotAvailable`

### AK-15: Nie stilles Scheitern, keine technischen Begriffe

- Gegeben: Jeder Fehlerpfad des Podcast-Imports (AK-10, 11, 13)
  Wenn: Er durchlaufen wird
  Dann: `downloadError` ist gesetzt (kein `.empty` ausser bei Abbruch)
- Gegeben: Die neuen DE/EN-Texte
  Wenn: Review
  Dann: Keine Begriffe wie "Download", "HTTP", "Server", "Lookup", "URL"

### AK-16: Lokalisiert, visuell konsistent

- Gegeben: Geraet auf DE bzw. EN
  Wenn: Eine der drei Meldungen erscheint
  Dann: Titel/Text/Knoepfe exakt wie in den Annahmen; `make check` (Lokalisierungspruefung) gruen
- Visuell: System-`.alert` wie bisher (Android nutzt seinen bestehenden Dialog) — manueller Vergleich

## Reihenfolge der Akzeptanzkriterien

Optimale Reihenfolge fuer TDD:

1. **AK-6 / AK-10 (Erkennung)** — `ApplePodcastsLinkTests` → `ApplePodcastsLink` (Domain, pure). Grundlage fuer alles.
2. **AK-2 (Vorschlagsregel)** — `PodcastEpisodeTests` (`teacherSuggestion`), `AudioMetadataPreferringTests` (Vorrang vor ID3).
3. **AK-13 Parsing-Teil** — `ApplePodcastsLookupResponseTests` (Folge finden, Video, kein `episodeUrl`, fehlende Folge, kaputtes JSON, Autor aus Podcast-Eintrag, `http`-`episodeUrl` wird `https`).
4. **AK-11/13 Resolver-Teil + AK-5 Lookup-Abbruch + AK-7** — `ApplePodcastsEpisodeResolverTests` mit `MockURLProtocol` (Request-URL inkl. `country` ohne Zusatz-Header, 403/429 → `notReachable`, 404/500 → `unavailable`, Netzfehler, Abbruch → `cancelled`).
5. **AK-9 (Download in Datei)** — `AudioDownloadServiceTests` erweitern, dann `AudioDownloadService` umbauen; alle bestehenden Tests gruen halten.
6. **AK-14 + Zuordnung (AK-11/12/13)** — `InboxErrorTests` → `InboxError.swift` (Umzug + neue Cases + `isRetryable`/Keys + Zuordnungsfunktionen).
7. **AK-2 Durchreichung** — `FileOpenHandler`-Test (`preferredTitle/Artist` landen im Signal) → Parameter ergaenzen.
8. **AK-1, AK-4, AK-5, AK-8, AK-10–13 im Flow** — `InboxHandlerTests+PodcastImport` mit `MockPodcastEpisodeResolver` + `MockAudioDownloadService` → `InboxHandler` umbauen (`processSharedLink`, Abbruch-Flag).
9. **AK-11/12 Retry** — `InboxHandlerTests+Retry` → `retryableSharedURL` + `retry()`.
10. **Verdrahtung** — `AppDependencies` (+ `AppDependenciesTests` falls dort Felder geprueft werden), `MockedAppDependencies`, `StillMomentApp` (Alert aus `InboxError`-Eigenschaften, Retry-Knopf → `retry()`).
11. **AK-16 Lokalisierung** — Strings DE/EN, `make check`.
12. **Doku** — CHANGELOG, Glossar, Konzept (Ergebnis Vorab-Pruefung).
13. **Manueller Test** laut Ticket (Simulator: Link per Safari-Teilen; Geraet: Apple Podcasts, Flugmodus, Folge > 2 h).

## Lokalisierungs-Keys

Namenskonvention wie bestehende `share.download.*`:

| Key | DE | EN |
|-----|----|----|
| `share.download.error.not_reachable.title` | Gerade nicht erreichbar | Not reachable right now |
| `share.download.error.not_reachable.message` | Bitte prüfe deine Internetverbindung und versuche es später erneut. | Please check your internet connection and try again later. |
| `share.download.error.podcast_without_episode.title` | Bitte eine einzelne Folge teilen | Please share a single episode |
| `share.download.error.podcast_without_episode.message` | Dieser Link führt zu einem ganzen Podcast. Teile in deiner Podcast-App eine einzelne Folge mit Still Moment. | This link leads to a whole podcast. In your podcast app, share a single episode with Still Moment. |
| `share.download.error.episode_unavailable.title` | Leider nicht möglich | Not possible |
| `share.download.error.episode_unavailable.message` | Diese Folge kann leider nicht übernommen werden. | Unfortunately, this episode can't be imported. |
| `share.download.error.retry` (bestehend, unveraendert) | Erneut versuchen | Retry |
| `share.download.error.cancel` (bestehend) | Abbrechen | Cancel |
| `common.close` (bestehend) | Schließen | Close |

Hinweis Cross-Platform: Android `download_error_retry` ist ebenfalls "Erneut versuchen"/"Retry" — keine Aenderung noetig. Die neue Meldung 2 nutzt auf beiden Plattformen den bestehenden Retry-Key.

Die `errorDescription`-Fallbacks in `InboxError` fuer die neuen Cases nutzen die `.message`-Keys (wie `.notAnAudioUrl` heute).

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Uebergebener Inhalt weicht vom erwarteten Folgenlink ab (z.B. fehlendes `?i=`) | Sichtbarkeit im Teilen-Menue am 2026-10-09 bestaetigt; den uebergebenen Link beim ersten manuellen Test per Log pruefen |
| `http://`-`episodeUrl` wird von ATS blockiert | Umschreiben auf `https://` vor dem Download; Anbieter ohne HTTPS fuehren zu Meldung 2 bzw. 3 (kein stilles Scheitern) |
| Temp-Datei von `download(for:)` bleibt bei Fehlern liegen (Speicher bei 170-MB-Folgen) | Jeder Fehlerpfad nach dem Download loescht die Temp-Datei; Test prueft "keine Datei bleibt zurueck" |
| `MockURLProtocol` verhaelt sich bei Download-Tasks anders (z.B. Abbruch-Test) | In Schritt 5 zuerst RED-Lauf; falls noetig `MockURLProtocol.stopLoading` / Fehlerpfad anpassen (nur Testcode) |
| Abbruch-Zeitfenster zwischen Lookup und Download | `cancelRequested`-Flag im MainActor-`InboxHandler`, eigener Test (AK-5 Szenario 2) |
| `cancelDownload()` bricht alle Tasks von `URLSession.shared` ab (auch fremde) | Bestehende, dokumentierte Einschraenkung; nur ein Vorgang gleichzeitig (`isProcessing`-Guard). Nicht in diesem Ticket aendern |
| Lookup-Ratenlimit (~20/min) beim Testen | Unit-Tests ausschliesslich ueber `MockURLProtocol`/Mocks, nie echtes Netz |
| Lookup liefert nur 200 neueste Folgen | Erwartet; Meldung 3 bis shared-129 |
| Duplikat-Erkennung per Dateiname+Groesse: viele Anbieter nennen Dateien generisch (`audio.mp3`, Tracking-Redirects) | Groessenvergleich verhindert Fehltreffer meist; bestehendes Verhalten, kein Scope |
| AAC-Folgen mit `audio/aac` bekommen Fallback-Namen `audio.mp3` | Bestehendes Verhalten des Link-Imports; AVFoundation erkennt das Format am Inhalt. Beim manuellen Test beobachten, ggf. Follow-up |
| Retry-Fix aendert bestehendes Link-Import-Verhalten | Eigene Tests (AK-12 Szenario 4); bestehende Aufraeum-Tests bleiben gruen |
| `URLSession.shared` sendet System-User-Agent | Enthaelt App-Name/Build und OS-Version, keine Geraete-/Nutzerkennung — gleich wie bestehender Link-Import; im Konzept/Datenschutz bereits abgedeckt (shared-127) |

## Offene Fragen

- [x] Retry-Fix in shared-128 — bestaetigt.
- [x] Retry-Text — bestehender Key unveraendert ("Erneut versuchen"/"Retry").
- [x] Vorab-Pruefung — Still Moment erscheint im Teilen-Menue von Apple Podcasts (2026-10-09).

Keine offenen Fragen.
