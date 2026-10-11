# Implementierungsplan: shared-138 (Android)

Ticket: shared-138

## Entscheidungen (verbindlich, mit dem User geklärt)

- **Regel:** Was die App begonnen hat (Laden, Bearbeiten-Blatt, Meldung), führt sie zu Ende. Ein währenddessen geteilter Eintrag wartet und startet danach von selbst. Höchstens ein wartender Eintrag, der zuletzt geteilte gewinnt. Nach „Abbrechen“ im Ladefenster startet der wartende.
- **Jedes Bearbeiten-Blatt zählt**, auch das Blatt einer vorhandenen Meditation (Edit-Modus: `showEditSheet()` meldet Beginn, `hideEditSheet`/`updateMeditation` das Ende) und ein Import über den Datei-Wähler „+“.
- **Derselbe Eintrag erneut geteilt, solange er läuft (Laden, Blatt oder Meldung): ignorieren.** Kein zweiter Import, kein nachgeschobenes „Schon da“. Gilt auch für einen fehlgeschlagenen Link, dessen Meldung offen ist (die Meldung bleibt, „Erneut versuchen“ ist der Weg). Ein *anderer* wartender Eintrag bleibt unberührt. Für Dateien klären, woran „derselbe“ erkennbar ist (Content-URIs können sich pro Teilen unterscheiden) — an der bestehenden Duplikat-Logik aus shared-132 („the same file handed over twice“) orientieren; iOS vergleicht Name + Größe.
- **„Öffnen mit“ zählt wie Teilen.**
- **„Erneut versuchen“ setzt den begonnenen Import fort**; der wartende Eintrag wartet weiter.
- **Nicht unterstütztes Format** und „Kein Link gefunden“ werden sofort gemeldet und werden nie zum wartenden Eintrag.
- **Ablöse-Zweig in `GuidedMeditationsListViewModel.importMeditation` löschen** (samt Test) statt als toten Code zu behalten — das Gate verhindert den Fall.
- **Tab-Wechsel bei offenem Blatt, dann teilen:** Eintrag wartet, bis das Blatt abgeschlossen ist. Kein automatisches Zurückwechseln in diesem Ticket.
- Begriff plattformübergreifend: **„wartender Eintrag“** (EN *waiting share*).

## Befunde (verifiziert)

| Befund | Beleg |
|---|---|
| `SharedLinkImport.share(url)` löst einen laufenden Import ab (`start()`: vorigen Job abbrechen, `join`, neu laden). Gleicher Link während des Ladens wird ignoriert (`loadingUrl`). | `presentation/navigation/SharedLinkImport.kt` |
| `ImportedLinkEffect` und `FileOpenEffect.onValidFile` schreiben direkt in `pendingMeditationImportUri`; `MeditationImportNavigationEffect` navigiert; die Bibliothek leert und ruft `importMeditation`. | `NavGraph.kt` |
| `pendingMeditationImportUri` ist ein Compose-`remember` — geht bei Activity-Recreation verloren. Mit einem Gate bliebe der Import dann für immer „beschäftigt“. Übergabe muss ins ViewModel. | `NavGraph.kt` |
| `importMeditation` ersetzt ein offenes Import-Blatt und verwirft dessen Download. | `GuidedMeditationsListViewModel.kt` |
| „Schon da“/Importfehler sind Snackbars; `clearError()` läuft, wenn `showSnackbar` zurückkehrt. Fehler liegt im ViewModel (überlebt Recreation) — verlässliches „Meldung geschlossen“. | `GuidedMeditationsListScreen.kt` |
| Link-Fehlerdialog: `failure` in `SharedLinkImport`, `dismissFailure`, `retry()`. | `NavGraph.kt` |
| `MainActivity._pendingFileUri`/`_pendingDownloadUrl` sind kurzlebige Weiterleitungen. | `MainActivity.kt` |
| `FileOpenHandler.validateFileFormat(uri)` ist synchron. | `data/FileOpenHandler.kt` |
| Import-Blatt ist ein Overlay; Tab-Leiste bleibt sichtbar. | `NavGraph.kt`, `MeditationEditSheet.kt` |
| Kein androidTest prüft das Teilen; altes Ablösen nur in Unit-Tests. | — |
| detekt `LongParameterList.constructorThreshold: 10`: Bibliotheks-ViewModel hat 9, mit Gate 10. | `config/detekt/detekt.yml` |

## Annahmen

- „Beschäftigt“ beginnt beim Start eines Eintrags und endet erst mit Abschluss: Blatt gespeichert/verworfen, „Schon da“/Import-Snackbar geschlossen, Link-Fehlerdialog geschlossen, „Abbrechen“. Ein fertig geladener Link, der noch auf die Bibliothek wartet, ist beschäftigt.
- Wiedergabe stoppt erst bei Übergabe an die Bibliothek, nicht schon beim Teilen.
- Prozess-Tod ist nicht Teil des Tickets; wartende Einträge leben im ActivityRetained-Scope.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/navigation/SharedEntryGate.kt` | Presentation (Wiring) | Neu | `@ActivityRetainedScoped class SharedEntryGate @Inject constructor()`, reines Kotlin; `sealed interface SharedEntry { Link(url); File(uri) }`. API siehe Entscheidung 1. Logging über `LoggerProtocol` (busy/released) zur Diagnose. |
| `presentation/navigation/SharedLinkImport.kt` | Presentation | Ändern | Parameter `onEnded`, aufgerufen in `cancel()`, `dismissFailure()`, bei `Cancelled`. Ablöse-Zweig und `loadingUrl`-Duplikatprüfung entfallen. `previous?.join()` bleibt (nach „Abbrechen“ startet der nächste Download erst, wenn der alte wirklich beendet ist). KDoc anpassen. |
| `presentation/viewmodel/SharedLinkImportViewModel.kt` → `SharedImportViewModel.kt` | Presentation | Umbenennen + Erweitern | Injiziert Gate, sammelt `gate.toStart`: Link → `linkImport.share(url)`, Datei → `handover`. `share(entry)` → Gate. `importedLink`/`consumeImportedLink` → `handover: StateFlow<SharedImport?>` + `consumeHandover()` für Links und Dateien. Verwerfen-bei-Ablösen entfällt. |
| `SharedImport` (heute privat in `NavGraph.kt`) | Presentation | Verschieben | Nicht mehr privat. |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | Presentation | Erweitern | Gate injizieren (`@Suppress("LongParameterList")` mit Begründung). Beginn melden in `importMeditation` (erstmals) und `showEditSheet()`. Private `endImportIfSettled()`: kein Blatt offen, keine Meldung, Import angemeldet → `gate.importEnded()`. Aufruf nach abgeschlossenem Speichern, in `cancelImport()`, `hideEditSheet`/`updateMeditation`, `clearError()`. Ablöse-Zweig löschen. |
| `presentation/navigation/NavGraph.kt` | Presentation | Ändern | `pendingMeditationImportUri` entfällt; `vm.handover`/`vm::consumeHandover` an `NavHostScaffold`. `ImportedLinkEffect` + `MeditationImportNavigationEffect` → ein `SharedImportHandoverEffect`. `FileOpenEffect.onValidFile` → `vm.share(SharedEntry.File(uri))`, `DownloadUrlEffect` → `vm.share(SharedEntry.Link(url))`. |
| `MainActivity.kt`, `LinkImportHandler.kt`, `UrlAudioDownloaderImpl.kt`, `ImportDownloads*` | — | Unverändert | — |
| `test/.../navigation/SharedEntryGateTest.kt` | Test | Neu | Reine Regeltests. |
| `test/.../navigation/SharedLinkImportTest.kt` | Test | Umschreiben | Siehe Refactorings. |
| `test/.../viewmodel/SharedLinkImportViewModelTest.kt` → `SharedImportViewModelTest.kt` | Test | Umschreiben + Erweitern | Echtes Gate + echter `SharedLinkImport` + `LinkImportHandler` mit `ControlledDownloader` + `FakeImportDownloads`. |
| `GuidedMeditationsListViewModelTest.kt`, `LibraryDurationFilterViewModelTest.kt` | Test | Anpassen + Ergänzen | Konstruktor mit Gate; Tests zu Beginn/Ende. |
| `dev-docs/reference/glossary.md` | Doku | Ändern | Absatz „Android … löst einen noch ladenden ab“ korrigieren; „wartender Eintrag“. **Abstimmen mit iOS-Branch** (gleiche Stelle — plattformneutral formulieren). |

## API-Recherche

| API | Quelle | Hinweis |
|---|---|---|
| `@ActivityRetainedScoped` | developer.android.com/training/dependency-injection/hilt-android#component-scopes | Lebt wie ein Activity-ViewModel, überlebt Konfigurationswechsel, endet bei `finish()`. In jedem `@HiltViewModel` injizierbar. **Nicht** `@Singleton` (veralteter „beschäftigt“-Zustand nach Zurück + erneutem Teilen). Neu im Projekt → am Gerät prüfen, dass beide ViewModels dieselbe Instanz bekommen. |
| `MutableStateFlow` | kotlinx.coroutines | `toStart` nach Übernahme auf `null` zurücksetzen, sonst wird derselbe Eintrag nicht erneut emittiert. |
| `Job.join()` unter `NonCancellable` | kotlinx.coroutines | Besteht in `SharedLinkImport.start`; verhindert parallele Downloads nach „Abbrechen“. |

## Design-Entscheidungen

### 1. Eine Klasse `SharedEntryGate` statt verteilter Compose-Effekte
Reines Kotlin, direkt testbar; das Ende eines Imports ist im Composable-Lebenszyklus nicht zuverlässig erkennbar.
```kotlin
@ActivityRetainedScoped
class SharedEntryGate @Inject constructor() {
    val toStart: StateFlow<SharedEntry?>   // Eintrag, der jetzt starten soll
    fun share(entry: SharedEntry)          // frei → toStart; derselbe läuft → nichts; sonst waiting = entry
    fun started()                          // Starter hat toStart übernommen → toStart = null
    fun importBegan()                      // Import ohne Teilen (Datei-Wähler, Edit-Blatt): frei → beschäftigt
    fun importEnded()                      // waiting → toStart (wird der laufende), sonst frei
}
```

### 2. Wer meldet „Import abgeschlossen“?
Die ViewModels anhand ihres eigenen Zustands (nicht die Composables: Speichern endet asynchron, Composables werden bei Tab-Wechsel/Recreation verworfen; zu frühes Ende schließt sonst das neue Blatt). Jeder Weg muss enden:

| Ablauf | Ende durch |
|---|---|
| Link → Abbrechen | `SharedLinkImport.cancel` |
| Link → Fehler → Schließen | `dismissFailure` |
| Link → Fehler → Erneut versuchen | läuft im selben Import weiter |
| Übergabe → Blatt → Speichern/Verwerfen | Bibliotheks-ViewModel |
| → „Schon da“/Fehler → Snackbar zu | `clearError` |
| Speichern fehlgeschlagen → Snackbar zu | `clearError` |
| Edit-Blatt → Speichern/Schließen | Bibliotheks-ViewModel |

### 3. Übergabe an die Bibliothek im ViewModel statt in `remember`
Sonst kann Recreation den Eintrag verlieren und das Gate blockieren. Nebeneffekt: die bekannte shared-132-Einschränkung (nach Dunkelmodus-Wechsel auf dem Timer-Tab kein Wechsel in die Bibliothek) verschwindet.

### 4. Dateiformat beim Teilen prüfen; wartender Eintrag ist nur Adresse/Content-URI
Ein abgelöster wartender Eintrag hat nichts heruntergeladen → android-087 ohne Zusatzcode erfüllt.

### 5. `SharedLinkImportViewModel` → `SharedImportViewModel`
Übergibt jetzt auch Dateien.

## Refactorings

1. **`SharedLinkImport` verschlanken** (Risiko gering, gut getestet):
   - `SharedLinkImportTest.SameAddressTwice`: löschen, Regel wandert in `SharedEntryGateTest`/`SharedImportViewModelTest`.
   - `NewerAddressWhileLoading`: löschen; behalten/umformulieren: „nach Abbrechen startet ein neuer Link erst, wenn der abgebrochene Download beendet ist“, „nie zwei Downloads gleichzeitig“.
   - `DownloadsThatAreNotNeeded`: Ablöse-Variante löschen, Abbrechen-Variante bleibt.
   - `SingleShare.*` bleiben; ergänzen: `cancel`/`dismissFailure` rufen `onEnded`, `retry` nicht.
2. **`SharedLinkImportViewModelTest`**: Ablöse-Test löschen, Rest auf `handover`.
3. **`GuidedMeditationsListViewModelTest`**: Ablöse-Test mit dem Code löschen; „a newer share that fails keeps the open edit sheet …“ und „the same file handed over twice …“ prüfen und ggf. anpassen.
4. **`NavGraph`**: Effekte zusammenlegen, `pendingMeditationImportUri` entfällt (Risiko mittel, keine automatisierten Tests → manueller Test).

## Fachliche Szenarien

### AK-1: Link während Link
- 25401 lädt, 25402 geteilt → 25401 lädt weiter, Downloader nur einmal aufgerufen, danach Blatt 25401.
- Blatt 25401 offen, 25402 wartet, Speichern → erst danach lädt 25402, sein Blatt folgt; beide in der Bibliothek.
- Dasselbe mit Verwerfen → 25402 lädt; Download von 25401 weg.

### AK-2: Datei während Link
- Link lädt, MP3 geteilt/„Öffnen mit“ → Blatt des Links zuerst, kein Blatt ersetzt ein anderes; danach Blatt der MP3.
- Link lädt, nicht unterstützte Datei → sofort Snackbar, Link lädt weiter, wartender Eintrag bleibt.

### AK-3: Offenes Blatt mit Eingaben
- Import-Blatt offen mit Lehrer, 25402 geteilt → Blatt bleibt, 25402 lädt nicht; nach „Abbrechen“ (+ Verwerfen-Bestätigung) lädt 25402.
- Blatt über „+“ geöffnet, Link geteilt → wie oben.
- Edit-Blatt einer vorhandenen Meditation offen, Link geteilt → Blatt bleibt; nach Speichern/Schließen lädt der Link.
- Blatt offen, Datei geteilt, Speichern → Blatt der Datei erst nach abgeschlossenem Speichern (altes Speichern schließt das neue Blatt nicht).

### AK-4: „Schon da“ / Fehlermeldung
- 25401 schon in Bibliothek, wird geteilt und lädt, 25402 geteilt; „Schon da“ → 25402 startet erst nach Ende der Snackbar.
- Link lädt, Datei wartet, Link scheitert → Meldung bis Schließen, dann Blatt der Datei.
- Fehlermeldung, Eintrag wartet, „Erneut versuchen“ → Link lädt erneut, wartender wartet bis Abschluss.
- Fehlermeldung für A offen, A erneut geteilt → Meldung bleibt, nichts lädt.
- Podcast-Link ohne Folge, Datei wartet, Meldung geschlossen → Blatt der Datei.

### AK-5: Abbrechen
- 25401 lädt, 25402 wartet, „Abbrechen“ → keine Meldung, 25402 lädt, aber erst nach echtem Ende des abgebrochenen Downloads; endet 25401 trotzdem mit Datei, wird sie weggeräumt.
- 25401 lädt, nichts wartet, Abbrechen → still, nächstes Teilen startet sofort.

### AK-6: Mehrfach teilen
- 25401 lädt; 25402, dann MP3 → nach 25401 nur Blatt der MP3; 25402 nie geladen.
- 25401 lädt, 25402 wartet, 25401 erneut geteilt → 25402 wartet weiter.

### AK-7: Nie still verloren
- Wartender Eintrag startet nach jedem Ende-Weg (Tabelle Entscheidung 2).
- Abgelöster wartender Eintrag → Downloader nie aufgerufen (android-087).
- 25401 lädt, 25401 erneut geteilt → kein zweiter Download, nichts wartet, genau ein Blatt.
- 25401 gespeichert, **danach** erneut geteilt → „Schon da“ wie bisher.

### AK-8: Start ohne Neuöffnen
- Wartender Eintrag startet in derselben Sitzung; App wechselt in die Bibliothek und stoppt Wiedergabe erst jetzt.

### AK-9: Erhalt
- Einzelner Link, Podcast-Folge (mit Titel/Autor-Vorschlag), Datei: wie bisher inkl. „Schon da“, Fehlermeldungen, Retry, Abbrechen.
- „+“ ohne Teilen wie bisher; danach Gate frei.

### AK-10: Recreation (Dunkelmodus, Schriftgröße)
- 25401 lädt, 25402 wartet, Dunkelmodus wechselt → Ladefenster bleibt, Download läuft, dann Blatt 25401, dann 25402.
- Wechsel genau während der Übergabe an die Bibliothek → Blatt öffnet trotzdem (auch vom Timer-Tab), Gate hängt nicht.
- „Schon da“-Snackbar sichtbar, Eintrag wartet, Schriftgröße wechselt → Snackbar erneut, danach startet der wartende.
- Fehlerdialog offen, Eintrag wartet, Dunkelmodus → Dialog bleibt, nach Schließen startet der wartende.

## Reihenfolge (TDD)

1. `SharedEntryGateTest` + `SharedEntryGate`.
2. `SharedLinkImport` umbauen (`onEnded`, Ablösung raus), Tests löschen/umformulieren.
3. `SharedImportViewModel` (Umbenennung, Gate, `handover`).
4. `GuidedMeditationsListViewModel` (Beginn/Ende, Edit-Modus, Ablöse-Zweig raus).
5. `NavGraph`-Verdrahtung, Hilt prüfen; `make check`, `make test-unit-agent`.
6. Glossar, CHANGELOG.
7. Manueller Test am Emulator (Ticket-Schritte 1–9, AK-10, Zurück → erneut teilen startet sofort). Teilen ohne Browser: `adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "https://www.audiodharma.org/talks/25402/download" -n com.stillmoment.dev/com.stillmoment.MainActivity` (Package/Activity vorher verifizieren).

## Risiken

| Risiko | Mitigation |
|---|---|
| Ein Weg ohne `importEnded` blockiert jedes weitere Teilen. | Tabelle Entscheidung 2 als Checkliste, pro Weg ein Test; Übergabe im ViewModel; Gate-Logging. |
| Tab-Wechsel bei offenem Blatt/Snackbar, dann teilen: App auf Timer-Tab, sichtbar passiert nichts. | Kein Verlust, nur verzögert; ggf. Follow-up-Ticket. |
| `@ActivityRetainedScoped` neu im Projekt; verschiedene Instanzen → nie freigegeben. | Am Gerät per Log prüfen; manueller Test „Datei während Link“. |
| detekt `LongParameterList`. | `@Suppress` mit Begründung. |
