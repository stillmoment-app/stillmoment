# Implementierungsplan: shared-138 (iOS)

Ticket: shared-138

## Entscheidungen (verbindlich, mit dem User geklärt)

- **Regel:** Was die App begonnen hat (Laden, Bearbeiten-Blatt, Meldung), führt sie zu Ende. Ein währenddessen geteilter Eintrag wartet und startet danach von selbst. Höchstens ein wartender Eintrag, der zuletzt geteilte gewinnt. Nach „Abbrechen“ im Ladefenster startet der wartende.
- **Jedes Bearbeiten-Blatt zählt**, auch das Blatt einer vorhandenen Meditation (Edit-Modus) und ein Import über die Dateiauswahl.
- **Derselbe Eintrag erneut geteilt, solange er läuft (Laden, Blatt oder Meldung): ignorieren.** Kein zweiter Import, kein nachgeschobenes „Schon da“, kein zweites Blatt. „Derselbe“: Link mit gleicher Adresse, Audiodatei mit gleichem Namen und gleicher Größe (wie die „Schon da“-Erkennung). Ein *anderer* bereits wartender Eintrag bleibt davon unberührt. **Falle:** Ein Vergleich gegen „den zuletzt beendeten Eintrag“ darf nicht über das Ende hinaus gelten — wer 25401 nach dem Speichern bewusst erneut teilt, bekommt wie bisher „Schon da“. Die Regel gilt nur für Einträge, die geteilt wurden, *während* der gleiche lief.
- **„Öffnen in“ zählt wie Teilen** (Weg über die Inbox, siehe Entscheidung 3).
- **„Erneut versuchen“ setzt den begonnenen Import fort**; der wartende Eintrag wartet weiter.
- **Nicht unterstütztes Format** wird sofort gemeldet und wird nie zum wartenden Eintrag.
- **Befund 5 (geteilte Audiodatei scheitert beim Speichern) wird in diesem Ticket behoben**, als eigener `fix(ios)`-Commit vor dem Feature, im CHANGELOG eigens genannt. Vorher im Simulator bestätigen.
- `InboxHandler` darf `ShareInbox.storeAudioFile` direkt aufrufen.
- Kein ausdrückliches Aufräumen übernommener Kopien in `tmp` (System räumt auf).
- Begriff plattformübergreifend: **„wartender Eintrag“** (EN *waiting share*). Ereignisnamen nach Möglichkeit wie Android: „Meldung geschlossen“, „Blatt geschlossen“, „Erneut versuchen“, „Abbrechen“.

## Ist-Zustand (Code-Analyse)

1. **Teilen während ein Link lädt.** `InboxHandler.processInbox()` gibt bei `isProcessing` `.empty` zurück; der neue Eintrag bleibt in der Inbox und wird erst bei `scenePhase == .active` / `didBecomeActive` / `stillmoment://import` geholt (`StillMomentApp.checkInbox()`). Am Ende löscht `deleteFiles([newestFile])` per Pfad — ein inzwischen gleichnamig abgelegter neuer Eintrag (`download.json`) wird still mitgelöscht (25401/25402).
2. **Teilen bei offenem Bearbeiten-Blatt** (im Simulator bestätigen). `isProcessing` ist dann `false`, der neue Eintrag wird sofort verarbeitet; `FileOpenHandler.importFile` setzt `pendingImportSignal`, `GuidedMeditationsListView.takeOverPendingImport` → `viewModel.beginImport` überschreibt `pendingImport`/`meditationToEdit`, während `showingEditSheet` schon `true` ist. Das Blatt zeigt (wegen `@State(initialValue:)`) weiter A, intern gilt B: Speichern → `updateMeditation(A)` scheitert mit `meditationNotFound`, weder A noch B wird importiert. Bei Edit-Modus wird B nach dem Speichern still verworfen.
3. **Teilen während einer Meldung.** Wird sofort verarbeitet; neue Ergebnisse überschreiben `fileOpenError` bzw. `downloadError`/`retryableSharedLink`. Schließen der Meldung ist nur an den Alert-Buttons in `StillMomentApp` erkennbar (Binding-Setter läuft auch bei „Erneut versuchen“).
4. **„Öffnen in“** (`handleFileOpen`) importiert sofort, unabhängig von allem; security-scoped URL (`LSSupportsOpeningDocumentsInPlace`).
5. **Versteckter Bug:** Eine über die Extension geteilte Audiodatei wird nach Veröffentlichen des Signals sofort aus der Inbox gelöscht (`InboxHandler` „imported synchronously … copy lives in the library“ — seit ios-043 falsch, Persistenz erst bei „Speichern“). `GuidedMeditationService.addMeditation` → `copyFileToMeditationsDirectory` kopiert dann aus einer gelöschten Datei → „Import fehlgeschlagen“. War mit shared-046 (`365191df`) schon einmal behoben. `testAudioFileIsCleanedUpFromInboxAfterImport` schreibt das Löschen fest; Mocks kopieren nicht.

**Wo ein Import endet:**
- Blatt gespeichert/verworfen: `GuidedMeditationsListViewModel.showingEditSheet` → `false` (per `onChange` in der App beobachtbar).
- Meldung geschlossen: nur Button-Actions der Alerts in `StillMomentApp`.
- „Abbrechen“ im Ladefenster: `processInbox()`/`retry()` liefern `.empty` bei `cancelRequested`.

## Annahmen

- Der wartende Eintrag ist auf iOS der Inhalt der Inbox; „neuester gewinnt“ besteht schon (`processInbox` nimmt den neuesten, löscht den Rest). Neu: Inbox nicht anfassen, solange ein Import offen ist, und danach selbst nachsehen.
- Wechselt man mit offenem Blatt den Tab, wartet der Eintrag, bis das Blatt abgeschlossen ist.
- Scheitert das Speichern im Blatt, startet der wartende Eintrag trotzdem nach dem Schließen des Blatts.
- Wartende Einträge > 24 h werden wie bisher weggeräumt.
- „Schon da“ nach „Öffnen in“ wechselt jetzt wie beim Teilen in die Bibliothek (gewollte Angleichung).
- Share Extension, `ShareOutcome`, `ShareInbox` bleiben unverändert.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMoment/Application/InboxHandler.swift` | Application | Erweitern | (a) **Eintrag beim Start übernehmen statt am Ende löschen:** neuesten Eintrag vor der Verarbeitung atomar nach `tmp/share_<UUID>/<Name>` verschieben (`moveItem`). Link-Eintrag lesen und entfernen; Audiodatei bleibt bis „Speichern“, bei „Schon da“/Fehler verwerfen (`discardDownload` auch für Präfix `share_`). `deleteFiles([newestFile])` entfällt. (b) **„Begonnener Import offen“:** `isProcessing` ODER Meldung offen ODER `fileOpenHandler.pendingImportSignal != nil` ODER Bearbeiten-Blatt offen. Solange das gilt: `processInbox()` → `.empty`, Eintrag wartet (Duplikate des laufenden Eintrags verwerfen, siehe Entscheidungen). Möglichst aus echtem Zustand ableiten; explizite Merker nur für „Meldung offen“ und „Blatt offen“. (c) **Stilles Ende (Abbrechen):** im selben Durchlauf den nächsten wartenden Eintrag verarbeiten (Schleife, endet bei leerer Inbox; `cancelRequested` pro Eintrag zurücksetzen). (d) Neu: Meldung geschlossen (ohne Retry) → Fehler zurücksetzen, dann `processInbox()`; Blatt geschlossen → dann `processInbox()`; „Öffnen in“ annehmen (Format prüfen, Security-Scope kurz öffnen, `ShareInbox.storeAudioFile`). Doc-/Flow-Kommentare korrigieren. Datei bei Bedarf in `InboxHandler+…`-Extensions aufteilen (`file_length`). |
| `ios/StillMoment/StillMomentApp.swift` | Composition Root | Erweitern | Nur Verdrahtung, je Ereignis ein Aufruf: `onChange(of: guidedListViewModel.showingEditSheet)`; Close/OK in Download-Alert und `fileOpenError`-Alert → „Meldung geschlossen“; „Erneut versuchen“ bleibt `retryShare()`; `handleFileOpen` → Inbox + `checkInbox()`. |
| `ios/StillMomentTests/Application/InboxHandlerTests+WaitingShare.swift` | Tests | Neu | Fachliche Szenarien unten, Ablage über `ShareInbox` wie `+RepeatedShare`. |
| `ios/StillMomentTests/Mocks/MockAudioDownloadService.swift` | Tests | Erweitern | Datei pro angefragter Adresse; „Abbrechen“ nur für den laufenden Download (heute hängt `downloadCancelCalled` für alle folgenden); `whileDownloading` steuerbar pro Adresse. |
| `InboxHandlerTests*.swift`, `InboxHandlerImportFailureTests.swift` | Tests | Anpassen | `.audioFile(url)` zeigt auf die übernommene Kopie, nicht in die Inbox. `testAudioFileIsCleanedUpFromInboxAfterImport`: Inbox leer UND Datei für das Blatt existiert weiter. |
| `dev-docs/reference/glossary.md` | Docs | Ergänzen | Begriff „wartender Eintrag“ + Regel; Absatz zu shared-132 (Android löst ab) korrigieren. **Abstimmen mit Android-Branch** (beide ändern dieselbe Stelle — Formulierung plattformneutral halten). |

Unverändert: `FileOpenHandler`, `GuidedMeditationsListViewModel`, `GuidedMeditationsListView`, `ShareInbox`, `ShareViewController`.

Vorhandene Mocks/Helfer: `MockAudioDownloadService`, `MockPodcastEpisodeResolver`, `MockGuidedMeditationService`, `MockAudioMetadataService`, `makeDownloadedFile(named:)`, `makeSharedAudioFile(named:)`, `share(_:)`, `ShareInboxTests.talk25401`/`talk25402`.

## API-Recherche

| API | Min. Version | Hinweis |
|-----|--------------|---------|
| `FileManager.moveItem(at:to:)` | iOS 2+ | Auf demselben Volume ein `rename`, atomar. App-Group-Inbox und App-`tmp` liegen auf dem Daten-Volume — **verifizieren**; falls `moveItem` volumenübergreifend kopiert, ist es nicht atomar (dann Ziel innerhalb des App-Group-Containers wählen). |
| `URL.startAccessingSecurityScopedResource()` | iOS 8+ | Nur für die Dauer des Kopierens bei „Öffnen in“. |
| `View.onChange(of:perform:)` | iOS 14+ | Ein-Parameter-Form wie im übrigen Code (Target iOS 16). |
| `navigationDestination(isPresented:)` | iOS 16+ | Ein neues Blatt während der Pop-Animation des alten kann verschluckt werden (Risiken). |

## Design-Entscheidungen

1. **Regel lebt im `InboxHandler`**, seine Sperre `isProcessing` wird zu „begonnener Import offen“ erweitert, so weit wie möglich aus echtem Zustand abgeleitet (kein hängender Merker). App ruft je Ereignis genau eine Methode auf; alles Fachliche ist in `InboxHandlerTests` prüfbar.
2. **Übernehmen beim Start statt Löschen am Ende** (atomar verschieben). In der Inbox liegen nur noch wartende Einträge; ein gleichnamiger neuer kann den laufenden nicht treffen (AK-7); die Audiodatei bleibt bis „Speichern“ (Befund 5).
3. **„Öffnen in“ immer über die Inbox** (`ShareInbox.storeAudioFile` + `checkInbox()`): ein Weg, eine Regel, Security-Scope nur kurz offen.
4. **Nach „Abbrechen“ startet der wartende Eintrag im `InboxHandler`** (Schleife), weil die App ein abgebrochenes `.empty` nicht von „Inbox leer“ unterscheiden kann. `InboxResult` bleibt unverändert.

## Fachliche Szenarien

### AK-1: 25401 lädt, 25402 wird geteilt
- Gegeben 25401 lädt. Wenn 25402 geteilt wird (`download.json` ersetzt) und die App aktiv wird. Dann lädt 25401 weiter, zweites `processInbox()` → `.empty`, Inbox enthält genau 25402.
- Gegeben Blatt 25401 offen, 25402 wartet. Wenn gespeichert. Dann wird 25402 geladen, `requestedURLs` = [25401, 25402], Signal für 25402.
- Dasselbe mit Verwerfen.

### AK-2: Audiodatei während Link (auch „Öffnen in“)
- Link lädt, `Vortrag.mp3` wird geteilt → erst Ergebnis des Links; `Vortrag.mp3` bleibt in der Inbox.
- Blatt des Links verworfen → Signal für `Vortrag.mp3`, Datei existiert außerhalb der Inbox.
- Link lädt, `Vortrag.mp3` über „Öffnen in“ → wartet, nach Schließen des Blatts übernommen.
- Blatt einer geteilten Audiodatei gespeichert → Meditation in der Bibliothek, kein „Import fehlgeschlagen“ (Befund 5).

### AK-3: Offenes Blatt mit Eingaben
- Blatt offen (Import- oder Edit-Modus), 25402 geteilt → `.empty`, nichts geladen, kein neues Signal.
- Signal veröffentlicht, Blatt noch nicht übernommen, neuer Eintrag → wartet.
- Blatt offen, 25402 wartet, „Abbrechen“ im Blatt → 25402 wird geladen, sein Blatt folgt.

### AK-4: „Schon da“ oder Fehlermeldung
- Laufender Import endet mit „Schon da“, 25402 geteilt; App aktiv solange Meldung steht → `.empty`; Meldung geschlossen → 25402 lädt.
- Link scheitert („nicht erreichbar“), 25402 wartet; Schließen → 25402 lädt.
- Dieselbe Lage, „Erneut versuchen“ → derselbe Link lädt erneut, 25402 wartet bis zum Abschluss des zweiten Versuchs.
- Podcast-Link ohne Folge (Meldung ohne Ladefenster), danach Datei geteilt; Meldung geschlossen → Blatt der Datei.
- Audiodatei „Schon da“ → übernommene Kopie entfernt, Inbox leer.

### AK-5: Abbrechen
- 25401 lädt, 25402 wartet, „Abbrechen“ → keine Meldung für 25401, 25402 wird geladen (nicht als abgebrochen).
- 25401 lädt, nichts wartet, „Abbrechen“ → `.empty`, keine Meldung.
- Retry lädt, 25402 wartet, „Abbrechen“ → 25402 wird geladen.

### AK-6: Mehrfach geteilt
- 25401 lädt; erst 25402, dann `Vortrag.mp3`; Blatt 25401 geschlossen → nur `Vortrag.mp3`, 25402 nie angefragt, Inbox danach leer.
- 25401 lädt; 25402 zweimal geteilt → danach genau einmal geladen.

### AK-7: Kein stiller Verlust / gleicher Eintrag
- 25401 (`download.json`) übernommen, 25402 als `download.json` abgelegt, 25401 endet → 25402 liegt weiter in der Inbox.
- 25401 lädt, 25401 erneut geteilt → kein zweiter Download, nach dem Blatt kein „Schon da“, nichts wartet.
- 25401 lädt, 25402 wartet, 25401 erneut geteilt → 25402 wartet weiter (neuester *anderer* bleibt).
- `Vortrag.mp3` Blatt offen, `Vortrag.mp3` erneut geteilt → ignoriert.
- 25401 gespeichert, **danach** 25401 erneut geteilt → „Schon da“ wie bisher.

### AK-8: Start ohne erneutes Öffnen
- Anstoß aus „Blatt geschlossen“ / „Meldung geschlossen“ / „Abbrechen“, ohne `didBecomeActive`. Verdrahtung in `StillMomentApp` manuell prüfen.

### AK-9: Erhalt
- Alle bestehenden `InboxHandlerTests*`, `InboxHandlerImportFailureTests`, `FileOpenHandler*Tests`, `GuidedMeditationsListViewModelTests+ImportFlow`, `ShareInboxTests` grün (mit Pfad-Anpassungen).
- Einzelner Link/Podcast-Folge/Audiodatei wie bisher inkl. Retry. „Öffnen in“ ohne laufenden Import: Blatt sofort; schon vorhanden → „Schon da“.

## Reihenfolge

1. Befund 5 im Simulator bestätigen; Charakterisierungs-Test (Datei des Signals existiert nach `processInbox()`), rot.
2. Übernehmen statt Löschen (AK-7 Teil 1, behebt Befund 5) → eigener `fix(ios)`-Commit.
3. Mock erweitern; AK-5/AK-6 (Schleife nach stillem Ende).
4. AK-4 (Meldung offen/geschlossen, Retry).
5. AK-1/AK-3 (Blatt offen, `pendingImportSignal`, Blatt geschlossen).
6. AK-7 gleiche Einträge ignorieren.
7. AK-2 inkl. „Öffnen in“.
8. Verdrahtung `StillMomentApp`; `make check`, `make test-unit-agent`.
9. Glossar, CHANGELOG, manueller Test im Simulator (Ticket-Schritte, Befund 5, „Öffnen in“ während Laden).

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Nächstes Blatt öffnet während der Pop-Animation des alten und wird verschluckt (`showingEditSheet == true`, kein Blatt). Vor allem bei wartender Audiodatei. | Ohne Verzögerung bauen, manuell prüfen. Tritt es auf: an genau einer Stelle (Fortsetzung nach „Blatt geschlossen“) auf das Ende der Pop-Animation warten. |
| Hängender Merker blockiert alle späteren Teilungen. | Sperre überwiegend aus echtem Zustand; Merker nur von Buttons/`onChange` gelöst, die immer feuern; nur im Speicher. |
| Doppelte Anstöße (`scenePhase` + `didBecomeActive`). | Sperre greift weiterhin. |
| Kopie bei „Öffnen in“ scheitert (iCloud-Datei nicht geladen). | `.importFailed`-Meldung wie bisher. |
