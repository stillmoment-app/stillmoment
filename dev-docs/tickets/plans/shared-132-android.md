# Implementierungsplan: shared-132 (Android)

Ticket: shared-132 — Mehrfaches Teilen an Still Moment: kein Fehler, der zuletzt geteilte Eintrag gewinnt
Plattform: Android
Erstellt: 2026-10-09

## Kurzfassung

Die Hypothese aus dem Ticket („Android verhält sich schon so“) stimmt **innerhalb einer
laufenden App-Instanz** für die drei Fälle im Ergebnis: kein Fehler, ein Import, der neueste
Link gewinnt. Sie beruht aber auf impliziter StateFlow-/LaunchedEffect-Semantik, die kein Test
absichert, und hat drei echte Lücken:

1. **Abgelöster Download läuft weiter.** Teilt man 25402, während 25401 lädt, wird nur die
   Coroutine von 25401 abgebrochen, nicht die blockierende Verbindung. 25401 lädt im Hintergrund
   vollständig weiter, bleibt als Datei im Cache liegen und setzt beim Ende die
   Verbindungs-Referenz des Downloaders zurück. Folge: „Abbrechen“ im Ladefenster von 25402
   wirkt erst, wenn 25402 komplett geladen ist.
2. **„Erneut versuchen“ wird von einem neuen Teilen nicht abgelöst.** Ein Retry läuft in einem
   eigenen Scope parallel zum neu geteilten Link. Scheitert der Retry, erscheint eine
   Fehlermeldung, obwohl der neuere Link noch lädt. Außerdem gewinnt der zuletzt *fertige*, nicht
   der zuletzt *geteilte* Link, und das Ladefenster verschwindet zu früh.
3. **Unverifiziert: Erreicht ein zweites Teilen überhaupt dieselbe Activity?** `MainActivity`
   hat keinen `launchMode` (Standard). Je nach Intent-Flags der teilenden App kann ein zweites
   Teilen eine **zweite** MainActivity-Instanz erzeugen (eigene StateFlows, eigene NavHost, zwei
   parallele Imports, im schlimmsten Fall zwei Einträge) oder bei gleicher Intent-Signatur
   **verworfen** werden (25402 käme nie an). Das lässt sich nur am Gerät klären. Ich weiß nicht,
   welche Flags Chrome und die Dateien-App setzen.

## Annahmen

- „Bevor die App den Eintrag übernommen hat“ heißt auf Android: solange der Link-Import lädt.
  Eine Share-Inbox gibt es auf Android nicht. Das Teilen wird sofort von der App übernommen.
- Ein zweites Teilen, nachdem das Bearbeiten-Blatt schon offen ist, ist nicht Gegenstand des
  Tickets. Heute ersetzt es das offene Blatt (siehe AK-2). Das bleibt so.
- Gemischter Fall „Datei teilen, während ein Link lädt“ ist nicht Teil der Akzeptanzkriterien.
  Er wird durch die neue Komponente mit erledigt, wenn es ohne Mehraufwand geht (siehe Offene Fragen).
- Das 24-h-Aufräumen ist iOS-spezifisch (`ios/StillMoment/Application/InboxHandler.swift:106-107,177`).
  Android hat keine wartenden geteilten Einträge, also nichts aufzuräumen. Das Kriterium ist auf
  Android nicht anwendbar und wird nicht angefasst.

## Befund pro Akzeptanzkriterium (Code-Stand `fea4051f`)

| AK | Befund | Belege |
|----|--------|--------|
| AK-1 Gleiche Adresse zweimal, während sie lädt | **Korrekt (eine Instanz vorausgesetzt), ungetestet.** Das zweite Teilen setzt `_pendingDownloadUrl` auf den gleichen Wert. StateFlow sendet gleiche Werte nicht erneut, der Effekt startet nicht neu. Geleert wird die URL erst nach dem Import. Nach dem Import landet ein erneutes Teilen im normalen Ablauf: ein neuer Download, dann „Schon da“ oder ein ersetztes Blatt. | `MainActivity.kt:160-161`, `NavGraph.kt:711-716` |
| AK-2 Gleiche Audiodatei zweimal (Datei-Share via `EXTRA_STREAM`) | **Korrekt (eine Instanz vorausgesetzt), ungetestet.** `FileOpenEffect` leert die URI sofort, beide Shares werden validiert. `pendingMeditationImportUri` dedupliziert gleiche `SharedImport`s (data class). Kommt das zweite Teilen nach der Übergabe, ruft die Bibliothek `importMeditation` erneut auf. Das überschreibt `pendingImport`/`selectedMeditation`, es bleibt ein Blatt und ein Eintrag. Nach dem Speichern greift „Schon da“. | `MainActivity.kt:129-139`, `NavGraph.kt:765-770`, `NavGraph.kt:427-430`, `GuidedMeditationsListViewModel.kt:272-297` |
| AK-3 25401, dann 25402 während des Ladens | **Ergebnis korrekt, Weg fehlerhaft.** Der Schlüsselwechsel bricht die Coroutine von 25401 ab. `withContext` verwirft deren Ergebnis, kein Fehlerdialog, 25402 wird importiert. **Aber:** `handler.cancel()` wird nicht gerufen, der blockierende `HttpURLConnection`-Read von 25401 läuft weiter (`UrlAudioDownloaderImpl.kt:96-141`). Die fertige Datei bleibt im Cache (`:159-178`, `succeeded = true`). Das `finally` von 25401 setzt `currentConnection = null` (`:139`), deshalb unterbricht „Abbrechen“ für 25402 die Verbindung nicht mehr (`:182-187`). **Retry-Lücke:** `scope.launch { runImport(...) }` (`NavGraph.kt:727`) hängt nicht am Effekt-Schlüssel und wird von einem neuen Teilen nicht abgebrochen. Scheitert der Retry, setzt er `failed` und zeigt einen Fehler (`:706`). | `NavGraph.kt:700-728` |
| AK-4 iOS = Android | **Abweichung.** iOS übernimmt keinen neuen geteilten Eintrag, solange ein Import läuft (`InboxHandler.swift:84`, `guard !isProcessing`). Der neue Eintrag wartet bis zur nächsten Aktivierung. Android ersetzt den laufenden Import. Siehe Offene Fragen. | |
| AK-5 „Schon da“ | **Korrekt, getestet.** Doppelprüfung über Dateiname und Größe vor dem Bearbeiten-Blatt, gilt auch für geladene Links. | `FileOpenHandler.kt:100-103,136-148`, `GuidedMeditationsListViewModel.kt:302`, `FileOpenHandlerTest.kt` |
| AK-6 Einzel-Teilen inkl. Fehlermeldungen und „Erneut versuchen“ | **Korrekt, getestet** (Abbildung der Fehler und Retry-Fähigkeit). Die Dialog-Verdrahtung in `DownloadUrlEffect` hat keine Tests. | `LinkImportHandler.kt:60-118`, `LinkImportHandlerTest.kt`, `UrlAudioDownloaderTest.kt` |
| AK-7 24-h-Aufräumen | **Auf Android nicht anwendbar** (keine Inbox). | — |
| Voraussetzung: ein Teilen landet in derselben Instanz | **Unverifiziert.** Kein `launchMode` am Activity-Eintrag. `onNewIntent` (`MainActivity.kt:119-122`) wird bei Standard-Launch-Mode nur unter bestimmten Intent-Flags aufgerufen. | `AndroidManifest.xml:24-29` |

Nebenbefund, außerhalb des Tickets: Auch erfolgreich importierte Downloads bleiben unter
`cacheDir/dl_*` liegen. Android räumt sie nie selbst weg, iOS schon
(`InboxHandler.swift:268-273`). Kandidat für ein eigenes Ticket.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/SharedLinkImport.kt` | Presentation (Wiring, wie `PlayerCompletionWiring`) | Neu | Plain-Kotlin-Klasse mit der Regel „zuletzt geteilt gewinnt, gleicher Link nur einmal“. Hält den laufenden Import-Job, Ladezustand und Fehler. Unit-testbar. |
| `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/NavGraph.kt` (`DownloadUrlEffect`, `:686-732`) | Presentation | Refactoring | Wird zur dünnen Bindung an `SharedLinkImport`. Retry läuft über dieselbe Komponente. |
| `android/app/src/test/kotlin/com/stillmoment/presentation/navigation/SharedLinkImportTest.kt` | Test | Neu | Fachliche Szenarien AK-1, AK-3, Retry, Fehler und Abbrechen (Fake-Import-Funktion, `runTest`) |
| `android/app/src/main/AndroidManifest.xml` (`:24-29`) | Manifest | Bedingt | `android:launchMode="singleTask"`, nur falls Schritt 0 mehrere Instanzen oder verworfene Intents zeigt |
| `LinkImportHandler.kt`, `UrlAudioDownloaderImpl.kt` | Data/Infra | Unverändert | Durch „abbrechen und warten, dann neu starten“ bleibt die Annahme „nur ein Download gleichzeitig“ erhalten. Die Klassen brauchen keine Änderung. |
| `FileOpenHandlerTest.kt` / `GuidedMeditationsListViewModelTest` | Test | Ergänzen | Absicherung AK-2: Dieselbe Datei zweimal an die Bibliothek gegeben ergibt ein Blatt und einen gespeicherten Eintrag. |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `Job.cancelAndJoin()` | kotlinx.coroutines 1.x | kotlinx.coroutines Docs | Wartet, bis der abgebrochene Import wirklich beendet ist. Der blockierende Read endet erst durch `handler.cancel()` (`disconnect()`), deshalb vorher `handler.cancel()` rufen. |
| `android:launchMode="singleTask"` | API 1 | developer.android.com/guide/topics/manifest/activity-element#lmode | Eine Instanz im eigenen Task, neue Intents über `onNewIntent`. Der Rücksprung zur teilenden App beim Zurück-Wischen ist am Gerät zu prüfen. |
| `FLAG_ACTIVITY_NEW_TASK` bei Standard-Launch-Mode | — | Intent-Docs | Passt der Root-Intent eines vorhandenen Tasks (`filterEquals` ignoriert Extras), kommt der Task nur nach vorn und der **neue Intent wird verworfen**. Darum Schritt 0. |

## Design-Entscheidungen

### 1. Regel explizit in einer testbaren Komponente statt impliziter StateFlow-Gleichheit

**Trade-off:** Heute ergibt sich „gleicher Link nur einmal“ daraus, dass StateFlow gleiche Werte
nicht erneut sendet und die URL erst nach dem Import geleert wird. „Neuer Link ersetzt“ ergibt
sich aus dem `LaunchedEffect`-Schlüsselwechsel. Beides steckt in einem privaten Composable, ist
ohne Compose-UI-Test nicht testbar und hat die Retry-Lücke. Ein Minimal-Fix (Retry-Job beim neuen
Teilen abbrechen, `handler.cancel()` beim Schlüsselwechsel) wäre ein paar Zeilen, aber
ungetestet. Und `handler.cancel()` im `finally` des alten Effekts liefe gegen den bereits
gestarteten neuen Download: Race, der neue würde abgebrochen.
**Entscheidung:** Kleine Klasse `SharedLinkImport` nach dem Muster von `PlayerCompletionWiring`.
Konstruktor: `CoroutineScope`, `import: suspend (String) -> LinkImportOutcome`,
`cancelRunning: () -> Unit` (= `linkImportHandler::cancel`), `onImported: (SharedImport) -> Unit`.
Zustand: `isLoading: StateFlow<Boolean>`, `failure: StateFlow<FailedLinkImport?>`.
- `share(url)`: Lädt gerade derselbe Link, passiert nichts. Sonst wird der Fehlerdialog
  geschlossen, der laufende Import abgelöst und `url` gestartet.
- `retry()`: startet den fehlgeschlagenen Link neu, läuft über denselben Job.
- `cancel()` (Ladefenster): `cancelRunning()` wie bisher, Ergebnis `Cancelled`, keine Meldung.
- Ablösen: `cancelRunning()` aufrufen, alten Job `cancelAndJoin()`, **erst dann** den neuen
  Import starten. Es läuft nie mehr als ein Download. Der alte bricht seine Verbindung ab und
  löscht seine Teildatei (vorhandenes Verhalten `UrlAudioDownloaderImpl.kt:176-178`). Die
  Verbindungs-Referenz wird nicht mehr überschrieben.
- Ein abgelöster Import liefert nie eine Meldung und ruft nie `onImported`. `isLoading` spiegelt
  nur den aktuellen Import.

`MainActivity` bleibt die Quelle der geteilten URL. `DownloadUrlEffect` reicht jede neue URL an
`share(url)` weiter und leert `pendingDownloadUrl` sofort. Die Deduplizierung steckt jetzt in der
Regel, nicht mehr im Timing des Leerens.

### 2. `launchMode` nur nach Gerätenachweis

**Trade-off:** `singleTask` garantiert, dass jedes Teilen bei der einen Instanz ankommt. Es
ändert aber das Task-Verhalten der ganzen App, etwa den Rücksprung zur teilenden App und
„Öffnen mit“ aus der Dateien-App. Ohne Nachweis wäre das eine Änderung auf Verdacht.
**Entscheidung:** Schritt 0 prüft am Gerät. Nur wenn ein zweites Teilen eine zweite Instanz
erzeugt oder verworfen wird, kommt `singleTask` hinzu, mit manuellem Regressionstest von „Öffnen
mit“ und Zurück-Navigation.

## Refactorings

1. **`DownloadUrlEffect` → `SharedLinkImport`**: Import-Ablauf, Fehlerzustand und Retry ziehen
   aus dem Composable in die neue Klasse. Begründung: AK-3 (Retry-Lücke, Ablösen ohne Race) ist
   im Composable nicht sauber testbar umsetzbar.
   - Risiko: gering bis mittel. Der Bereich hat heute keine Tests. Die neuen Szenario-Tests
     decken ihn danach ab. `LinkImportHandler` und Downloader bleiben unverändert, ihre Tests
     bleiben gültig.

## Fachliche Szenarien

### Schritt 0 (vor dem Code): Verifikation am Gerät
- Gegeben: Still Moment ist geschlossen. Wenn: in Chrome zweimal hintereinander denselben
  audiodharma-Link teilen (zwischen den Teilen mit Zurück zu Chrome, sofern nötig). Dann
  notieren: Gibt es eine oder zwei MainActivity-Instanzen
  (`adb shell dumpsys activity activities`, Abschnitt `com.stillmoment`)? Wie oft erscheint
  `Downloaded … bytes` im Logcat-Tag `UrlDownload`?
- Dasselbe mit 25401, dann 25402, und mit der Dateien-App (eine MP3 zweimal teilen).
- Ein Ergebnis aus einer Instanz und ein Download: kein Manifest-Eingriff. Sonst Design-Entscheidung 2.

### AK-1: Dieselbe Adresse zweimal, während sie lädt
- Gegeben: Link A lädt. Wenn: A wird erneut geteilt. Dann: Es wird nicht neu geladen, das
  Ladefenster bleibt, am Ende öffnet sich genau ein Bearbeiten-Blatt.
- Gegeben: A ist fehlgeschlagen, der Fehler wird angezeigt. Wenn: A wird erneut geteilt. Dann:
  Der Fehler verschwindet, A lädt neu (das ist kein Doppel-Import).

### AK-2: Dieselbe Audiodatei zweimal
- Gegeben: Eine Datei wurde geteilt, das Bearbeiten-Blatt ist offen. Wenn: dieselbe Datei wird
  erneut übergeben. Dann: genau ein Blatt; nach dem Speichern genau ein Eintrag, keine Meldung.
- Gegeben: Die Datei ist schon gespeichert. Wenn: Sie wird erneut geteilt. Dann: „Schon da“
  (vorhandener Test, nur prüfen).

### AK-3: 25401, dann 25402 während des Ladens
- Gegeben: 25401 lädt. Wenn: 25402 wird geteilt. Dann: 25401 wird abgebrochen, keine Meldung,
  25402 lädt, das Blatt öffnet sich für 25402.
- Gegeben: 25401 lädt. Wenn: 25402 wird geteilt und der abgelöste Import von 25401 endet mit
  einem Fehler. Dann: keine Meldung.
- Gegeben: 25402 hat 25401 abgelöst und lädt. Wenn: Der User tippt „Abbrechen“. Dann: Der
  Import endet sofort ruhig, kein Blatt, keine Meldung (Regression zum heutigen Verhalten).
- Gegeben: 25401 ist fehlgeschlagen, „Erneut versuchen“ läuft. Wenn: 25402 wird geteilt. Dann:
  Der Retry wird abgelöst. Scheitert er, gibt es keine Meldung. Importiert wird 25402.
- Gegeben: 25401 lädt. Wenn: 25402 wird geteilt. Dann: Das Ladefenster bleibt durchgehend
  sichtbar und schließt erst mit dem Ergebnis von 25402.

### AK-6 (Erhalt): Einzelnes Teilen
- Gegeben: Ein Link wird geteilt. Wenn: Der Import scheitert mit „nicht erreichbar“. Dann:
  Meldung mit „Erneut versuchen“. Ein Tipp darauf lädt denselben Link erneut, Erfolg öffnet das Blatt.
- Gegeben: Ein Link wird geteilt. Wenn: Der User tippt „Abbrechen“. Dann: keine Meldung, kein Blatt.
- Gegeben: Ein Link wird geteilt. Wenn: Import erfolgreich. Dann: Das Blatt öffnet sich mit dem
  Vorschlag (Podcast-Titel und -Autor bleiben erhalten).

## Reihenfolge der Akzeptanzkriterien

1. **Schritt 0: Gerät verifizieren.** Bestimmt, ob das Manifest angefasst wird.
2. **AK-1 und AK-6 als Charakterisierung in `SharedLinkImportTest`** (rot, weil die Klasse fehlt),
   dann `SharedLinkImport` minimal implementieren.
3. **AK-3 einzeln per TDD:** Ablösen ohne Meldung, Ladefenster durchgehend, Abbrechen nach
   Ablösen, Retry wird abgelöst.
4. **`DownloadUrlEffect` auf `SharedLinkImport` umstellen.** Fehlerdialog und Ladefenster
   binden an deren StateFlows.
5. **AK-2 Absicherungstest** (Bibliothek: dieselbe Datei zweimal ergibt einen Eintrag).
6. **Bedingt: `launchMode`**, falls Schritt 0 es erfordert, plus manuelle Regression.
7. **Manueller Test aus dem Ticket (Schritt 6)** am Gerät, `make check`, `make test-unit-agent`.

## Offene Fragen

- [ ] **Regel bei laufendem Import, iOS und Android (AK-4).** Android: Ein neuer anderer Link
  ersetzt den laufenden Import. iOS übernimmt während eines laufenden Imports keinen neuen
  Eintrag (`InboxHandler.swift:84`), der neue wartet bis zur nächsten Aktivierung.
  **Empfehlung:** Beide Plattformen folgen „der zuletzt geteilte gewinnt, auch während des
  Ladens“. Das muss der iOS-Plan klären oder bewusst als Plattformunterschied festhalten.
- [ ] **Refactoring statt Minimal-Fix?** Alternative: Retry-Job und `handler.cancel()` direkt im
  Composable, ohne Unit-Tests, nur manuell geprüft. **Empfehlung:** `SharedLinkImport`. Die
  Regel ist der Kern des Tickets und soll getestet sein, und der Minimal-Fix hat das oben
  beschriebene Race.
- [ ] **Datei teilen, während ein Link lädt.** Heute lädt der Link weiter und überschreibt
  danach das Blatt der Datei. Gewinnen würde also der früher geteilte Link. **Empfehlung:** mit
  erledigen (`FileOpenEffect` ruft vor der Übergabe `sharedLinkImport.cancel()`), ein Szenario
  mehr. Falls das als Scope-Ausweitung gilt: Follow-up-Ticket.
- [ ] **Cache-Aufräumen `dl_*` nach erfolgreichem Import** (Nebenbefund). **Empfehlung:** eigenes Ticket.
- Hinweis: Den Plan-Verweis im Ticket (Skill-Schritt 7) habe ich auftragsgemäß nicht eingetragen.
