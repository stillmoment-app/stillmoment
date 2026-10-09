# Domain Glossar

<!--
CLAUDE-OPTIMIZED: Strukturiert für schnelles AI-Nachschlagen
- Quick Reference für Übersicht
- Detailsektionen nach Domäne gruppiert (aus User-Perspektive)
- Jeder Eintrag mit Cross-Platform Dateireferenzen

Last Updated: 2026-10-09
-->

## Quick Reference

| Begriff | Typ | Domäne | Beschreibung |
|---------|-----|--------|--------------|
| `AppearanceMode` | Enum | App-weit | Darstellungsmodus (System, Hell, Dunkel) |
| `AppTab` | Enum | App-weit | Die drei Tabs und ihre Reihenfolge |
| `AudioMetadata` | Value Object | Bibliothek | Metadaten aus den ID3-Tags einer Audiodatei |
| `BackgroundSound` | Value Object | Timer | Eingebauter Soundscape aus dem Katalog |
| `ColorTheme` | Enum | App-weit | Farbthema (Kerzenschein, Wald, Mond) |
| `CustomAudioFile` | Value Object | Timer | Selbst importierter Soundscape |
| `CustomAudioType` | Enum | Timer | Art einer importierten Audiodatei (aktuell nur Soundscape) |
| `DurationFilter` | Enum | Bibliothek | Die fünf Dauer-Stufen des Bibliotheksfilters |
| `EditSheetState` | Value Object | Bibliothek | Zustand und Validierung beim Bearbeiten |
| `GongSound` | Value Object | Timer | Wählbarer Gong-Klang |
| `GuidedMeditation` | Entity | Bibliothek | Eine Meditation in der Bibliothek |
| `GuidedMeditationGroup` | Value Object | Bibliothek | Die Meditationen eines Lehrers als Gruppe |
| `GuidedMeditationSettings` | Value Object | Bibliothek | Einstellungen der Wiedergabe |
| `ImportPrefill` | Value Object | Bibliothek | Vorschlagswerte für Lehrer und Titel beim Import |
| `IntervalMode` | Enum | Timer | Wie Intervallklänge ausgelöst werden |
| `IntervalSettings` | Value Object | Timer | Intervall-Konfiguration für `tick()` |
| `LibrarySearchEngine` | Domain Service | Bibliothek | Die Regeln der Volltextsuche und ihrer Rangfolge |
| `LibrarySearchState` | Enum | Bibliothek | Welche Ansicht die Bibliothek gerade zeigt |
| Link-Import (`AudioDownloadService`) | Protokoll | Bibliothek | Meditation aus einer geteilten Adresse holen |
| `LocalizedString` | Value Object | Timer | Deutscher und englischer Text eines Soundscapes |
| `MeditationPhase` | Enum | App-weit | Visuelle Phase: Vorbereitung oder laufende Meditation |
| `MeditationSettings` | Value Object | Timer | Abgeleitete Sicht auf die Praxis für Reducer und Timer |
| `MeditationTimer` | Value Object | Timer | Das zentrale Timer-Modell |
| Podcast-Import (`PodcastEpisodeResolver`) | Protokoll | Bibliothek | Eine geteilte Apple-Podcasts-Folge zur Audiodatei auflösen |
| `PendingImport` | Value Object | Bibliothek | Import zwischen Dateiwahl und Speichern |
| Rückmeldung (`FeedbackLinks`) | Konzept | App-weit | „App bewerten" und „Schreib uns" in den Einstellungen |
| `Praxis` | Value Object | Timer | Die eine gespeicherte Timer-Konfiguration |
| `PraxisRepository` | Protokoll | Timer | Laden und Speichern der Praxis |
| `PreparationCountdown` | Value Object | Bibliothek | Vorbereitungszeit vor dem Start der Wiedergabe |
| `ResolvedSoundscape` | Value Object | Timer | Aufgelöster Soundscape, Herkunft egal |
| `SearchHistory` | Domain Service | Bibliothek | Die Regeln des Suchverlaufs („Zuletzt gesucht") |
| `ShareOutcome` | Enum | Bibliothek | Was nach dem Teilen an Still Moment erscheint (nur iOS) |
| `Soundscape` | Konzept | Timer | Hintergrundklang während der stillen Meditation |
| `SoundscapeResolver` | Protokoll | Timer | Löst Soundscape-Kennungen auf (eingebaut oder eigen) |
| Start-/End-Gong | Konzept | Bibliothek | Ein Gong rahmt die Wiedergabe einer Meditation |
| `TimerAction` | Enum | Timer | Benutzeraktionen und Systemereignisse |
| `TimerEffect` | Enum | Timer | Seiteneffekte des Reducers |
| `TimerEvent` | Enum | Timer | Domänenereignisse aus `tick()` |
| `TimerState` | Enum | Timer | Der Zustandsautomat des Timers |
| `TrimEditorState` | Value Object | Bibliothek | Zustand des Zuschnitt-Editors |
| Vibration statt Gong | Konzept | Timer | Spürbares Signal anstelle eines hörbaren |
| Wellenform (`MeditationWaveform`) | Value Object | Bibliothek | Vorberechnete Amplituden für den Zuschnitt-Editor |
| Wiedergabe-Bereich | Konzept | Bibliothek | Die Trim-Punkte als nicht-destruktiver Bereich |
| Zoom im Zuschnitt-Editor | Konzept | Bibliothek | Ausschnittsvergrößerung beim Setzen der Marken |

---

## Bibliothek

Das Kernfeature: aus eigenen MP3s eine persönliche Sammlung aufbauen. Der stille Timer ist
die Ergänzung — siehe „Feature priority" in `CLAUDE.md`. Das prägt Tab-Reihenfolge,
Default-Tab und die Priorisierung im Konfliktfall.

**Drei Begriffe für dieselbe Sache — so heißen sie richtig:**

| Begriff | Gilt für |
|---------|----------|
| **Bibliothek** | Der kanonische Name der Domäne: die persönliche Sammlung als Ganzes. So heißt sie in `CLAUDE.md`, in den Texten der App („deine persönliche Bibliothek") und in den Schlüsseln `library.*`. |
| **Meditationen** | Nur das Tab-Label in der Oberfläche (`tab.library`). Kürzer, weil im Tab kein Platz ist. Kein Domänenbegriff. |
| **Guided Meditation** | Der einzelne Eintrag in der Bibliothek, nicht die Sammlung. Trägt der Code-Typ `GuidedMeditation` und die Schlüssel `guided_meditations.*`. |

---

### Sammlung

#### GuidedMeditation

**Typ:** Entity (hat ID)
**Muster:** Rich Domain Model

**Beschreibung:**
Eine vom User importierte geführte Meditation — der einzelne Eintrag in der Bibliothek.
Das Abspielen der Audiodatei ist das Hauptfeature. Ob die Datei selbst importiert oder aus
einer kuratierten Quelle geholt wurde, macht danach keinen Unterschied mehr.

**Fachlich Erklärungsbedürftiges:**

| Eigenschaft | Bedeutung |
|-------------|-----------|
| `teacher` / `name` | Aus den ID3-Tags oder vom User bearbeitet. Seit shared-103 ist der gespeicherte Wert die einzige Wahrheit — die Datei wird nicht erneut befragt. |
| `trimStart` / `trimEnd` | Optionale Grenzen des Wiedergabe-Bereichs. `nil` heißt Dateianfang bzw. Dateiende. |
| `effectiveStart` / `effectiveEnd` | Wo die Wiedergabe tatsächlich beginnt und endet — die Trim-Punkte oder die Dateigrenzen. |
| `effectiveDuration` | Die Zeit, die der User tatsächlich meditiert. Danach filtert der `DurationFilter`, und diese Zahl steht in der Liste. |
| `formattedDuration` vs. `formattedFileDuration` | Effektive Dauer für Liste und Player, volle Dateilänge nur für die Datei-Info im Bearbeiten-Blatt. |
| `startGongEnabled` / `endGongEnabled` | Zwei unabhängige Schalter, siehe Start-/End-Gong. |
| `gongSoundId` | Der Klang für beide Gongs dieser Meditation, unabhängig von den Timer-Einstellungen. |
| `origin` | Aus welcher kuratierten Quelle die Meditation geholt wurde, siehe Herkunft. `nil` heißt: selbst importiert. |
| `fileBookmark` | Nur noch für die Migration von Altbeständen; der reguläre Weg ist `localFilePath`. |

Alle weiteren Felder stehen im Code.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/GuidedMeditation.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/GuidedMeditation.kt`

**Siehe auch:** `AudioMetadata`, `EditSheetState`, Wiedergabe-Bereich, Start-/End-Gong, Herkunft

---

#### GuidedMeditationGroup

**Typ:** Value Object
**Muster:** Sichtbare Ordnung

**Beschreibung:**
Die Meditationen eines Lehrers als Gruppe — so ist die Bibliotheksliste im Ruhezustand
geordnet. Gruppen stehen alphabetisch nach Lehrer, innerhalb einer Gruppe stehen die
Meditationen alphabetisch nach Titel. Sobald gesucht oder gefiltert wird, verschwindet die
Gruppierung zugunsten einer flachen Liste (siehe `LibrarySearchState`).

**Dateireferenzen:**
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/GuidedMeditationGroup.kt`
  (mit der Erweiterung `List<GuidedMeditation>.groupByTeacher()`)
- iOS: kein eigener Typ — die Gruppierung entsteht in der Ansicht. Die Ordnung ist
  dieselbe, nur ohne benanntes Modell.

---

#### DurationFilter

**Typ:** Enum
**Muster:** Filter-Stufe

**Beschreibung:**
Die fünf Stufen der Filterzeile über der Bibliothek (shared-081). Gefiltert wird die
**effektive** Dauer, also die Zahl, die in der Liste steht — eine zugeschnittene Meditation
fällt in die Stufe ihrer zugeschnittenen Länge, nicht in die ihrer Dateilänge.

**Stufen:** `all`, `upTo5`, `from5To15`, `from15To30`, `over30`

Die obere Grenze jeder Stufe ist ausschließend, damit jede Dauer genau einer Stufe gehört:
4:59 liegt in `upTo5`, 5:00 in `from5To15`. Stufen, in die keine Meditation fällt, stellt die
Filterzeile blass und nicht antippbar dar — `all` ist immer verfügbar, auch bei leerer
Bibliothek.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/DurationFilter.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/DurationFilter.kt`

**Siehe auch:** `GuidedMeditation.effectiveDuration`, `LibrarySearchState`

---

#### LibrarySearchEngine

**Typ:** Domain Service (reine Funktionen)
**Muster:** Suchregel

**Beschreibung:**
Die Regeln der Volltextsuche in der Bibliothek. Die Eingabe wird an Leerzeichen zerlegt,
alle Teile müssen zutreffen (UND), verglichen wird als Teilzeichenkette ohne Rücksicht auf
Groß-/Kleinschreibung und Diakritika.

**Rangfolge der Treffer** — vier Ränge, der beste gewinnt:

1. Wortanfang im Titel
2. Wortanfang beim Lehrer
3. Teilzeichenkette im Titel
4. Teilzeichenkette beim Lehrer

Bei mehreren Suchbegriffen zählt der beste erreichte Rang. Bei Gleichstand steht die zuletzt
hinzugefügte Meditation vorn. Die Engine liefert außerdem die Fundstellen, damit die Ansicht
sie hervorheben kann.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Services/LibrarySearchEngine.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/services/LibrarySearchEngine.kt`

**Siehe auch:** `LibrarySearchState`, `SearchHistory`

---

#### LibrarySearchState

**Typ:** Enum
**Muster:** Zustandsautomat

**Beschreibung:**
Welche Ansicht die Bibliothek gerade zeigt. Wird aus Sucheingabe, Fokus des Suchfelds,
gesetztem Dauer-Filter und Trefferzahl abgeleitet.

| Wert | Bedeutung |
|------|-----------|
| `idle` | Suchfeld nicht fokussiert, keine Eingabe, kein Filter — die nach Lehrern gruppierte Liste |
| `history` | Suchfeld fokussiert, noch keine Eingabe — der Suchverlauf ist sichtbar |
| `filtered` | Keine Eingabe, aber ein Dauer-Filter gesetzt — flache Liste (shared-081) |
| `results` | Eingabe und/oder Filter, mindestens ein Treffer |
| `empty` | Eingabe und/oder Filter, kein Treffer |

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Services/LibrarySearchState.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/LibrarySearchState.kt`

Der Typ liegt auf iOS unter `Services/`, auf Android unter `models/` — dieselbe Sache,
unterschiedlich einsortiert.

---

#### SearchHistory

**Typ:** Domain Service (reine Funktionen) + Persistenz-Protokoll
**Muster:** Verlauf

**Beschreibung:**
Die Regeln hinter „Zuletzt gesucht". Ein neuer Begriff wandert an die Spitze; ein bereits
vorhandener wird dabei entfernt und in der **neuen** Schreibweise wieder eingefügt.
Verglichen wird ohne Rücksicht auf Groß-/Kleinschreibung und Diakritika. Leere Eingaben
lassen den Verlauf unverändert. Die Liste wird auf eine feste Länge gekappt.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Services/SearchHistoryStore.swift` (Protokoll `SearchHistoryStore`
  und Regeln `SearchHistory`)
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/services/SearchHistory.kt`,
  Persistenz in `domain/repositories/SearchHistoryRepository.kt`

**Siehe auch:** Cross-Platform-Namensabweichungen (kanonisch: `SearchHistoryRepository`)

---

### Import

#### AudioMetadata

**Typ:** Value Object
**Muster:** Transportobjekt

**Beschreibung:**
Was die ID3-Tags einer Audiodatei hergeben: `artist`, `title`, `album` (alle optional) und
die gemessene `duration`. Wird beim Import gelesen und zu Vorschlägen verarbeitet.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/AudioMetadata.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/AudioMetadata.kt`

**Siehe auch:** `ImportPrefill`

---

#### PendingImport

**Typ:** Value Object
**Muster:** Schwebender Zustand

**Beschreibung:**
Ein Import zwischen Dateiwahl und Speichern. Solange dieser Wert gehalten wird, ist eine
Audiodatei ausgelesen, aber noch **nichts** persistiert: Die Datei wird erst beim Speichern
im Bearbeiten-Blatt kopiert und der Bibliothek hinzugefügt. Abbrechen verwirft den Zustand
samt Datei.

Der Wert merkt sich außerdem, ob der Zugriff auf die Quelldatei angemeldet werden musste —
dann muss er bei Abbruch wie bei Speichern wieder abgemeldet werden.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/PendingImport.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/PendingImport.kt`

**Siehe auch:** `ImportPrefill`, `EditSheetState`

---

#### ImportPrefill

**Typ:** Value Object
**Muster:** Vorschlagswert

**Beschreibung:**
Die Vorschläge für Lehrer und Titel, mit denen das Bearbeiten-Blatt beim Import vorbelegt
wird. Zwei Optionale — `nil` heißt „kein Vorschlag, das Feld bleibt leer".

Der Vorschlag ist **still**: Es gibt keine Kennzeichnung, woher er stammt, und keinen Hinweis
darauf, dass vorbelegt wurde. Darum wird die Quelle auch nicht gespeichert.

**Die Regeln, die den Vorschlag prägen:**

- Platzhalter werden verworfen — „Unknown Artist", „Untitled", „Audio", „Recording",
  „Voice Memo" und reine Titelnummern („Track 03", „03").
- Unbrauchbare Dateinamen werden verworfen: eine reine UUID, oder ein sehr langes Wort
  ohne jedes Trennzeichen.
- Aus dem Dateinamen werden Endung und führende Titelnummer entfernt, `_`, `-` und `.`
  werden zu Leerzeichen, und an Übergängen wie `MomentMal` oder `04Fuesse` wird ein
  Leerzeichen eingefügt.
- Die Groß-/Kleinschreibung innerhalb der Wörter bleibt unangetastet.
- Umlaute werden **nicht** zurückgeraten (`ue` → `ü` würde aus „Quelle" ein „Quölle"
  machen). Der User korrigiert das selbst.
- Findet sich kein Lehrer im ID3-Tag, wird der Dateiname gegen die bereits in der
  Bibliothek vorhandenen Lehrernamen geprüft — aber nur gegen hinreichend
  unterscheidbare (mindestens zwei Wörter oder sechs Zeichen), damit kurze Namen nicht
  überall zufällig zutreffen.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/ImportPrefill.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/ImportPrefill.kt`

---

#### EditSheetState

**Typ:** Value Object
**Muster:** Editor-Zustand

**Beschreibung:**
Zustand und Validierung beim Bearbeiten der Angaben einer Meditation. Hält das Original
neben den bearbeiteten Werten und beantwortet daraus zwei Fragen: Gibt es überhaupt
Änderungen, und sind die Eingaben gültig? `applyChanges()` erzeugt daraus die aktualisierte
`GuidedMeditation`.

Die Trim-Punkte werden hier als Text geführt (`m:ss`, `h:mm:ss` oder reine Minuten; leer
heißt „kein Zuschnitt") und beim Anwenden geparst. Das eigentliche Setzen der Punkte
geschieht seit shared-107 im Zuschnitt-Editor, nicht mehr in Textfeldern.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/EditSheetState.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/EditSheetState.kt`
  (dazu `EditSheetMode` für die Unterscheidung Hinzufügen/Bearbeiten; auf iOS liegt diese
  Unterscheidung in der Präsentationsschicht)

---

#### Link-Import

**Typ:** Protokoll (`AudioDownloadService`)
**Muster:** Holen aus der Ferne

**Beschreibung:**
Eine Meditation aus einer geteilten Adresse holen, statt sie aus den Dateien zu wählen.
Die Datei wird in ein temporäres Verzeichnis geladen, Antwort und Inhaltstyp werden geprüft,
danach läuft sie durch denselben Import-Weg wie eine lokale Datei.

Der Fortschritt wird nur gemeldet, wenn die Gesamtgröße bekannt ist — lieber keine Zahl als
eine erfundene. Abgebrochen wird über den umgebenden Vorgang, sodass genau dieser Download
endet und kein zufällig paralleler.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Services/AudioDownloadServiceProtocol.swift`,
  Fehler in `ios/StillMoment/Domain/Models/AudioDownloadError.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/services/UrlAudioDownloaderProtocol.kt`,
  Fehler in `domain/models/UrlAudioDownloadError.kt`, Prüfung geteilter Texte in
  `domain/models/UrlAudioValidator.kt`

**Siehe auch:** Cross-Platform-Namensabweichungen (kanonisch: `AudioDownloadService`)

---

#### Podcast-Import

**Typ:** Protokoll (`PodcastEpisodeResolver`)
**Muster:** Auflösen vor dem Holen

**Beschreibung:**
Sonderfall des Link-Imports: Ein geteilter Apple-Podcasts-Folgenlink
(`podcasts.apple.com/[<land>/]podcast/<name>/id<Podcast-ID>?i=<Folgen-ID>`) zeigt auf eine
Webseite, nicht auf die Audiodatei. Vor dem Download wird er über Apples Lookup-Dienst zur
Audiodatei beim Anbieter aufgelöst; danach läuft der normale Link-Import. Folgentitel und
Autor (sonst Podcast-Name) werden als Vorschlag für Titel und Lehrer:in übernommen und haben
Vorrang vor den ID3-Tags der Datei. Die Herkunft wird nicht gespeichert — die Folge ist danach
eine ganz normale Meditation.

Abgrenzung: **Link-Import** holt eine Datei von einer Adresse, die direkt auf Audio zeigt.
**Podcast-Import** löst zuerst eine Podcast-Folge zu einer solchen Adresse auf. Ein Link auf
einen ganzen Podcast (ohne Folgen-ID) wird nicht aufgelöst, sondern mit einem Hinweis
beantwortet.

Fehler werden nach Handlungsmöglichkeit genau drei Meldungen zugeordnet: einzelne Folge
teilen (`podcastWithoutEpisode`), gerade nicht erreichbar (`notReachable`, als einzige mit
„Erneut versuchen") und leider nicht möglich (`episodeUnavailable`).

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/ApplePodcastsLink.swift`,
  `Domain/Models/PodcastEpisode.swift`, `Domain/Services/PodcastEpisodeResolverProtocol.swift`,
  `Infrastructure/Services/ApplePodcastsEpisodeResolver.swift`, Ablauf in
  `Application/InboxHandler.swift`, Meldungen in `Application/InboxError.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/ApplePodcastsLink.kt`,
  `domain/models/PodcastEpisode.kt`, `domain/services/PodcastEpisodeResolverProtocol.kt`,
  `infrastructure/network/ApplePodcastsEpisodeResolver.kt`, Ablauf in
  `data/LinkImportHandler.kt`, Meldungen in `domain/models/LinkImportFailure.kt`

**Siehe auch:** Link-Import, `dev-docs/concepts/podcast-import.md`

---

#### ShareOutcome

**Typ:** Enum (nur iOS)
**Muster:** Reine Zuordnung

**Beschreibung:**
Was die Share-Extension zeigt, nachdem etwas an Still Moment geteilt wurde. Die Zuordnung
`ShareOutcome.evaluate(SharedContent)` entscheidet allein anhand des geteilten Inhalts
(`audioFile`, `link`, `nothing`):

| Wert | Wann | Meldung |
|------|------|---------|
| `confirmation` | MP3/M4A-Datei oder Webadresse (`http`/`https`) | "Fast geschafft" — die App übernimmt beim nächsten Öffnen |
| `unsupportedFormat` | Audiodatei in einem anderen Format oder ohne Endung | nur MP3 und M4A |
| `noLink` | Link, der keine Webadresse ist (`mailto:`, `tel:` …) | "Kein Link gefunden" |
| `unreadable` | Nichts Verwertbares geteilt, Laden oder Ablegen in der Inbox fehlgeschlagen | "Import fehlgeschlagen" |

Ob unter einer Webadresse wirklich Audio liegt, prüft erst die App beim Link-Import. Der Typ
liegt im Domain-Ordner der App, damit er testbar ist, wird aber nur von der Share-Extension
benutzt. Android braucht ihn nicht: Dort öffnet sich beim Teilen direkt die App.

Mehrfaches Teilen ist nie ein Fehler: Der zuletzt geteilte Eintrag gewinnt. Die Extension legt
einen Eintrag unter dem Namen der Datei bzw. dem letzten Teil der Adresse in der Inbox ab und
ersetzt dabei einen gleichnamigen, der noch wartet (derselbe Link oder dieselbe Datei doppelt,
oder `…/25401/download` und danach `…/25402/download`). Verschieden benannte Einträge räumt die
App auf: Sie importiert nur den neuesten. Android verhält sich gleich (shared-132).

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/ShareOutcome.swift` (Mitglied auch im Extension-Target),
  Anzeige in `ios/StillMomentShareExtension/ShareConfirmationView.swift`, Ablage in der Inbox in
  `ios/StillMoment/Infrastructure/Services/ShareInbox.swift` (Mitglied auch im Extension-Target),
  Format eines geteilten Links in `ios/StillMoment/Domain/Models/URLReference.swift`
- Android: nicht vorhanden (keine Share-Extension)

**Siehe auch:** Link-Import

---

### Wiedergabe

#### GuidedMeditationSettings

**Typ:** Value Object
**Muster:** Einstellungsobjekt

**Beschreibung:**
Die Einstellungen für die Wiedergabe geführter Meditationen. Aktuell genau eine: die
Vorbereitungszeit vor dem Start.

**Gültige Werte:** aus (`nil`), 5, 10, 15, 20, 30 oder 45 Sekunden. Ein anderer Wert wird auf
den nächstgelegenen gültigen gezogen. In der Ablage bedeutet die 0 „aus".

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/GuidedMeditationSettings.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/GuidedMeditationSettings.kt`

**Siehe auch:** `Praxis` (das Gegenstück für den Timer)

---

#### PreparationCountdown

**Typ:** Value Object (unveränderlich)
**Muster:** Wie `MeditationTimer` — `tick()` liefert eine neue Instanz

**Beschreibung:**
Die Vorbereitungszeit vor dem Start einer geführten Meditation: Zeit, das Telefon wegzulegen
und zur Ruhe zu kommen. Hält die konfigurierte Gesamtdauer und die verbleibenden Sekunden,
kennt daraus den Fortschritt und weiß, wann er abgelaufen ist.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/PreparationCountdown.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/PreparationCountdown.kt`

**Siehe auch:** `TimerState.preparation` (das Gegenstück im Timer), `GuidedMeditationSettings`

---

#### Start-/End-Gong

**Typ:** Konzept (Protokoll `MeditationGongPlayer`)
**Muster:** Rahmung der Wiedergabe

**Beschreibung:**
Zwei unabhängige Schalter pro Meditation (`startGongEnabled`, `endGongEnabled`, shared-106)
rahmen die Wiedergabe mit einem Gong: Start-Gong → kurze Atempause (2 s) → Audio; am
effektiven Ende klingt der End-Gong vollständig aus, bevor die Audio-Sitzung freigegeben wird
— das macht ihn auch auf dem Sperrbildschirm hörbar.

Der Klang ist pro Meditation wählbar (`gongSoundId`) und gilt für beide Gongs; zur Auswahl
stehen dieselben Gongs wie im Timer, ohne die Vibrationsoption. Die Lautstärke folgt den
Timer-Einstellungen (`Praxis.gongVolume`).

Gespielt wird über einen eigenen, kleinen Player — der `AudioService` des Timers wird bewusst
nicht wiederverwendet, weil eine zweite Instanz doppelte Konflikt-Handler und
Keep-Alive-Player anmelden würde. Der Abschluss-Rückruf kommt **immer**, auch wenn die
Wiedergabe scheitert oder unterbrochen wird, damit der Ablauf sich darauf verlassen kann.

Altbestände: Einträge ohne die Schalter laden als „aus" mit Standard-Gong. Das frühere
kombinierte Feld `gongEnabled` lädt mit beiden Gongs aktiviert — es existiert nur noch als
Lese-Schlüssel für Altdaten, nicht mehr als Eigenschaft.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Services/MeditationGongPlayerProtocol.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/services/MeditationGongPlayerProtocol.kt`

**Siehe auch:** `GongSound`, `GuidedMeditation`

---

### Zuschnitt

#### Wiedergabe-Bereich

**Typ:** Konzept (das Trim-Punkte-Paar)
**Muster:** Nicht-destruktiver Bereich

**Beschreibung:**
Der für den User sichtbare Begriff für den durch `trimStart`/`trimEnd` (shared-105)
begrenzten Bereich einer Meditation. Im Bearbeiten-Blatt öffnet die Karte
„Wiedergabe-Bereich" (shared-107) einen bildschirmfüllenden Wellenform-Editor, in dem zwei
ziehbare Griffe Anfang und Ende setzen.

**Nicht-destruktiv:** Die Audiodatei bleibt unverändert, der Bereich ist jederzeit änderbar
oder entfernbar. Die Wiedergabe beginnt bei `effectiveStart` und endet bei `effectiveEnd` —
über denselben Abschluss-Weg wie ein natürliches Dateiende, auch auf dem Sperrbildschirm.
Spulen und Springen werden auf den Bereich begrenzt.

**Regeln:** Zwischen Anfang und Ende gilt ein Mindestabstand von 25 Sekunden. Ist der Bereich
praktisch die ganze Datei (Anfang ≤ 1 s und Ende ≥ Dauer − 1 s), wird kein Zuschnitt
gespeichert.

**Bedienung:** Die Abspielposition hat eine eigene Spur in Salbeigrün oberhalb der
Wellenform; Berührungen werden rein geometrisch zugeordnet (`TrimHitTesting`: oben die
Abspielposition, unten die Marken, im Gedränge gewinnt die aktive Marke).

**Dateireferenzen:**
- iOS Editor-Zustand: `ios/StillMoment/Domain/Models/TrimEditorState.swift`
- iOS Editor-Oberfläche: `ios/StillMoment/Presentation/Views/GuidedMeditations/TrimEditor/`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TrimEditorState.kt`

**Siehe auch:** `GuidedMeditation`, Wellenform, Zoom im Zuschnitt-Editor, `EditSheetState`

---

#### TrimEditorState

**Typ:** Value Object (unveränderlich)
**Muster:** Editor-Zustand

**Beschreibung:**
Der Zustand des Zuschnitt-Editors, während der User Griffe zieht oder Marken feinjustiert.
Hält Anfang, Ende, die Dateilänge und die gerade aktive Marke (`TrimPoint`: `start` oder
`end`). Jede Änderung liefert eine neue Instanz.

Beim Öffnen wird mit den effektiven Grenzen der Meditation begonnen. Ist die Datei kürzer als
der Mindestabstand von 25 Sekunden, bleibt der volle Dateibereich fest und Bewegungen laufen
ins Leere — es ist schlicht kein Platz, den Mindestabstand einzuhalten.

Abspielposition, „spielt gerade" und die Vorhör-Funktion sind Sache der Oberfläche und
gehören bewusst nicht in diesen Zustand.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/TrimEditorState.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TrimEditorState.kt`

---

#### Wellenform

**Typ:** Value Object (`MeditationWaveform`)
**Muster:** Vorberechnete, zwischengespeicherte Darstellung

**Beschreibung:**
Die vorberechnete, normalisierte Amplituden-Darstellung einer Meditation für den
Zuschnitt-Editor (shared-107). Eine feste Anzahl Ausschlagswerte, jeweils auf `[0, 1]`
normalisiert. Darin heben sich dichte Sprachblöcke (Einleitung, Schlussworte) sichtbar von
der stillen Meditation ab — genau das macht die Marken setzbar.

Die Daten sind klein, werden beim Import im Hintergrund berechnet und je Meditation
zwischengespeichert. Fehlen sie (Bestandsmeditation nach einem Update), werden sie beim
ersten Öffnen einmalig berechnet. Da die Audiodatei nie verändert wird, braucht der
Zwischenspeicher keine Invalidierung. Scheitert das Dekodieren, zeigt der Editor statt Balken
eine schlichte Linie — die Funktion bleibt erhalten.

**Dateireferenzen:**
- iOS Modell: `ios/StillMoment/Domain/Models/MeditationWaveform.swift`
- iOS Bereitstellung: `ios/StillMoment/Domain/Services/WaveformProviderProtocol.swift`,
  `WaveformCacheServiceProtocol.swift`, `WaveformGenerationServiceProtocol.swift`
- Android Modell: `android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationWaveform.kt`
- Android Bereitstellung: `android/app/src/main/kotlin/com/stillmoment/domain/services/WaveformServiceProtocols.kt`

**Siehe auch:** Wiedergabe-Bereich, `GuidedMeditation`

---

#### Zoom im Zuschnitt-Editor

**Typ:** Konzept (`TrimZoomWindow`)
**Muster:** Reine Berechnung

**Beschreibung:**
Damit Marken auch an den Rändern präzise gesetzt werden können, zeigt der Editor nicht immer
die ganze Datei, sondern einen vergrößerten Ausschnitt. Dessen Breite wächst mit der Datei
(ein Anteil von ihr, mindestens zwei Minuten, nie mehr als die Datei selbst). Beim Anfassen
einer Marke rückt der Ausschnitt so, dass sie nahe ihrer eigenen Kante liegt — die Marke
`start` links, die Marke `end` rechts — damit in Ziehrichtung Platz bleibt. Bei Dateien, die
nicht länger als der Ausschnitt sind, gibt es effektiv keinen Zoom.

Der Ausschnitt ist Zustand der Oberfläche und liegt bewusst **außerhalb** von
`TrimEditorState`.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Application/Models/TrimZoomWindow.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TrimZoomWindow.kt`

Der Typ liegt auf iOS in der Anwendungsschicht, auf Android im Domänen-Paket — dieselbe
Rechnung, unterschiedlich einsortiert.

---

## Timer

Die stille Meditation mit konfigurierbarem Timer. Innerhalb dieser Domäne ist der Timer
selbst die Hauptsache, der Hintergrundklang ist Beiwerk.

Zur Einordnung im Produkt: Kernfeature der App ist die Bibliothek, der stille Timer ist die
Ergänzung — siehe „Feature priority" in `CLAUDE.md`.

### TimerState

**Typ:** Enum
**Muster:** Zustandsautomat

| Wert | Bedeutung |
|------|-----------|
| `idle` | Timer bereit zum Start |
| `preparation` | Vorbereitungsphase vor der Meditation (konfigurierbar) |
| `startGong` | Start-Gong spielt, der Countdown läuft bereits |
| `running` | Timer läuft, stille Meditationsphase |
| `endGong` | Timer bei 0, Abschluss-Gong spielt. Ring voll, 00:00 angezeigt. Der Wechsel zu `completed` erfolgt erst nach dem Audio-Rückruf (`endGongFinished`). |
| `completed` | Timer abgelaufen, Meditation beendet |

**Zustandsautomat:**

```
idle --> preparation --> startGong --> running --> endGong --> completed
  |                        ^
  |                        |
  +------------------------+

Pfade:
- Voll: idle → preparation → startGong → running → endGong → completed
- Ohne Vorbereitung: idle → startGong → running → endGong → completed
- Der Start-Gong spielt im startGong-Zustand; das Hintergrund-Audio startet erst
  beim Übergang zu running
- running wechselt zu endGong (Timer bei 0), endGong zu completed (Audio-Rückruf)
- endGong: Abschluss-Gong spielt, die Oberfläche zeigt 00:00 mit vollem Ring,
  das Keep-Alive bleibt aktiv
```

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerState.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerState.kt`

---

### TimerAction

**Typ:** Enum
**Muster:** Befehl/Ereignis

**Benutzeraktionen (Verb + Pressed):**

| Aktion | Bedeutung |
|--------|-----------|
| `startPressed` | Start-Knopf gedrückt |
| `resetPressed` | Zurücksetzen-Knopf gedrückt |

**Systemereignisse (Verb + Partizip):**

| Ereignis | Bedeutung |
|----------|-----------|
| `preparationFinished` | Vorbereitung abgeschlossen |
| `startGongFinished` | Start-Gong fertig gespielt, die stille Meditation beginnt |
| `timerCompleted` | Timer bei 0 angekommen, wechselt in die endGong-Phase |
| `endGongFinished` | Abschluss-Gong fertig gespielt (Audio-Rückruf), wechselt zu completed |
| `intervalGongTriggered` | Intervall-Gong soll spielen (ausgelöst durch `TimerEvent.intervalGongDue`) |

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerAction.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerAction.kt`

**Siehe auch:** `TimerReducer` (Muster in `../architecture/ddd.md`)

---

### TimerEvent

**Typ:** Enum
**Muster:** Domänenereignis

**Beschreibung:**
Ereignisse, die `MeditationTimer.tick()` ausgibt. Sie drücken aus, was während eines Ticks
passiert ist. Das ViewModel verarbeitet sie direkt, statt Übergänge durch Vergleich mit dem
vorherigen Zustand zu erschließen.

| Ereignis | Bedeutung |
|----------|-----------|
| `preparationCompleted` | Vorbereitung abgeschlossen, die Start-Gong-Phase beginnt |
| `meditationCompleted` | Timer bei 0, die End-Gong-Phase beginnt |
| `intervalGongDue` | Ein Intervall-Gong ist fällig (`tick()` hat das intern vermerkt) |

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerEvent.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerEvent.kt`

**Siehe auch:** `MeditationTimer.tick()`, `IntervalSettings`

---

### TimerEffect

**Typ:** Enum
**Muster:** Seiteneffekt

| Kategorie | Effekte |
|-----------|---------|
| Sitzung | `activateTimerSession`, `deactivateTimerSession` |
| Hintergrund-Audio | `startBackgroundAudio(soundId:volume:)`, `stopBackgroundAudio` |
| Klänge | `playStartGong`, `playIntervalGong(soundId:volume:)`, `playCompletionSound` |
| Timer-Dienst | `startTimer(durationMinutes:)`, `resetTimer`, `beginRunningPhase` |
| Zustandsübergänge | `transitionToCompleted`, `clearTimer` |
| Persistenz | `saveSettings(MeditationSettings)` |

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerEffect.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerEffect.kt`

**Muster-Dokumentation:** `../architecture/ddd.md` (Effect Pattern)

---

### MeditationTimer

**Typ:** Value Object (unveränderlich)
**Muster:** Value Object mit Domänenlogik

**Beschreibung:**
Das zentrale Timer-Modell. Kennt Gesamtdauer, verbleibende Zeit, Zustand und
Vorbereitungszeit; daraus abgeleitet Fortschritt und „abgelaufen?".

| Methode | Bedeutung |
|---------|-----------|
| `tick(intervalSettings:)` | Neue Instanz mit Zeit − 1, dazu die entstandenen `TimerEvent`s |
| `withState(_:)` | Neue Instanz mit neuem Zustand |
| `startPreparation()` | Neue Instanz im Vorbereitungsmodus |
| `markIntervalGongPlayed()` | Neue Instanz mit gesetztem Gong-Vermerk |
| `shouldPlayIntervalGong(intervalMinutes:mode:)` | Ist ein Intervall-Gong fällig? |
| `reset()` | Zurückgesetzter Timer |

**Invarianten:**
- `durationMinutes`: 1…60
- `remainingSeconds`: 0…`totalSeconds`
- Jede Änderung erzeugt eine neue Instanz

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/MeditationTimer.swift` (Anzeige-Ableitungen in
  `MeditationTimer+Display.swift`)
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationTimer.kt`

---

### Praxis

**Typ:** Value Object (unveränderlich)
**Muster:** Einstellungsobjekt mit Identität

**Beschreibung:**
Die **eine** gespeicherte Timer-Konfiguration und damit die Wahrheit über alle
Timer-Einstellungen. Es gibt genau eine Praxis — keine Mehrfach-Voreinstellungen, kein
Umschalten, kein eigener Editor-Bildschirm. Sie wird direkt auf dem Timer-Bildschirm
bearbeitet und bei jeder Änderung sofort gespeichert (siehe
`dev-docs/reference/ux-conventions.md` §2).

Sie umfasst Dauer, Vorbereitungszeit, Start-/End-Gong, Intervall-Gongs und den
Hintergrundklang, jeweils mit Lautstärke. `shortDescription` fasst das für die Anzeige
zusammen (z. B. „10 Min · Stille · Tempelglocke · 15 s Vorbereitung").

**Invarianten:**
- Es existiert genau eine Praxis; sie wird beim ersten Zugriff (`load()`) als Standard
  angelegt und nie gelöscht
- `durationMinutes`: 1…60; die Dauer lässt sich für eine einzelne Sitzung abweichend wählen
- Alle Lautstärken: 0,0…1,0
- Jede Änderung erzeugt eine neue Instanz

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/Praxis.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/Praxis.kt`

**Siehe auch:** `PraxisRepository`, `MeditationSettings`

---

### PraxisRepository

**Typ:** Protokoll
**Muster:** Repository

**Beschreibung:**
Laden und Speichern der einen Praxis. Kein Mehrfach-CRUD — es gibt genau eine Konfiguration.
`load()` legt beim ersten Aufruf (Neuinstallation oder Migration) eine Standard-Praxis an,
`save(_:)` ersetzt die bestehende.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Services/PraxisRepository.swift`,
  Implementierung `ios/StillMoment/Infrastructure/Services/UserDefaultsPraxisRepository.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/repositories/PraxisRepository.kt`,
  Implementierung `data/local/PraxisDataStore.kt`

---

### MeditationSettings

**Typ:** Value Object
**Muster:** Abgeleitete Sicht

**Beschreibung:**
Die aus der Praxis abgeleitete Sicht, mit der Reducer und Timer arbeiten
(`praxis.toMeditationSettings()`). **Nicht** selbst die Quelle der Wahrheit: Gespeichert wird
die Praxis, nicht dieses Objekt. Wer eine Einstellung ändern will, ändert die Praxis.

Die Felder entsprechen denen der Praxis; Standardwerte und gültige Bereiche stehen dort. Zum
Absichern von Eingaben gibt es `validateInterval(_:)`, `validateDuration(_:)` und
`validatePreparationTime(_:)`, die auf den nächstgelegenen gültigen Wert ziehen.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/MeditationSettings.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationSettings.kt`
  (Ablage-Schlüssel in `MeditationSettingsKeys`, auf iOS als `MeditationSettings.Keys`
  eingebettet)

**Siehe auch:** `Praxis`

---

### IntervalSettings

**Typ:** Value Object
**Muster:** Einstellungsobjekt

**Beschreibung:**
Was `MeditationTimer.tick(intervalSettings:)` braucht, um Intervall-Gongs zu erkennen:
`intervalMinutes` und `mode`. Wird aus der Praxis aufgebaut, wenn Intervall-Gongs aktiviert
sind, sonst `nil`.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/IntervalSettings.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/IntervalSettings.kt`

**Siehe auch:** `IntervalMode`

---

### IntervalMode

**Typ:** Enum
**Muster:** Strategie

**Beschreibung:**
Wie Intervallklänge während der Meditation ausgelöst werden.

| Wert | Bedeutung |
|------|-----------|
| `REPEATING` | Ein Gong bei jedem vollen Intervall ab Start (Standard) |
| `AFTER_START` | Genau ein Gong X Minuten nach dem Start |
| `BEFORE_END` | Genau ein Gong X Minuten vor dem Ende |

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/IntervalMode.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/IntervalMode.kt`

**Algorithmus-Details:** `../architecture/ddd.md` (Flexible Intervall-Modi)

**Siehe auch:** `MeditationTimer.shouldPlayIntervalGong()`

---

### GongSound

**Typ:** Value Object
**Muster:** Lokalisierter Inhalt

**Beschreibung:**
Ein wählbarer Gong-Klang für Start-/End-Gong und Intervall-Gong. Unveränderliches Value
Object aus Kennung, Audio-Ressource und lokalisiertem Namen.

**Für Start und Ende:**

| Kennung | EN | DE |
|---------|----|----|
| `temple-bell` | Temple Bell | Tempelglocke |
| `classic-bowl` | Classic Bowl | Klassisch |
| `deep-resonance` | Deep Resonance | Tiefe Resonanz |
| `clear-strike` | Clear Strike | Klarer Anschlag |

**Zusätzlich nur für den Intervall-Gong:**

| Kennung | EN | DE |
|---------|----|----|
| `soft-interval` | Soft Interval Tone | Sanfter Intervallton |

**Standard:** `temple-bell` für Start/Ende, `soft-interval` für das Intervall.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/GongSound.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/GongSound.kt`

**Siehe auch:** Vibration statt Gong

---

### Vibration statt Gong

**Typ:** Konzept
**Muster:** Stille Alternative

**Beschreibung:**
Statt eines hörbaren Gongs kann ein spürbares Signal treten — gedacht für Umgebungen, in
denen ein Klang stören würde. Der Start-/End-Gong vibriert lang, der Intervall-Gong kurz. Für
geführte Meditationen steht diese Option bewusst **nicht** zur Verfügung.

**Wichtig für den Sperrbildschirm:** Vibration muss über den Systemklang-Weg ausgelöst
werden, nicht über die Haptik-Schnittstellen der Oberfläche — die wirken nur im Vordergrund
und damit nicht im Standard-Anwendungsfall (Meditation starten, Telefon weglegen).

**Dateireferenzen:**
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/services/VibrationServiceProtocol.kt`
- iOS: kein Domänen-Typ — gelöst im `AudioService` der Infrastrukturschicht

**Siehe auch:** `GongSound`, `../architecture/audio-system.md`

---

### Soundscape

**Typ:** Konzept
**Muster:** Lokalisierter Inhalt

**Beschreibung:**
Der optionale Hintergrundklang während der stillen Meditation. Beiwerk zum Timer, kein
eigenständiges Feature. „Soundscape" bzw. „Klangkulisse" ist der Begriff in der Oberfläche;
im Code steht dahinter eines von zwei Modellen — je nachdem, woher der Klang kommt.

| Modell | Was es ist |
|--------|-----------|
| `BackgroundSound` | Ein eingebauter Klang aus dem mitgelieferten Katalog (`sounds.json`). Name und Beschreibung werden beim Laden für die Gerätesprache aufgelöst. |
| `CustomAudioFile` | Ein selbst importierter Klang, kopiert in den App-Speicher. Der Anzeigename stammt beim Import aus dem Dateinamen und ist änderbar. Die Art führt `CustomAudioType` — aktuell nur `SOUNDSCAPE`; das Enum bleibt bestehen, damit die Ablage ein selbsterklärendes Feld behält. |
| `ResolvedSoundscape` | Das Ergebnis der Auflösung: Kennung und Anzeigename, Herkunft egal. Damit arbeiten alle, die nur abspielen wollen. |

**Der Sonderfall „Stille":** Die Kennung `silent` ist kein abspielbares Audio, sondern das
Signal „kein Soundscape gewählt". Der Resolver löst sie zu „nichts" auf; die Oberfläche
nutzt sie, um die Ruhezeile gedämpft darzustellen (shared-089).

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/BackgroundSound.swift`, `CustomAudioFile.swift`,
  `ResolvedSoundscape.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/BackgroundSound.kt`,
  `CustomAudioFile.kt`, `CustomAudioType.kt`, `ResolvedSoundscape.kt`

**Siehe auch:** `SoundscapeResolver`

---

### SoundscapeResolver

**Typ:** Protokoll
**Muster:** Einheitliche Auflösung

**Beschreibung:**
Löst eine Soundscape-Kennung auf, ohne dass Aufrufer wissen müssen, ob dahinter ein
eingebauter Katalog-Eintrag oder eine selbst importierte Datei steht. Die Kennung `silent`
ergibt „nichts".

| Methode | Bedeutung |
|---------|-----------|
| `resolve(id:)` | Der aufgelöste Soundscape mit Anzeigename |
| `resolveAudioURL(id:)` | Die Adresse zum Abspielen |
| `allAvailable()` | Alle verfügbaren Soundscapes, eingebaute und eigene |

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Services/SoundscapeResolverProtocol.swift`,
  Implementierung `ios/StillMoment/Infrastructure/Services/SoundscapeResolver.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/services/SoundscapeResolverProtocol.kt`,
  Implementierung `infrastructure/audio/SoundscapeResolver.kt`

---

### LocalizedString

**Typ:** Value Object
**Muster:** Eingebettetes Value Object

**Beschreibung:**
Deutscher und englischer Text für Name und Beschreibung eines Soundscapes.

**Dateireferenzen:**
- iOS: eingebettet in `BackgroundSound.swift`
- Android: eingebettet im Schema von `sounds.json`

---

## App-weit

Konzepte, die beide Bereiche betreffen.

### AppTab

**Typ:** Enum
**Muster:** Navigations-Wahrheit

**Beschreibung:**
Die drei Tabs der App und ihre Reihenfolge — die einzige Quelle der Wahrheit für Navigation
und das Merken des zuletzt gewählten Tabs.

**Werte und Reihenfolge:** `timer`, `library`, `settings`

**Standard beim ersten Start:** `library`. Das ist eine Produktentscheidung, keine technische
(shared-084): Die Bibliothek ist das Kernfeature, der Timer die Ergänzung — siehe „Feature
priority" in `CLAUDE.md`.

**Dateireferenzen:**
- iOS: `ios/StillMoment/StillMomentApp.swift` (außerhalb des Domänen-Ordners)
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/AppTab.kt`
  (führt zusätzlich die Navigations-Route je Tab)

---

### MeditationPhase

**Typ:** Enum
**Muster:** Visuelle Phase

**Beschreibung:**
Die visuelle Phase einer Meditation, geteilt zwischen Timer und Player: `preRoll` (die
Vorbereitungszeit) und `playing` (die laufende Meditation).

Eine **Layout**-Phase, kein Audio-Zustand: Eine Pause im Player oder das Laden einer Datei
bleiben `playing`, weil sich der Atemkreis visuell identisch verhält — der Bogen friert ein,
der Atem läuft weiter. Nur die Vorbereitungsphase zeigt ein anderes Inneres.

**Dateireferenzen:**
- iOS: `ios/StillMoment/Application/Models/MeditationPhase.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationPhase.kt`

Der Typ liegt auf iOS in der Anwendungsschicht, auf Android im Domänen-Paket.

---

### ColorTheme

**Typ:** Enum
**Muster:** Einstellungswert

**Beschreibung:**
Die Farbthema-Auswahl. Jedes Thema hat eine helle und eine dunkle Fassung.

| Wert | Bedeutung |
|------|-----------|
| `candlelight` | Kerzenschein — warm/sandfarben (Standard) |
| `forest` | Wald — warm-neutral, natürlich |
| `moon` | Mond — silber/indigo, nächtlich |

**Ablage:** `@AppStorage("selectedTheme")` über den `ThemeManager`

**Kette:**
```
ColorTheme (Domäne) → ThemeManager (Präsentation) → ThemeRootView → ThemeColors → @Environment(\.themeColors)
```

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/ColorTheme.swift`
- Farbsystem: `dev-docs/reference/color-system.md`

---

### AppearanceMode

**Typ:** Enum
**Muster:** Einstellungswert

**Beschreibung:**
Erlaubt es, helle oder dunkle Darstellung unabhängig vom Gerät zu erzwingen.

| Wert | Bedeutung |
|------|-----------|
| `system` | Folgt der Geräte-Einstellung |
| `light` | Erzwingt helle Darstellung |
| `dark` | Erzwingt dunkle Darstellung (Standard seit shared-122) |

**Ablage:** `@AppStorage("appearanceMode")` über den `ThemeManager`

**Kette:**
```
AppearanceMode (Domäne) → ThemeManager (Präsentation) → ThemeRootView → .preferredColorScheme()
```

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/AppearanceMode.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/AppearanceMode.kt`

---

### Rückmeldung (`FeedbackLinks`)

**Typ:** Konzept
**Muster:** Feste Adressen nach außen

**Beschreibung:**
Die zwei Wege, auf denen jemand der App etwas zurückgeben kann, beide im eigenen Abschnitt
„Rückmeldung" (EN „Feedback") der Einstellungen, zwischen „Geführte Meditationen" und
„Info & Rechtliches" (shared-135):

- **App bewerten** (Untertitel „Damit andere Still Moment finden") öffnet die Store-Seite von Still Moment direkt beim Bewerten
  (iOS: App Store, Android: Google Play, ohne Play-Store-App die Webseite).
- **Schreib uns** (Untertitel „Ideen, Wünsche oder einfach ein Gruß") öffnet eine neue Mail an `hello@stillmoment.app`, Betreff „Still Moment",
  im Text App-Version und Betriebssystem — sichtbar und vor dem Senden löschbar. Gibt es
  kein Mail-Programm, zeigt die App die Adresse zum Kopieren.

**Bewusst nicht:** Die App fragt nie von sich aus nach einer Bewertung (kein
Bewertungsfenster des Systems), und es gibt kein Formular und keinen Feedback-Dienst — die
App hat keinen Server und misst nichts (shared-134).

**Dateireferenzen:**
- iOS: `ios/StillMoment/Domain/Models/FeedbackLinks.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/FeedbackLinks.kt`

---

## Namenskonventionen

### Aktionen (TimerAction)

| Muster | Beispiel | Verwendung |
|--------|----------|------------|
| `verbPressed` | `startPressed`, `resetPressed` | Benutzer-Interaktion |
| `nounVerbed` | `preparationFinished`, `timerCompleted`, `endGongFinished` | Systemereignis |
| `nounVerbTriggered` | `intervalGongTriggered` | Internes Ereignis (aus einem `TimerEvent`) |

### Effekte (TimerEffect)

| Muster | Beispiel | Verwendung |
|--------|----------|------------|
| `configureNoun` | `configureAudioSession` | Einrichten |
| `verbNoun` | `startBackgroundAudio`, `playStartGong` | Aktion ausführen |
| `saveNoun(data)` | `saveSettings(MeditationSettings)` | Persistenz |

### Cross-Platform-Namensabweichungen

Beide Plattformen sollen dieselben Begriffe tragen. Wo sie heute auseinanderlaufen, gilt der
**kanonische** Name — er ist das Wort, mit dem über die Sache gesprochen und geschrieben
wird. Der Code wird deswegen nicht sofort umbenannt; wer die Stelle ohnehin anfasst, zieht
sie nach.

| Konzept | Kanonisch | Abweichung | Warum so |
|---------|-----------|------------|----------|
| Katalog eingebauter Klänge | `BackgroundSoundRepository` | Android: `SoundCatalogRepository` | Folgt dem Modellnamen `BackgroundSound`, den beide Plattformen tragen |
| Einstellungen geführter Meditationen | `GuidedMeditationSettingsRepository` | iOS: `GuidedSettingsRepository` | Folgt dem Modellnamen `GuidedMeditationSettings`; die iOS-Kurzform ist der Ausreißer |
| Suchverlauf | `SearchHistoryRepository` | iOS: `SearchHistoryStore` | `Repository` ist projektweit gesetzt (`PraxisRepository` auf beiden Plattformen) |
| Persistenz der Bibliothek | `GuidedMeditationRepository` | iOS: `GuidedMeditationServiceProtocol` | Kernaufgabe ist das Halten der Bibliothek; die zusätzliche Dateikopie und Bookmark-Migration auf iOS ändern daran nichts |
| Audio-Download | `AudioDownloadService` | Android: `UrlAudioDownloader` | Das `Url`-Präfix ist redundant — Downloads kommen immer von einer Adresse |
| Meldungen beim Link-/Podcast-Import | `LinkImportFailure` | iOS: `InboxError` | Der iOS-Typ deckt zusätzlich Fehler der Inbox der Share-Extension ab, die es auf Android nicht gibt; für die Import-Meldungen ist das Konzept dasselbe |
| Timer-Zustandshaltung | `TimerService` | Android: `TimerRepository` | Der Android-Typ hat `start`/`tick`/`reset` und keinerlei Persistenz. Das ist kein Repository, sondern eine echte Abweichung im Entwurf, nicht nur im Namen. |

**Keine Abweichung, sondern Plattform-Konvention:** Das Suffix `Protocol` auf iOS
(`CustomAudioRepositoryProtocol` vs. `CustomAudioRepository`,
`MeditationSourceRepositoryProtocol` vs. `MeditationSourceRepository`,
`AudioMetadataServiceProtocol` vs. `AudioMetadataService`). Gemeint ist dieselbe Sache; das
Glossar nennt sie ohne Suffix.

Ebenso Plattform-Konvention sind die View-Suffixe: iOS `*View` / `*Sheet`, Android
`*Screen` / `*Sheet` (`TimerView` ↔ `TimerScreen`). Darüber hinaus weichen View-Namen an
diesen Stellen ab — wer per Namen sucht, stolpert sonst:

- **Wortstellung:** iOS `*Selection*` ↔ Android `Select*`
  (`GongSelectionView` ↔ `SelectGongScreen`, `BackgroundSoundSelectionView` ↔ `SelectBackgroundSoundScreen`).
- **Laufender Timer:** iOS hat keinen eigenen Screen — der Running-State lebt in `TimerView`.
  Android trennt ihn als `TimerFocusScreen` ab.
- **„Guided"-Präfix:** iOS `GuidedMeditationEditSheet` ↔ Android `MeditationEditSheet`;
  bei Liste und Player tragen beide das Präfix.

---

## Wartungshinweise

### Was gehört ins Glossar

**Aufnehmen, was in einem Gespräch über die App fallen könnte.** Alles, worüber User, Ticket
oder Produktentscheidung reden — Wiedergabe-Bereich, Praxis, Dauer-Filter, Suchverlauf
— dazu die Zustandsautomaten, weil sie das Verhalten definieren.

**Nicht aufnehmen:** Rechen-, Puffer- und Plattform-Hilfsmittel. Sie gehören in die
Architektur-Dokumentation, nicht hierher.

| Nicht im Glossar | Weil |
|------------------|------|
| `WaveformAccumulator`, `SampledWaveformAccumulator`, `AudioFrameReader` | Rechenwerk hinter der Wellenform — über sie spricht niemand |
| `MediaPlayerProtocol`, `MediaPlayerFactoryProtocol`, `VolumeAnimatorProtocol`, `ProgressSchedulerProtocol`, `ClockProtocol`, `LoggerProtocol` | Abstraktionen über Plattform-Schnittstellen, rein technisch |
| `AudioFocusManagerProtocol`, `TimerForegroundServiceProtocol`, `NowPlayingInfoProvider`, `AudioSource` | Audio-Koordination — beschrieben in `../architecture/audio-system.md` |
| Fehler-Enums (`AudioServiceError`, `WaveformGenerationError`, …) | Technische Fehlerfälle; wo ein Fehler fachlich etwas bedeutet, steht das im jeweiligen Eintrag |
| `PlaybackState`, `MeditationSettingsKeys` | Implementierungsdetails; `PlaybackState` ist zudem auf beiden Plattformen unterschiedlich modelliert |

Im Zweifel gilt: Würde ein Mönch den Begriff verstehen? Dann gehört er hierher.

### Plattform-Vermerke

Das Glossar beschreibt, **was ist** — keine Roadmap. Ein Begriff, den es nur auf einer
Plattform gibt, bekommt „nur iOS" bzw. „noch nicht vorhanden" plus Dateireferenz. Kein
„geplant", kein Verweis auf ein Ticket für etwas Zukünftiges: Solche Vermerke stimmten beim
Schreiben und waren drei Monate später an vier Stellen falsch.

Einzige Ausnahme: Ein Bereich, der **gerade gebaut** wird, darf mit einem sichtbaren Hinweis
am Kopf stehen, damit von Anfang an dieselbe Sprache benutzt wird. Der Hinweis verschwindet,
sobald das Feature fertig ist.

### Detailtiefe

Bei Einstellungsobjekten nur festhalten, was **fachlich erklärungsbedürftig** ist:
Invarianten, gültige Bereiche, nicht-offensichtliche Bedeutung. Keine Abschrift der
Felderliste — die veraltet als Erstes und steht ohnehin im Code.

Bei Zustandsautomaten und Enums dagegen die vollständige Aufzählung behalten: Dort **ist** die
Liste der Werte die fachliche Aussage.

### Neuen Begriff hinzufügen

1. Prüfen, ob er dem Kriterium oben genügt
2. Quick Reference ergänzen — alphabetisch einsortieren
3. Detail-Eintrag in der passenden Sektion anlegen
4. Dateireferenzen für beide Plattformen angeben (oder vermerken, dass es ihn nur auf einer gibt)
5. Querverweise prüfen — „Siehe auch", Muster-Verweise
6. Heißen die Plattformen unterschiedlich? Dann in die Tabelle der
   Cross-Platform-Namensabweichungen eintragen und den kanonischen Namen festlegen
7. „Last Updated" im Kopf anpassen

### Zuordnung zur Domäne

Aus User-Perspektive zuordnen:

- **Bibliothek**: die persönliche Sammlung, ihr Import, ihre kuratierten Quellen, ihre Suche,
  ihre Wiedergabe und ihr Zuschnitt
- **Timer**: die stille Meditation samt Beiwerk (Hintergrundklang, Gongs)
- **App-weit**: was beide betrifft (Tabs, Darstellung, Farben)

### Review-Checkliste

Bei Code Reviews prüfen:

- [ ] Neue Begriffe im Glossar — sofern sie dem Kriterium genügen?
- [ ] Heißen sie auf beiden Plattformen gleich? Wenn nein: kanonischer Name festgelegt?
- [ ] Namenskonventionen für Aktionen und Effekte eingehalten?
- [ ] Keine „geplant"-Vermerke eingeschleust?

---

**Muster-Dokumentation:** `../architecture/ddd.md`
