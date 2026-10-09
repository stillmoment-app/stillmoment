# Implementierungsplan: shared-128 (Android)

Ticket: [shared-128](../shared/shared-128-podcast-folge-aus-apple-podcasts.md)
Plattform: **Android**
Erstellt: 2026-10-09

## Kurzfassung

Der Link-Import laeuft heute so: `MainActivity.handleTextShareIntent` → `UrlAudioValidator.classifyShareText` → `pendingDownloadUrl` → `DownloadUrlEffect` (NavGraph) ruft `UrlAudioDownloaderProtocol.download(url)` → `pendingMeditationImportUri` → Library-Composable → `GuidedMeditationsListViewModel.importMeditation(uri)` → Bearbeiten-Dialog mit `ImportPrefill` aus ID3/Dateiname.

Neu: Ein kleiner `LinkImportHandler` (neben `FileOpenHandler` in `data/`) uebernimmt den Teil "geteilte Adresse → lokale Datei + Vorschlag". Er erkennt Apple-Podcasts-Links, fragt bei Apples Lookup-Dienst nach der Folge, laedt `episodeUrl` ueber den bestehenden Downloader und liefert neben der Datei einen Vorschlag (Folgentitel / Autor). Fehler werden dort auf genau die drei Podcast-Meldungen bzw. die bestehenden Link-Import-Meldungen abgebildet — als reiner, unit-testbarer Kotlin-Code statt in der Composable. `DownloadUrlEffect` ruft nur noch den Handler.

**Wichtiger Befund:** `classifyShareText` akzeptiert heute nur Text, der mit `http(s)://` **beginnt**. Ein Messenger-Share wie `"Folge X https://podcasts.apple.com/..."` endet heute in "Kein Link gefunden". Die Link-Extraktion muss deshalb angepasst werden (AK "auf anderem Weg geteilt").

## Annahmen

- **Auflösung (festgelegt):** Link-Form `https://podcasts.apple.com/<land>/podcast/<slug>/id<digits>?i=<digits>`; `i` vorhanden → Folge, fehlt → ganzer Podcast; jede Laendervariante. Lookup `https://itunes.apple.com/lookup?id=<PodcastID>&entity=podcastEpisode&limit=200&country=<land>` (`<land>` = erstes Pfadsegment des geteilten Links, z. B. `de`; entschieden, damit regional verfuegbare Podcasts gefunden werden — keine Nutzerkennung); Folge = Eintrag mit `wrapperType == "podcastEpisode"` und `trackId == i`; Audiodatei `episodeUrl`, Titel `trackName`. Autor = `artistName` des Podcast-Eintrags (`wrapperType == "track"`, `kind == "podcast"`), sonst `collectionName`. `episodeContentType == "video"` → nicht uebernehmbar. Live geprueft (2026-10-09, "Achtsam"): Felder und Typen stimmen; Antwort-Content-Type ist `text/javascript` (nicht pruefen); Podcast-Eintrag hat `trackId == PodcastID` (deshalb nur `podcastEpisode`-Eintraege vergleichen).
- **IDs sind `Long`:** Folgen-IDs wie `1000792422344` > `Int.MAX_VALUE`. Parsing mit `toLongOrNull()`, JSON mit `jsonPrimitive.longOrNull`. Ueberlange Ziffernfolge → `null` → "Leider nicht moeglich" statt Crash.
- **Lage der Erkennung:** Läuft im bestehenden Link-Import-Pfad **vor** dem Download. Keine Abstraktion fuer andere Podcast-Apps (kein `PodcastLinkResolver`-Interface mit mehreren Implementierungen); nur ein Lookup-Interface als Test-Naht fuer das Netz.
- **Vorrang:** Lookup-Vorschlag schlaegt ID3/Dateiname feldweise. Fehlt ein Lookup-Feld (leer), greift der bisherige ID3-/Dateiname-Vorschlag fuer dieses Feld. Titel wird nur getrimmt, nichts abgeschnitten (Ticket-Hinweis "(20:34 Min.)").
- **Meldungs-Zuordnung (festgelegt):**
  - "Bitte eine einzelne Folge teilen" — Link ohne `i`.
  - "Gerade nicht erreichbar" (Retry + Abbrechen) — `IOException`/Timeout ohne HTTP-Status bei Lookup **oder** Download; HTTP 403/429 **nur vom Lookup-Dienst**. Gilt auch im bestehenden Link-Import fuer `UrlAudioDownloadError.Network`.
  - "Leider nicht moeglich" (nur Schliessen) — Folge nicht im Lookup, Video, kein `episodeUrl`, unerwartete/kaputte Antwort, sonstiger HTTP-Status vom Lookup, HTTP-Fehler beim Laden der Episode, falscher Content-Type der Episode.
  - Bestehender Link-Import ausserhalb von Apple Podcasts: `Http` → weiter "Download fehlgeschlagen" (Retry), `NotAudio` → "Keine Aufnahme gefunden", kein Link → "Kein Link gefunden". Unveraendert.
- **Ladefenster** (`DownloadProgressModal`) unveraendert; Lookup laeuft unter demselben `isDownloading`-Flag.
- **Keine Kennungen:** Lookup-URL enthaelt nur `id`, `entity`, `limit`, `country` (Land aus dem geteilten Link, keine Nutzerkennung). Header wie beim Downloader (`User-Agent: StillMoment/1.0`), keine weiteren.
- **> 2 h:** Android streamt bereits per `input.copyTo(output)` in `cacheDir/dl_<ts>/` (verifiziert in `UrlAudioDownloaderImpl.download`). `readTimeout` 60 s gilt pro Lesevorgang, nicht fuer die Gesamtdauer. Keine Codeaenderung noetig; nur Test + manueller Test.
- **Link-Extraktion aus Text:** `classifyShareText` sucht kuenftig das **erste** `http(s)://`-Token im Text (bis Whitespace, abschliessende Satzzeichen `.,;:!?)»"'` entfernt). Gilt fuer den gesamten Link-Import, nicht nur Apple-Links — ein Text mit Link ist fachlich ein geteilter Link. Reiner Text ohne Link bleibt "Kein Link gefunden". (Entschieden; iOS braucht das nicht, weil die Share-Extension einen URL-Typ bekommt.)
- **`http://`-Audioadresse:** Eine `episodeUrl` mit `http://` wird vor dem Download auf `https://` umgeschrieben (entschieden, identisch auf iOS — Android blockiert Cleartext, iOS ATS ebenso). Pure Funktion `PodcastEpisode`-seitig (`audioUrl` liefert bereits die https-Variante), getestet.
- **Vorab-Pruefung iOS erledigt:** Still Moment erscheint im Teilen-Menue von Apple Podcasts (laut Koordination); fuer Android ohne Auswirkung.
- **Retry-Knopf:** Die neue Meldung nutzt den bestehenden Key `download_error_retry` ("Erneut versuchen" / "Retry"); kein "Try Again", kein neuer Key.

## Betroffene Codestellen

Pfade relativ zu `android/app/src/main/kotlin/com/stillmoment/` bzw. `android/app/src/test/kotlin/com/stillmoment/`.

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `domain/models/UrlAudioValidator.kt` | Domain | Aendern | `classifyShareText`: erstes `http(s)`-Token aus Text extrahieren statt `startsWith` auf den ganzen Text |
| `domain/models/ApplePodcastsLink.kt` | Domain | **Neu** | `sealed class ApplePodcastsLink { data class Episode(country: String, podcastId: Long, episodeId: Long); data class Podcast(country: String, podcastId: Long) }` + `companion fun parse(url: String): ApplePodcastsLink?` (`null` = kein Apple-Podcasts-Link). Reine String-/Regex-Logik, Host case-insensitiv `podcasts.apple.com`, Laendersegment beliebig, wird als `country` (lowercase) mitgegeben |
| `domain/models/PodcastEpisode.kt` | Domain | **Neu** | `data class PodcastEpisode(audioUrl: String, title: String?, podcastAuthor: String?, podcastName: String?)` (Feldnamen wie iOS) + berechnete `teacherSuggestion` (Autor, sonst Podcast-Name; leer zaehlt als fehlend) + `fun importSuggestion(): ImportPrefill` (title → name, teacherSuggestion → teacher) + `companion fun upgradeToHttps(url: String): String` (`http://` → `https://`, sonst unveraendert) |
| `domain/models/PodcastEpisodeResolveError.kt` | Domain | **Neu** | `sealed class PodcastEpisodeResolveError : Throwable { NotReachable; Unavailable }` — nur die zwei Ausgaenge, die fuer den Nutzer zaehlen |
| `domain/models/LinkImportFailure.kt` | Domain | **Neu** | `sealed class LinkImportFailure { PodcastWithoutEpisode; NotReachable; EpisodeUnavailable; NotAudio; DownloadFailed }` — bestimmt Meldung und ob Retry angeboten wird (`val canRetry`) |
| `domain/models/ImportPrefill.kt` | Domain | Erweitern | `fun preferring(suggestion: ImportPrefill?): ImportPrefill` — feldweiser Vorrang des Vorschlags |
| `domain/services/PodcastEpisodeResolverProtocol.kt` | Domain | **Neu** | `suspend fun resolveEpisode(link: ApplePodcastsLink.Episode): Result<PodcastEpisode>` (Failure = `PodcastEpisodeResolveError` oder `CancellationException`), `fun cancel()` — gleiche Form wie `UrlAudioDownloaderProtocol` |
| `infrastructure/network/ApplePodcastsEpisodeResolver.kt` | Infrastructure | **Neu** | `HttpURLConnection` mit `connectionFactory`-Naht (Muster `UrlAudioDownloaderImpl`), `currentConnection`/`cancelled` + `disconnect()` fuer Abbrechen; HTTP 200 → Parser; 403/429 → `NotReachable`; sonstiger Status → `Unavailable`; `IOException` → `NotReachable` (bzw. `CancellationException` wenn abgebrochen). `internal fun lookupUrl(country: String, podcastId: Long)` |
| `infrastructure/network/ApplePodcastsLookupResponse.kt` | Infrastructure | **Neu** | `internal object`, pure: `parse(json: String, episodeId: Long): Result<PodcastEpisode>` mit `kotlinx.serialization.json.Json.parseToJsonElement` (bereits Dependency). Liefert Rohwerte (`podcastAuthor` = `artistName` des Podcast-Eintrags, `podcastName` = `collectionName`). Kaputtes JSON / fehlende Felder / Video / nicht gefunden → `Unavailable` |
| `data/LinkImportHandler.kt` | Data | **Neu** | `@Singleton`, `@Inject(downloader, lookup, logger)`. `suspend fun import(sharedUrl: String): LinkImportOutcome`; `fun cancel()` (setzt Flag, ruft `lookup.cancel()` + `downloader.cancel()`). `sealed class LinkImportOutcome { Imported(uri: Uri, suggestion: ImportPrefill?); Failed(LinkImportFailure); Cancelled }`. Enthaelt die gesamte Fehler-Zuordnung |
| `infrastructure/di/AppModule.kt` | Infrastructure | Erweitern | `providePodcastEpisodeResolver(impl: ApplePodcastsEpisodeResolver): PodcastEpisodeResolverProtocol` |
| `MainActivity.kt` | Presentation | Aendern | `@Inject lateinit var linkImportHandler: LinkImportHandler` statt `urlAudioDownloader` an `StillMomentNavHost` durchreichen |
| `presentation/navigation/NavGraph.kt` | Presentation | Aendern | `StillMomentNavHost`: Parameter `linkImportHandler` statt `urlAudioDownloader`; Modal-Cancel → `linkImportHandler.cancel()`. `pendingMeditationImportUri: MutableStateFlow<Uri?>` → `MutableStateFlow<SharedImport?>` (`data class SharedImport(uri: Uri, suggestion: ImportPrefill?)`), FileOpen-Pfad setzt `suggestion = null`. Library-Composable ruft `importMeditation(uri, suggestion)`. `DownloadUrlEffect` auf Handler umbauen; Retry startet `import(originalUrl)` erneut (statt `downloader.download(failedUrl)`), `DownloadFailure` → `LinkImportFailure` + Original-URL. `RetryableErrorDialog`, `NotAudioErrorDialog`, `NoLinkErrorDialog` in neue Datei verschieben |
| `presentation/ui/common/LinkImportErrorDialogs.kt` | Presentation | **Neu** | `LinkImportErrorDialog(failure, onRetry, onDismiss)` dispatcht auf zwei kleine Composables: `CloseOnlyErrorDialog(titleRes, messageRes, onDismiss)` und `RetryErrorDialog(titleRes, messageRes, retryRes, onRetry, onDismiss)`. Ersetzt die drei duplizierten AlertDialogs; je ein `AlertDialog` pro Composable (MultipleEmitters) |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | Application | Erweitern | `importMeditation(uri: Uri, suggestion: ImportPrefill? = null)`: nach `ImportPrefill.compute(...)` → `.preferring(suggestion)` |
| `res/values/strings.xml`, `res/values-de/strings.xml` | Resources | Erweitern | 8 neue Keys (siehe unten) |
| `test/.../domain/models/ApplePodcastsLinkTest.kt` | Test | **Neu** | Erkennung inkl. Laendervarianten, Long-IDs, kein Apple-Link |
| `test/.../infrastructure/network/ApplePodcastsLookupResponseTest.kt` | Test | **Neu** | Folge finden, Autor-Fallback, Video, fehlendes `episodeUrl`, kaputtes JSON, nur `podcastEpisode`-Eintraege |
| `test/.../infrastructure/network/ApplePodcastsEpisodeResolverTest.kt` | Test | **Neu** | Exakte Lookup-URL, 403/429/500, IOException, Cancel (Muster `UrlAudioDownloaderTest`) |
| `test/.../data/LinkImportHandlerTest.kt` | Test | **Neu** | Fehler-Zuordnung je Fall, Cancel zwischen Lookup und Download, kein Lookup bei Nicht-Apple-Link. Fakes fuer Downloader + Lookup als private Klassen im Test (kein Mock-Framework-Zwang; Mockito ist vorhanden) |
| `test/.../domain/models/UrlAudioValidatorTest.kt` | Test | Erweitern | Text + URL, URL mit Satzzeichen am Ende, nur Text |
| `test/.../domain/models/ImportPrefillTest.kt` | Test | Erweitern | `preferring` feldweise |
| `test/.../presentation/viewmodel/GuidedMeditationsListViewModelTest.kt` | Test | Erweitern | Import mit Vorschlag → Draft zeigt Lookup-Titel/-Autor trotz ID3 |
| `test/.../infrastructure/network/UrlAudioDownloaderTest.kt` | Test | Erweitern | Grosse Datei (z. B. 64 MB generierter Stream) landet vollstaendig in Datei |
| `CHANGELOG.md`, `dev-docs/reference/glossary.md`, `dev-docs/concepts/podcast-import.md` | Docs | Erweitern | Laut Ticket |

**Kein Handlungsbedarf:** `DownloadProgressModal` (Ladefenster unveraendert), `FileOpenHandler` (Duplikatpruefung Name+Groesse greift auch fuer Podcast-Dateien), `UrlAudioDownloaderImpl` (Streaming in Datei existiert), Persistenz beim Speichern (`repository.addMeditation` kopiert in den App-Container → offline abspielbar).

### String-Keys (Konvention `download_error_*`)

| Key | EN | DE |
|-----|----|----|
| `download_error_whole_podcast_title` | Please share a single episode | Bitte eine einzelne Folge teilen |
| `download_error_whole_podcast_message` | This link leads to a whole podcast. In your podcast app, share a single episode with Still Moment. | Dieser Link führt zu einem ganzen Podcast. Teile in deiner Podcast-App eine einzelne Folge mit Still Moment. |
| `download_error_not_reachable_title` | Not reachable right now | Gerade nicht erreichbar |
| `download_error_not_reachable_message` | Please check your internet connection and try again later. | Bitte prüfe deine Internetverbindung und versuche es später erneut. |
| `download_error_episode_unavailable_title` | Not possible | Leider nicht möglich |
| `download_error_episode_unavailable_message` | Unfortunately, this episode can't be imported. | Diese Folge kann leider nicht übernommen werden. |

"Erneut versuchen"/"Retry", "Abbrechen"/"Cancel" und "Schließen"/"Close" nutzen die bestehenden `download_error_retry` / `download_error_cancel` / `download_error_close`. Apostroph in EN als `’` oder `\'` escapen (aapt).

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `itunes.apple.com/lookup?id=…&entity=podcastEpisode&limit=200` | — | Live-Abruf 2026-10-09 | Felder wie im Ticket; `trackId` als JSON-Zahl > Int; `episodeContentType` = `audio`/`video`; Content-Type `text/javascript` |
| `HttpURLConnection` | API 1 | bestehend | `instanceFollowRedirects` folgt **nicht** ueber Protokollwechsel (http↔https) — Risiko bei Tracking-Redirects |
| `kotlinx.serialization.json.Json.parseToJsonElement`, `JsonPrimitive.longOrNull` | bereits eingebunden (`libs.kotlinx.serialization.json`) | bestehende Nutzung in `SoundCatalogRepositoryImpl` | Keine neue Dependency; kein OkHttp/org.json noetig |
| Cleartext-Policy | targetSdk ≥ 28 | Android-Default | Keine `network_security_config` im Manifest → `http://`-Adressen werfen `UnknownServiceException` (eine `IOException`) |

## Design-Entscheidungen

### 1. Orchestrierung in `LinkImportHandler` statt in `DownloadUrlEffect`

**Trade-off:** Die Kette (erkennen → Lookup → Download → Zuordnung) direkt in der Composable waere weniger Dateien, ist aber nicht unit-testbar — das Ticket verlangt Tests fuer die Zuordnung jedes Fehlerfalls und fuer Abbrechen. Ein neuer Handler ist eine zusaetzliche Klasse.
**Entscheidung:** `data/LinkImportHandler.kt`, analog zum bestehenden `FileOpenHandler` (gleiche Schicht, gleiche Injektionsart). Die Composable bleibt duenn: Handler aufrufen, Ergebnis rendern. Der Handler kennt Apple Podcasts konkret (`ApplePodcastsLink.parse`), kein Strategie-Interface fuer weitere Apps.

### 2. Metadaten-Fluss zum Bearbeiten-Dialog

**Trade-off:** (a) Vorschlag in einer separaten StateFlow neben der Uri; (b) Uri und Vorschlag gemeinsam in einem Wert; (c) Vorschlag in der Datei speichern (ID3 schreiben) — absurd.
**Entscheidung:** (b) `SharedImport(uri, suggestion)` ersetzt den Typ von `pendingMeditationImportUri` (nur innerhalb `NavGraph.kt`). Keine Synchronisationsgefahr zwischen zwei Flows. Das ViewModel bekommt `suggestion` als optionalen Parameter und wendet `ImportPrefill.preferring(suggestion)` **nach** `compute(...)` an — `compute` und `FileOpenHandler` bleiben unveraendert, ID3 bleibt Rueckfall pro Feld. `PendingImport.prefill` traegt danach den gemischten Wert; sonst aendert sich am Speichern nichts.

### 3. Lage des Parsings

**Entscheidung:** Link-Erkennung in der Domain (`ApplePodcastsLink`, reines Kotlin, ohne `java.net.URI`/`android.net.Uri`). JSON-Auswertung in der Infrastruktur (`ApplePodcastsLookupResponse`, `internal object`, pure Funktion über einen String) — JSON-Format ist ein Detail des Apple-Dienstes, kein Domain-Wissen. Beide ohne Netz testbar. Die fachliche Regel "Autor, sonst Podcast-Name" liegt wie auf iOS in der Domain (`PodcastEpisode.teacherSuggestion`); der Parser liefert nur Rohwerte.

### 4. Fehlermodell

**Entscheidung:** Zwei Ebenen.
- Dienste melden technische Ausgaenge: `UrlAudioDownloadError` (bestehend: `NotAudio`, `Http`, `Network`) und neu `PodcastEpisodeResolveError` (`NotReachable`, `Unavailable`). 403/429 werden **im Lookup-Impl** zu `NotReachable`, weil nur dort bekannt ist, dass es Apples Ratenlimit ist.
- `LinkImportHandler` bildet auf `LinkImportFailure` ab — abhaengig davon, ob es ein Podcast-Import ist:

| Ausgang | Link-Import | Podcast-Import |
|---|---|---|
| `ApplePodcastsLink.Podcast` | — | `PodcastWithoutEpisode` |
| Lookup `NotReachable` | — | `NotReachable` |
| Lookup `Unavailable` | — | `EpisodeUnavailable` |
| Download `Network` | `NotReachable` (neu, statt "Download fehlgeschlagen") | `NotReachable` |
| Download `Http(code)` | `DownloadFailed` (unveraendert, Retry) | `EpisodeUnavailable` |
| Download `NotAudio` | `NotAudio` (unveraendert) | `EpisodeUnavailable` |
| `CancellationException` | `Cancelled` (kein Dialog) | `Cancelled` |

`LinkImportFailure.canRetry` = `NotReachable`, `DownloadFailed`. Die UI liest nur `LinkImportFailure`, nie Exceptions.

### 5. Abbrechen ueber Lookup und Download

**Entscheidung:** `LinkImportHandler.cancel()` setzt ein `@Volatile cancelled`-Flag und ruft `cancel()` auf beiden Diensten (No-op, wenn inaktiv). Nach erfolgreichem Lookup prueft der Handler das Flag, bevor er den Download startet — sonst koennte ein Cancel genau zwischen den Schritten verloren gehen (der Downloader setzt `cancelled = false` zu Beginn von `download`). Gleiches Muster wie `UrlAudioDownloaderImpl` (single-import-Annahme, kein AtomicReference).

### 6. Retry wiederholt den ganzen Vorgang

**Entscheidung:** "Erneut versuchen" ruft `linkImportHandler.import(originalSharedUrl)` — inklusive Lookup. Beim Ratenlimit ist genau das gewollt; ein gecachtes `episodeUrl` waere unnoetige Zustandshaltung.

## Refactorings

1. **Fehlerdialoge aus `NavGraph.kt` herausziehen** (`LinkImportErrorDialogs.kt`) und von drei fast identischen `AlertDialog`-Composables auf zwei generische reduzieren. Noetig, weil sonst drei weitere Kopien dazukaemen und `NavGraph.kt` (929 Zeilen, 23 Top-Level-Funktionen) weiter waechst. Risiko: niedrig — reine Darstellung, Verhalten unveraendert; manuelle Pruefung der fuenf Dialoge.
2. **`DownloadUrlEffect` / Retry auf Handler umstellen.** Der Retry ruft heute `urlAudioDownloader.download(failedUrl)` direkt und baut das NotAudio-Flag selbst — wird zu `import(url)` + `LinkImportOutcome`. Risiko: mittel; bestehender Kommentar zur `LaunchedEffect(downloadUrl)`-Key-Garantie bleibt erhalten. Keine Compose-Tests vorhanden → manueller Durchlauf aller Fehlerpfade.

## Fachliche Szenarien

### AK: Folgenlink → Ladefenster → Bearbeiten-Dialog

- Gegeben: Messenger teilt `"Hoer mal https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344"`
  Wenn: Still Moment im Teilen-Menue gewaehlt wird
  Dann: Ladefenster erscheint, danach Bearbeiten-Dialog im Import-Modus
- Gegeben: Teilen-Text ist nur der Link
  Wenn: geteilt wird
  Dann: identisches Verhalten
- Gegeben: Link `https://podcasts.apple.com/de/podcast/id1528936478?i=1000792422344` (ohne Kurzname)
  Wenn: erkannt wird
  Dann: wird als Folge erkannt
- Gegeben: Lookup-Antwort enthaelt den Podcast-Eintrag (dessen `trackId` = Podcast-ID) und Folgen
  Wenn: die Folge mit `trackId == 1000792422344` gesucht wird
  Dann: wird nur unter Folgen-Eintraegen gesucht und gefunden

### AK: Vorschlaege Titel / Lehrer:in

- Gegeben: Lookup liefert `trackName = "MBCT - Achtsame Therapie gegen Depressionen"`, Podcast-Eintrag `artistName = "Deutschlandfunk Nova"`, die MP3 hat ID3-Titel "dlf_nova_123" und ID3-Artist "DLF"
  Wenn: der Bearbeiten-Dialog oeffnet
  Dann: Titel = Folgentitel, Lehrer:in = "Deutschlandfunk Nova"
- Gegeben: Podcast-Eintrag ohne `artistName` (oder leer), `collectionName = "Achtsam - Deutschlandfunk Nova"`
  Wenn: der Dialog oeffnet
  Dann: Lehrer:in = "Achtsam - Deutschlandfunk Nova"
- Gegeben: Folgentitel "Body Scan (20:34 Min.)"
  Wenn: der Dialog oeffnet
  Dann: Titel unveraendert "Body Scan (20:34 Min.)"
- Gegeben: Lookup liefert leeren `trackName`, die Datei hat ID3-Titel "Body Scan"
  Wenn: der Dialog oeffnet
  Dann: Titel = "Body Scan" (Rueckfall pro Feld)
- Gegeben: normaler Datei-Import (Teilen einer MP3)
  Wenn: der Dialog oeffnet
  Dann: Vorschlaege wie bisher aus ID3/Dateiname (kein Vorschlag uebergeben)

### AK: Nach Speichern normale Meditation, offline

- Gegeben: Podcast-Folge importiert und gespeichert
  Wenn: Flugmodus an und die Meditation gestartet wird
  Dann: sie spielt ab (Datei liegt im App-Container) — manueller Test

### AK: Datei direkt beim Anbieter

- Gegeben: Lookup liefert `episodeUrl = https://podcast-mp3.dradio.de/.../x.mp3`
  Wenn: geladen wird
  Dann: der Downloader wird mit genau dieser Adresse aufgerufen (Handler-Test mit Fake)
- Gegeben: Lookup liefert `episodeUrl = http://anbieter.example/folge.mp3`
  Wenn: geladen wird
  Dann: der Downloader wird mit `https://anbieter.example/folge.mp3` aufgerufen (Test fuer `PodcastEpisode.upgradeToHttps` + Handler-Test); eine `https://`-Adresse bleibt unveraendert

### AK: Abbrechen stoppt auch die Suche

- Gegeben: Lookup laeuft (Antwort blockiert)
  Wenn: Nutzer tippt "Abbrechen"
  Dann: Lookup endet mit `Cancelled`, kein Download startet, kein Fehlerdialog, kein Eintrag
- Gegeben: Lookup gerade fertig, Download noch nicht gestartet
  Wenn: Abbrechen genau dazwischen
  Dann: Download wird nicht gestartet, Ergebnis `Cancelled`
- Gegeben: Download der Folge laeuft
  Wenn: Abbrechen
  Dann: `Cancelled`, temporaere Datei wird nicht importiert (bestehendes Verhalten)
- Gegeben: ein Import wurde abgebrochen
  Wenn: derselbe Link erneut geteilt wird
  Dann: Import laeuft normal

### AK: Alle Laendervarianten

- Gegeben: Links mit `/de/`, `/us/`, `/gb/`, `/at/` und Host in Grossbuchstaben (`Podcasts.Apple.com`)
  Wenn: erkannt wird
  Dann: jeweils Folge mit denselben IDs
- Gegeben: `https://podcasts.apple.com/de/podcast/achtsam/id1528936478?l=en&i=1000792422344` (weitere Query-Parameter, andere Reihenfolge)
  Wenn: erkannt wird
  Dann: Folge erkannt
- Gegeben: `https://podcasts.apple.com/US/podcast/x/id1528936478?i=1000792422344`
  Wenn: der Lookup startet
  Dann: `country=us` (Laendersegment lowercase) wird mitgeschickt
- Gegeben: `https://example.com/podcast/id123?i=456`
  Wenn: erkannt wird
  Dann: kein Apple-Podcasts-Link → normaler Link-Import

### AK: Netz nur nach Teilen, ohne Kennungen

- Gegeben: Folgenlink mit Podcast-ID 1528936478
  Wenn: der Lookup startet
  Dann: angefragte Adresse ist exakt `https://itunes.apple.com/lookup?id=1528936478&entity=podcastEpisode&limit=200&country=de`, keine weiteren Parameter/Kennungs-Header
- Gegeben: geteilter Link ist kein Apple-Podcasts-Link
  Wenn: importiert wird
  Dann: der Lookup-Dienst wird nie aufgerufen

### AK: Ladefenster unveraendert

- Gegeben: Folgenlink geteilt
  Wenn: Lookup und Download laufen
  Dann: dasselbe Ladefenster wie beim Link-Import, ohne neue Texte (manuell)

### AK: Folge > 2 h

- Gegeben: Server liefert 64 MB Audio als Stream
  Wenn: der Downloader laedt
  Dann: die Datei im Cache hat genau 64 MB (Unit-Test; belegt Streaming ohne Gesamtpuffer). Manuell: echte 3-h-Folge (~170 MB) importieren

### AK: Ganzer Podcast

- Gegeben: `https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478`
  Wenn: geteilt wird
  Dann: Meldung "Bitte eine einzelne Folge teilen", nur "Schließen", kein Netzabruf

### AK: Gerade nicht erreichbar (Podcast-Import)

- Gegeben: Flugmodus, Folgenlink geteilt
  Wenn: Lookup wirft `IOException`
  Dann: "Gerade nicht erreichbar" mit "Erneut versuchen" + "Abbrechen"
- Gegeben: Lookup antwortet HTTP 403 bzw. 429
  Wenn: importiert wird
  Dann: "Gerade nicht erreichbar"
- Gegeben: Lookup ok, Download der Folge wirft Timeout (`SocketTimeoutException`)
  Wenn: importiert wird
  Dann: "Gerade nicht erreichbar"
- Gegeben: Meldung "Gerade nicht erreichbar", Netz wieder da
  Wenn: "Erneut versuchen"
  Dann: Ladefenster, Lookup + Download laufen erneut, danach Bearbeiten-Dialog

### AK: Gerade nicht erreichbar (bestehender Link-Import)

- Gegeben: Flugmodus, direkter MP3-Link geteilt
  Wenn: Download wirft `IOException`
  Dann: "Gerade nicht erreichbar" (statt "Download fehlgeschlagen"), Retry + Abbrechen
- Gegeben: direkter MP3-Link, Server antwortet 404
  Wenn: importiert wird
  Dann: weiterhin "Download fehlgeschlagen" mit Retry
- Gegeben: direkter Link auf HTML-Seite
  Wenn: importiert wird
  Dann: weiterhin "Keine Aufnahme gefunden"
- Gegeben: geteilter Text ohne Link
  Wenn: geteilt wird
  Dann: weiterhin "Kein Link gefunden"

### AK: Leider nicht moeglich

- Gegeben: Lookup-Antwort enthaelt die Folgen-ID nicht (aeltere Folge)
  Dann: "Leider nicht möglich", nur "Schließen"
- Gegeben: Folge hat `episodeContentType = "video"`
  Dann: "Leider nicht möglich"
- Gegeben: Folge ohne `episodeUrl` (z. B. Abo-Folge)
  Dann: "Leider nicht möglich"
- Gegeben: Lookup antwortet 200 mit kaputtem JSON / ohne `results`
  Dann: "Leider nicht möglich"
- Gegeben: Lookup antwortet HTTP 500 bzw. 404
  Dann: "Leider nicht möglich"
- Gegeben: Lookup ok, Episode-Download antwortet 404 (Datei beim Anbieter weg)
  Dann: "Leider nicht möglich"
- Gegeben: Lookup ok, Episode-Download liefert `text/html`
  Dann: "Leider nicht möglich"
- Gegeben: Folgen-ID mit 25 Ziffern (Long-Ueberlauf)
  Dann: kein Absturz, "Leider nicht möglich"

### AK: Retry nur wenn sinnvoll / nie still / keine Technikbegriffe / DE+EN / konsistent

- Gegeben: jeder Wert von `LinkImportFailure`
  Wenn: der Dialog gerendert wird
  Dann: genau `NotReachable` und `DownloadFailed` zeigen "Erneut versuchen"; jeder Fehlerausgang des Handlers fuehrt zu einem Dialog, nur `Cancelled` nicht (Handler-Test: jeder Pfad liefert `Imported`, `Failed` oder `Cancelled`)
- Gegeben: Geraetesprache DE bzw. EN
  Dann: Texte exakt wie in der Key-Tabelle (identisch zu iOS)

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **Link-Extraktion aus Text** (`UrlAudioValidatorTest`) — Voraussetzung fuer Messenger-Shares; klein, rein Domain.
2. **Link-Erkennung** (`ApplePodcastsLinkTest`) — Folge / ganzer Podcast / kein Apple-Link / Laendervarianten inkl. `country` / Long-IDs.
3. **Lookup-Parser** (`ApplePodcastsLookupResponseTest`) — Folge finden, Autor-Fallback, Video, fehlendes `episodeUrl`, kaputtes JSON. Testdaten als gekuerzte echte Antwort (Raw-String im Test).
4. **Resolver** (`ApplePodcastsEpisodeResolverTest`) — exakte URL inkl. `country`, 403/429 → `NotReachable`, 500 → `Unavailable`, `IOException`, Cancel.
5. **`ImportPrefill.preferring`** (`ImportPrefillTest`).
6. **`LinkImportHandler`** (`LinkImportHandlerTest`) — komplette Zuordnungstabelle aus Design-Entscheidung 4, Cancel in drei Phasen, kein Lookup bei Nicht-Apple-Link, Download mit `episodeUrl` (http → https), Vorschlag im `Imported`-Ergebnis.
7. **ViewModel** (`GuidedMeditationsListViewModelTest`) — `importMeditation(uri, suggestion)` → Draft-Werte; ohne Vorschlag unveraendert.
8. **Downloader-Grossdatei-Test** (`UrlAudioDownloaderTest`) — sollte sofort gruen sein (Charakterisierung).
9. **UI-Verdrahtung** — Strings, `LinkImportErrorDialogs.kt`, `DownloadUrlEffect`/Retry, `MainActivity`, `AppModule`. Manuelle Pruefung aller Dialoge (Emulator), `make check`.
10. **Doku** — CHANGELOG, Glossar (Begriff "Podcast-Import": Unterart des Link-Imports, loest Apple-Podcasts-Folgenlink ueber Apples Lookup-Dienst zur Audiodatei auf; Android-Dateireferenzen), Konzept-Dokument (Vorab-Pruefung ist iOS-Sache; Android-Teil: Teilen per Messenger/Browser).

## detekt-Fallstricke

- **LongMethod (60):** `DownloadUrlEffect` waechst durch Retry ueber den Handler → Import-Lauf in eine lokale `suspend`-Funktion oder kleinen Helper auslagern; Dialog-Auswahl in `LinkImportErrorDialog`. `LinkImportHandler.import` in `importPodcastEpisode` / `importDirectLink` + Mapping-Funktionen splitten.
- **MultipleEmitters:** jede Dialog-Composable emittiert genau einen `AlertDialog`; der Dispatcher `LinkImportErrorDialog` ruft per `when` genau eine davon auf (eine Verzweigung = ein Emitter).
- **TooManyFunctions (15 pro Datei):** `NavGraph.kt` hat bereits 23 Top-Level-Funktionen → neue Dialoge nicht dort, sondern in `LinkImportErrorDialogs.kt`.
- **ReturnCount (4):** `ApplePodcastsLink.parse` und der Parser haben viele Abbruchbedingungen → `?.let`/`takeIf`-Ketten oder Teilfunktionen; ausgenommen sind nur Lambdas/Labels.
- **MagicNumber:** HTTP 403/429 als benannte Konstanten (`HTTP_FORBIDDEN` existiert in `HttpURLConnection`; 429 als `private const val HTTP_TOO_MANY_REQUESTS = 429`), `limit=200` als Konstante.
- **TooGenericExceptionCaught / SwallowedException:** im Parser `SerializationException` und `IllegalArgumentException` gezielt fangen (nicht `Exception`), und loggen.
- **LongParameterList (8):** `StillMomentNavHost` tauscht nur einen Parameter (Handler statt Downloader) → keine neue Zahl.

## Risiken

| Risiko | Mitigation |
|---|---|
| Messenger-Text-Format unbekannt (Link in Klammern, mit Zeilenumbruch, `<...>`) | Token-Extraktion bis Whitespace + Abschneiden gaengiger Satzzeichen; Tests mit realistischen Texten; manueller Test mit Signal/WhatsApp/Telegram |
| Podcast in keinem Store des Link-Landes gelistet → 0 Treffer → "Leider nicht möglich" | `country` aus dem Link wird mitgeschickt (entschieden); Rest akzeptiert |
| Tracking-Redirects mit Protokollwechsel (http↔https) werden von `HttpURLConnection` nicht verfolgt → 30x → "Leider nicht möglich" | Manuell mit mehreren Podcasts (Tara Brach, Achtsam) pruefen; bei Bedarf Follow-up (begrenzt manuelles Redirect-Folgen) |
| Anbieter ohne https-Unterstuetzung: nach Umschreiben auf `https://` schlaegt die Verbindung fehl (SSL-/Connect-Fehler = `IOException`) → "Gerade nicht erreichbar" | Selten; bewusst in Kauf genommen (beide Plattformen gleich). Bei Haeufung Follow-up |
| `MalformedURLException` (eine `IOException`) aus kaputtem `episodeUrl` → "nicht erreichbar" | Parser akzeptiert `episodeUrl` nur mit `https?://`-Praefix, sonst `EpisodeUnavailable` |
| Apple-Ratenlimit (~20/min) beim Testen | Tests ohne Netz; manuelle Tests sparsam |
| Cancel-Race zwischen Lookup und Download | Flag-Pruefung im Handler vor Download-Start, eigener Test |
| Refactor von `DownloadUrlEffect` ohne Compose-Tests | Logik in den Handler verschoben (unit-getestet); manueller Durchlauf aller 5 Dialoge + Retry + Cancel |
| Grosse Dateien im `cacheDir` bleiben nach Abbruch/Fehler im Dialog liegen | Bestehendes Verhalten; nicht Teil dieses Tickets |

## Offene Fragen

Alle Punkte vom 2026-10-09 entschieden (Koordination):

- [x] `&country=<land>` aus dem Link → ja, erstes Pfadsegment.
- [x] `http://`-`episodeUrl` → vor dem Download auf `https://` umschreiben, beide Plattformen.
- [x] Retry-Text → bestehender Key `download_error_retry` ("Erneut versuchen"/"Retry"), kein "Try Again".
- [x] Link aus Fliesstext → erster http(s)-Link, fuer den ganzen Link-Import; iOS braucht es nicht.
- [x] Typnamen an iOS angeglichen: `ApplePodcastsLink`, `PodcastEpisode` (`podcastAuthor`, `podcastName`, `teacherSuggestion`), `PodcastEpisodeResolverProtocol`/`ApplePodcastsEpisodeResolver`, `ApplePodcastsLookupResponse`, `PodcastEpisodeResolveError` (`NotReachable`, `Unavailable`; Abbruch als `CancellationException` statt eigenem Case), Meldungs-Faelle `NotReachable`, `PodcastWithoutEpisode`, `EpisodeUnavailable` (iOS: Cases in `InboxError`, Android: `LinkImportFailure`).
- Hinweis an iOS: Android-Resolver bekommt den ganzen `ApplePodcastsLink.Episode` (inkl. `country`); iOS-Signatur `resolveEpisode(podcastId:episodeId:)` braucht ebenfalls das Land.
