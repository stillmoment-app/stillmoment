# Implementierungsplan: shared-132 (iOS)

Ticket: shared-132
Erstellt: 2026-10-09

## Ursache

Die Share-Extension legt jeden geteilten Eintrag unter einem **festen Namen** in der Inbox
(`App Group/ShareInbox/`) ab und verschiebt ihn per `FileManager.moveItem(at:to:)` an diese Stelle.
`moveItem` wirft, wenn am Ziel schon eine Datei liegt. Die Extension wertet jeden Fehler als
`.unreadable` aus, und das erscheint als „Import fehlgeschlagen“.

- Link: Ziel ist `"\(url.lastPathComponent).json"`
  (`ios/StillMomentShareExtension/ShareViewController.swift:226-228`), Verschieben in Zeile 243.
  Ein Fehler führt zu `false` (Zeile 246) und damit zu `.unreadable` (Zeile 172).
  `…/talks/25401/download` und `…/talks/25402/download` landen beide auf `download.json`.
  Derselbe Link zweimal ergibt ebenfalls zweimal `download.json`.
- Audiodatei: Ziel ist `sourceURL.lastPathComponent` (Zeilen 198-199), Verschieben in Zeile 206.
  Ein Fehler führt zu `nil` und damit zu `.unreadable` (Zeile 145). Der Doc-Kommentar in Zeile 190
  verspricht ein „UUID prefix for uniqueness“, den der Code nicht umsetzt.
- `.unreadable` → `"share.error.title"` = „Import fehlgeschlagen“
  (`ShareConfirmationView.swift:146`, `de.lproj/Localizable.strings:22`).

Die App-Seite ist schon richtig: `InboxHandler.processInbox()`
(`ios/StillMoment/Application/InboxHandler.swift:106-127`) räumt veraltete Einträge (>24 h) weg,
nimmt den neuesten Eintrag nach Änderungsdatum, löscht die übrigen und verarbeitet genau einen.
Das passt bereits zur Regel „der zuletzt geteilte gewinnt“. Es fehlt nur, dass die Extension
gleichnamige Einträge ersetzt.

## Vergleich Android

Android hat keine Share-Extension und keine Inbox. `MainActivity.handleTextShareIntent`
(`android/.../MainActivity.kt:157-163`) schreibt die Adresse in einen einzelnen
`MutableStateFlow<String?>`. `DownloadUrlEffect` (`android/.../navigation/NavGraph.kt:711-716`)
startet über `LaunchedEffect(downloadUrl)`. Daraus folgt:
- Ein neuer Link ersetzt den Wert. Die laufende Effect-Coroutine wird abgebrochen, der neue Link gewinnt.
- Derselbe Link noch einmal geteilt: `StateFlow` sendet gleiche Werte nicht erneut, der Effekt startet
  nicht neu, es gibt genau einen Import.

Das ist dieselbe Regel, die iOS mit diesem Plan bekommt: ein Speicherplatz, der zuletzt geteilte
Eintrag überschreibt. Die Android-Prüfung ist nicht Teil dieses Plans.

## Annahmen

- **„Bevor die App übernommen hat“ heißt auf iOS: Der Eintrag liegt noch in der Inbox.** Läuft der
  Download in der App schon (`isProcessing`), wird ein weiterer Share erst beim nächsten Aktiv-Werden
  verarbeitet. Das bleibt wie bisher. Das Ticket verlangt nur, dass beim Ablegen kein Fehler entsteht.
- **Gleichnamige Einträge zu ersetzen ist korrekt.** Bei derselben Adresse oder derselben Datei
  ist der Inhalt identisch. Bei verschiedenen Adressen mit gleichem Ende (25401/25402) gewinnt laut
  Ticket ohnehin der zuletzt geteilte, und der frühere entfällt.
- **Verschieden benannte Einträge** (z. B. erst `a.mp3`, dann ein Link) bleiben beide liegen. Die
  App nimmt den neuesten und löscht den Rest. Das ist schon so implementiert und getestet
  (`testOnlyNewestEntryIsProcessed`, `testOlderEntriesDeletedAndNewestAudioFileImported`).
- **„Schon da“ bleibt** unverändert: Die Duplikaterkennung in `FileOpenHandler` (Dateiname + Größe)
  ist davon nicht berührt. Ein ersetzter Inbox-Eintrag behält Namen und Inhalt.
- Das Ändern des Änderungsdatums auf „jetzt“ beim Audio-Ablegen (Zeilen 207-211) bleibt erhalten.
  Davon hängen „neuester gewinnt“ und das 24-h-Aufräumen ab.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMoment/Infrastructure/Services/ShareInbox.swift` (neu) | Infrastructure | Neu | `enum ShareInbox` mit `static func storeAudioFile(from:in:fileManager:) throws -> URL` und `static func storeLink(_:in:fileManager:date:) throws -> URL`. Enthält die bisherige Ablage-Logik (temp → move, Änderungsdatum) und ersetzt einen gleichnamigen Eintrag. Kein `Logger` (in der Extension nicht vorhanden). Der Name endet auf keinen Suffix der Lint-Regel `service_created_outside_composition_root`. Es ist ein zustandsloser Helfer, kein Dienst in `AppDependencies`. |
| `ios/StillMoment.xcodeproj/project.pbxproj` | Build | Ergänzen | Die neue Datei in `membershipExceptions` von „Exceptions for "StillMoment" folder in "StillMomentShareExtension" target“ eintragen, wie bei `Domain/Models/ShareOutcome.swift`. Eine Zeile. |
| `ios/StillMomentShareExtension/ShareViewController.swift` | Extension | Vereinfachen | `copyFileToInbox` und `writeURLReferenceToInbox` rufen `ShareInbox` auf (`try?` → `.unreadable` nur bei echtem Fehler). Die Erzeugung des Inbox-Ordners bleibt in der Extension. Falschen Doc-Kommentar „UUID prefix“ (Zeile 190) entfernen. |
| `ios/StillMoment/Application/InboxHandler.swift` | Application | Optional | `URLReference` bleibt das gemeinsame JSON-Schema. `ShareInbox.storeLink` sollte dasselbe `Codable` nutzen statt `JSONSerialization`-Dictionary, dann muss `URLReference` mit in die neue Datei (oder ebenfalls in die Extension). Siehe Design-Entscheidung 2. |
| `ios/StillMomentTests/Infrastructure/ShareInboxTests.swift` (neu) | Tests | Neu | Fachliche Tests zum Ablegen |
| `ios/StillMomentTests/Application/InboxHandlerTests+RepeatedShare.swift` (neu) | Tests | Neu | Ende-zu-Ende: zweimal über `ShareInbox` ablegen, dann `processInbox()` |
| `dev-docs/reference/glossary.md` | Docs | Ergänzen | Im ShareOutcome- oder Link-Import-Abschnitt einen Satz zu „zuletzt geteilter Eintrag gewinnt“ mit Verweis auf `ShareInbox.swift` |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `FileManager.moveItem(at:to:)` | iOS 2+ | Apple Docs | Wirft, wenn `dstURL` existiert. Das ist die Ursache. |
| `FileManager.removeItem(at:)` | iOS 2+ | Apple Docs | Vor dem Verschieben auf das Ziel. „Datei existiert nicht“ wird bewusst ignoriert (`try?`). |
| `FileManager.replaceItemAt(_:withItemAt:)` | iOS 4+ | Apple Docs | Alternative, siehe Entscheidung 1. |

Keine neuen Frameworks. Das Deployment-Target ist nicht berührt.

## Design-Entscheidungen

### 1. Wie wird ersetzt: entfernen, dann verschieben, oder `replaceItemAt`?

**Trade-off:** `replaceItemAt` ist atomar, verhält sich aber unterschiedlich, je nachdem ob das
Ziel existiert (bei fehlendem Original sind die Docs nicht eindeutig), und kann ein Backup-Verzeichnis
anlegen. Entfernen und dann Verschieben ist zwei Schritte, aber leicht zu durchschauen. Das kurze
Fenster ohne Eintrag ist harmlos: Die App liest nur beim Aktiv-Werden, und der Eintrag erscheint
Millisekunden später wieder.
**Entscheidung:** `try? removeItem(at: destination)` direkt vor `moveItem`. Einfachste korrekte Lösung.

### 2. Ablage-Logik in die App verschieben (testbar) oder in der Extension lassen?

**Trade-off:** `StillMomentTests` hat keinen Zugriff auf den Extension-Target. Ohne Auslagerung
ließe sich der Fehler nicht per Test belegen (TDD-Pflicht). Das Muster gibt es schon:
`ShareOutcome.swift` liegt im App-Target und ist zusätzlich Mitglied der Extension.
**Entscheidung:** Auslagern in `ShareInbox.swift` (App-Target + Extension-Mitgliedschaft).
`storeLink` kodiert `URLReference` per `JSONEncoder` statt `JSONSerialization`. Dann gilt ein
Schema für Schreiber und Leser. Dafür zieht `URLReference` in `ShareInbox.swift` um, denn
`InboxHandler.swift` ist nicht Mitglied der Extension. Das ist die einzige Verschiebung außerhalb
der Extension.

### 3. Alternative verworfen: eindeutige Dateinamen (UUID)

Mit einem UUID-Präfix gäbe es nie eine Kollision. Dann lägen aber bei „derselbe Link zweimal“ zwei
Einträge in der Inbox. Die App würde trotzdem nur den neuesten importieren, aber der Audio-Dateiname
würde sich ändern. `FileOpenHandler` erkennt Duplikate über Dateiname + Größe, sodass „Schon da“
brechen könnte. Ersetzen ist einfacher und hält die Namen stabil.

### 4. Alternative verworfen: Extension leert vor dem Ablegen die ganze Inbox

Damit wäre „der zuletzt geteilte gewinnt“ auch für verschieden benannte Einträge schon in der
Extension sichergestellt. Die App macht das aber bereits (neuester gewinnt, Rest wird gelöscht).
Zusätzliches Leeren in der Extension würde in seltenen Fällen eine Datei löschen, die die App gerade
liest. Das bringt keinen Mehrwert.

## Refactorings

1. **Ablage-Logik aus `ShareViewController` nach `ShareInbox` auslagern.** Das ist nötig, weil das
   Akzeptanzkriterium sonst nicht testbar ist (siehe Entscheidung 2). Das Verhalten bleibt bis auf
   das Ersetzen gleich.
   - Risiko: Niedrig. Die Extension hat keine Unit-Tests, und die Logik umfasst etwa 50 Zeilen.
     Abgesichert durch die neuen `ShareInboxTests` und die bestehenden 24-h-/Neuester-Tests in
     `InboxHandlerTests`. Manueller Test auf dem Gerät oder im Simulator ist nötig, denn die
     Extension-Mitgliedschaft prüft nur der Build (`make check` / Build des Extension-Targets).

## Fachliche Szenarien

### AK-1: Dieselbe Adresse zweimal geteilt

- Gegeben: leere Inbox
  Wenn: `https://www.audiodharma.org/talks/25401/download` wird zweimal abgelegt
  Dann: Beide Ablagen gelingen (kein Fehler, also „In Still Moment gespeichert“), in der Inbox liegt genau ein Eintrag
- Gegeben: dieselbe Adresse zweimal abgelegt
  Wenn: die App die Inbox übernimmt
  Dann: genau ein Download von 25401, Ergebnis `.downloadCompleted`, eine neue Meditation, kein `downloadError`

### AK-2: Dieselbe Audiodatei zweimal geteilt

- Gegeben: leere Inbox
  Wenn: `Vortrag.mp3` wird zweimal abgelegt
  Dann: Beide Ablagen gelingen, in der Inbox liegt genau ein `Vortrag.mp3`
- Gegeben: `Vortrag.mp3` zweimal abgelegt
  Wenn: die App die Inbox übernimmt
  Dann: genau ein Import (`.audioFile`), eine Meditation in der Bibliothek

### AK-3: Verschiedene Adressen mit gleichem Ende

- Gegeben: `…/talks/25401/download` abgelegt
  Wenn: `…/talks/25402/download` abgelegt wird
  Dann: kein Fehler, in der Inbox liegt ein Eintrag, und er verweist auf 25402
- Gegeben: beide nacheinander abgelegt
  Wenn: die App übernimmt
  Dann: Download nur von 25402

### AK-4: iOS und Android gleich

- Durch die oben beschriebene gemeinsame Regel abgedeckt. Kein eigener iOS-Test, Abgleich im manuellen Test.

### AK-5: „Schon da“ bleibt

- Gegeben: `Vortrag.mp3` steht schon in der Bibliothek
  Wenn: `Vortrag.mp3` (zweimal) geteilt wird und die App übernimmt
  Dann: `.audioImportFailed(.alreadyImported)`, also der Hinweis „Schon da“, keine zweite Meditation

### AK-6: Einzelnes Teilen wie bisher

- Bestehende `InboxHandlerTests*` (Link, Podcast, Fehler, Erneut versuchen) bleiben grün, ohne Änderung.
- Gegeben: leere Inbox
  Wenn: ein Link einmal abgelegt wird
  Dann: Der Eintrag enthält Adresse und Dateinamen so, wie `InboxHandler` sie liest (Rundweg Schreiber → Leser)

### AK-7: 24-h-Aufräumen bleibt

- Bestehende Tests `testEntriesOlderThan24HoursAreCleanedUp` / `testStaleEntriesCleanedUpWhileNewestIsProcessed` bleiben grün.
- Gegeben: ein gleichnamiger Eintrag liegt seit 25 h in der Inbox (Änderungsdatum in der Vergangenheit)
  Wenn: dieselbe Datei erneut abgelegt wird
  Dann: Der Eintrag gilt als frisch (Änderungsdatum ≈ jetzt) und wird von der App importiert, nicht weggeräumt

## Reihenfolge der Akzeptanzkriterien

1. **Auslagern (Refactoring) mit Charakterisierungstest AK-6 (Rundweg)**: `ShareInbox` anlegen, Extension umstellen, Build beider Targets
2. **AK-1 / AK-3** (RED: zweites `storeLink` wirft; GREEN: Ziel vorher entfernen)
3. **AK-2** (gleiches Muster für `storeAudioFile`)
4. **AK-7** (Änderungsdatum beim Ersetzen)
5. **Ende-zu-Ende** in `InboxHandlerTests+RepeatedShare.swift` (AK-1, AK-2, AK-3, AK-5)
6. Glossar-Satz, CHANGELOG (über `/implement-ticket`), manueller Test laut Ticket

## Offene Fragen

- [ ] **`URLReference` umziehen (Entscheidung 2)?** Empfehlung: ja, ein Schema für Schreiber und
  Leser. Wenn das zu viel Bewegung ist: `storeLink` behält das `JSONSerialization`-Dictionary, und
  der Rundweg-Test sichert die Übereinstimmung ab.
- [ ] **Ablageort `Infrastructure/Services/` für einen zustandslosen `enum`?** Empfehlung: ja, dort
  liegen die anderen Dateisystem-Helfer. Ein eigener Ordner lohnt für eine Datei nicht.
- [ ] Plan-Verweis im Ticket (Skill-Schritt 7) wurde auf Anweisung bewusst nicht gesetzt. Nur diese
  Plan-Datei ist committet.
