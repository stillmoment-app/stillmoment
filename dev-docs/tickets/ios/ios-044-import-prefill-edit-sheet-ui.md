# Ticket ios-044: Edit-Sheet Prefill-UI

**Status**: [x] DONE
**Plan**: [Implementierungsplan](../plans/ios-044.md)
**Prioritaet**: HOCH
**Komplexitaet**: Schlanke UI-Erweiterung (X-Clear-Button, Match-Highlight im bestehenden Autocomplete, Pflichtfeld-Validation, Modus-Trennung Import vs. Edit) plus einmaliger Domain-Cleanup: der ungenutzte `customTeacher`/`customName`-Override-Mechanismus wird entfernt. Der Cleanup vereinfacht die Save-Logik fuer beide Modi und beseitigt eine semantische Schiefe im Import-Pfad (ios-043 hat den Override als Transport missbraucht, was zu einem Bug fuehrte). Migration ist trivial: einmaliger Sweep beim Load.
**Abhaengigkeiten**: ios-043 (Prefill-Service); ios-042 (kein Typ-Auswahl-Sheet mehr im Flow)
**Phase**: 3-Feature

---

## Was

Der `GuidedMeditationEditSheet` wird in zwei Modi betrieben:

- **Import-Modus** — nach erfolgreichem Datei-Import (Share-Sheet, „Oeffnen mit", Inbox-Download). Die Datei ist **noch nicht persistiert**. Felder sind mit den Vorschlaegen aus ios-043 vorbelegt. Der Prefill wird **still** dargestellt — kein Banner, kein Badge, keine Source-Markierung. Wenn der Vorschlag stimmt, weiter zum Save; wenn nicht, X-Button im Feld druecken und neu eingeben. **Save** persistiert die Meditation (ruft `addMeditation(url, metadata, teacher, name)` auf), **Cancel** verwirft die Datei ohne sie zu speichern.
- **Edit-Modus** — wenn der User aus dem Overflow-Menue einer bestehenden Meditation „Bearbeiten" antippt. Klassisches Editieren ohne Prefill-Spezifika. **Save** ruft `updateMeditation(...)` auf, **Cancel** laesst die Meditation unveraendert.

Beide Modi nutzen die **gleiche** SwiftUI-View. Die View nimmt die zu editierende `GuidedMeditation` (im Import-Modus ein Draft mit Prefill-Werten), die `availableTeachers`-Liste, einen `mode`-Wert (steuert Autofocus, Sheet-Titel und Save-Button-Text), und zwei Closures (`onSave: (GuidedMeditation) -> Void`, `onCancel`). Persistenz-Logik und die Auswahl der korrekten Service-Methode (`addMeditation` vs. `updateMeditation`) liegen **ausserhalb** der View im ViewModel/Caller.

**Domain-Cleanup (Voraussetzung).** Das `GuidedMeditation`-Modell hat heute pro Feld eine Override-Schicht: `teacher` (originaler Wert) + `customTeacher: String?` (User-Override) + `effectiveTeacher` (computed property `customTeacher ?? teacher`). Analog `name`/`customName`. Diese Trennung wird **nirgendwo** genutzt — es gibt kein „Reset to ID3"-Feature, keine UI die den Original-Wert separat anzeigt, und im Import-Pfad fuehrt der Override-Mechanismus zu einem Bug (ios-043 hat ihn als Transport benutzt, was beim Save den Prefill-Wert statt des User-Werts an `addMeditation` durchreichte). Im Rahmen von ios-044 werden `customTeacher` und `customName` entfernt; `teacher` und `name` sind die einzige Wahrheit pro Feld. Edit ueberschreibt direkt, Import setzt initial. Damit faellt die ganze Modus-Asymmetrie weg.

**Domain-State der View.** `EditSheetState` bleibt als interner Form-State der View (heutiges Pattern), wird aber simpler: nur noch `editedTeacher`/`editedName` als mutable Strings + `originalMeditation` als Initial-Werte-Quelle + `isValid` + `applyChanges()` ohne Override-Logik (setzt `teacher`/`name` direkt). Im Import-Modus wird ein Draft-`GuidedMeditation` als initial state benutzt — die Save-Closure liefert die finale `GuidedMeditation` mit direkt gesetzten `teacher`/`name`-Strings, der Caller verzweigt auf `addMeditation` vs. `updateMeditation`.

Save-Verhalten und Initial-Felder bleiben pro Modus klar getrennt:
- Save: `addMeditation(url, metadata, teacher, name)` vs. `updateMeditation(...)` (vom Caller entschieden, nicht von der View).
- Initial-Felder: `prefill.teacher ?? ""` / `prefill.name ?? ""` vs. `meditation.teacher` / `meditation.name`.

### Universell (beide Modi)

- **X-Clear-Button** im Textfeld, erscheint sobald das Feld fokussiert ist UND einen Wert enthaelt (iOS-Standard `.whileEditing`), leert das Feld in einem Tap.
- **Lehrer wird Pflichtfeld** — Save-Button disabled wenn Lehrer:in oder Name leer.
- **Lehrer-Autocomplete-Highlight** — Match-Substring im Dropdown akzent-hervorgehoben (Stil konsistent mit ios-041 Library-Search-Highlight). Counts/Footer/Avatar bewusst nicht — App-Philosophie „weniger ist mehr".
- **Placeholder-Texte** als Hilfe bei leeren Feldern: Lehrer „Wer leitet die Meditation an?", Name „Wie heisst diese Meditation?". Lokalisiert DE + EN.

### Nur Import-Modus

- **Autofocus** auf das Name-Feld, **wenn der Name-Vorschlag leer ist** (`prefill.name == nil`). Sonst kein Autofocus — der User soll erst sehen, was vorgeschlagen wurde, und kann jederzeit antippen, wenn er korrigieren will.

## Warum

Die Prefill-Kaskade aus ios-043 liefert bessere Defaults. Der Handoff verzichtet bewusst auf visuelle Indikatoren („Prefill-Indikatoren — keine Banner, keine Badges. Die Tatsache dass ein Wert vorausgefuellt wurde wird nicht visuell hervorgehoben"): wenn der Wert stimmt, weiter; wenn nicht, X-Button und neu tippen.

Der X-Button macht das Verwerfen eines schlechten Vorschlags zu einer einzigen Geste — wichtiger als ein dekoratives Badge, das nur sagt „dieser Wert ist abgeleitet".

Lehrer-Pflichtfeld haelt die neu importierte Library konsistent — wer beim Anchor-Worst-Case eine UUID-Datei reinwirft, wird zum Ausfuellen gezwungen statt mit leerem Lehrer-Feld weiterzulaufen. Im Edit-Modus gilt die gleiche Pflicht: User darf Werte editieren, aber nicht leer speichern.

Match-Highlight im Autocomplete: kostet wenig (`AttributedString`-Variante des Eintrags) und nimmt das bestehende ios-041-Pattern wieder auf — Konsistenz zwischen Library-Suche und Lehrer-Autocomplete. Counts („X Meditationen") und „Neue Lehrer:in anlegen"-Footer sind bewusst weggelassen: bei <20 Lehrern ist der Count Information ohne Entscheidungswert, und der Footer bestaetigt nur was Save ohnehin tut.

Das gleiche Sheet fuer beide Modi vermeidet Code-Duplikation. Die Form-Struktur, Autocomplete-Verdrahtung, X-Clear-Logik, Pflichtfeld-Validierung, Placeholder und Toolbar sind in beiden Modi identisch — zwei separate Sheets wuerden den gesamten Block duplizieren. Die einzigen modus-spezifischen Unterschiede leben **ausserhalb** der View: Save-Closure (welche Service-Methode), Initial-Werte, Autofocus-Regel.

## Referenz

- Design-Handoff: `handoffs/design_handoff_edit_meta_prefill/` (insbesondere `README.md` Abschnitte „Prefill-Indikatoren", „Clear-Button (×)", „FieldCard", „Lehrer-Autocomplete-Dropdown", „Tastatur-Verhalten" und die Mocks in `screens.html`).
- Begleit-Ticket fuer die Domain-Logik: [ios-043 — Prefill-Service](ios-043-import-prefill-service.md)
- iOS-Code-Bereich:
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` (eine Aufrufstelle in `GuidedMeditationsListView.swift:117`)
  - `ios/StillMoment/Domain/Models/EditSheetState.swift`
  - `ios/StillMoment/Presentation/Views/Shared/AutocompleteTextField.swift` (Erweiterung um Match-Highlight)

---

## Akzeptanzkriterien

### Vorbereitung: Override-Mechanismus entfernen

- [x] `customTeacher: String?` und `customName: String?` werden aus `GuidedMeditation` entfernt.
- [x] Die computed properties `effectiveTeacher` und `effectiveName` entfallen — alle Aufrufstellen lesen direkt `teacher` bzw. `name`. (Aufrufer u. a.: `LibrarySearchEngine`, `GuidedMeditationsListViewModel.uniqueTeachers`, `meditationsByTeacher`, `ImportPrefill`, View-Anzeige, Player-Title.)
- [x] **Migration beim Load**: bestehende persistierte Eintraege mit `customTeacher != nil` → `teacher = customTeacher`, danach `customTeacher` aus dem persistierten Format entfernen. Analog `customName`. Migration ist idempotent (zweiter Lauf macht nichts). Kein Datenverlust: `customTeacher` war ohnehin der aktuell sichtbare Wert. Implementierung: Custom `init(from:)` faltet die alten Felder beim Decoden in `teacher`/`name`, ein einmaliges Flag `guidedMeditationsOverrideMigratedV1` triggert einen Re-Save, damit die alten Keys auch physisch aus UserDefaults verschwinden.
- [x] **Save-Button-Text im Import-Modus**: Localization-Key `guided_meditations.import.action` (DE „Importieren", EN „Import"). Edit-Modus nutzt weiter `common.save`.

> Der ursprünglich vorgesehene Sheet-Titel ist nach UX-Review entfallen — siehe „Toolbar-Vereinfachung" unten.

### Universell (beide Modi)

- [x] **X-Clear-Button** in jedem Textfeld: erscheint sobald das Feld fokussiert ist UND einen Wert enthaelt (iOS-Standard `.whileEditing`), leert das Feld bei Tap, verbirgt sich bei leerem Feld oder Focus-Verlust. Accessibility-Label „Feld leeren". Style 20×20 px Kreis, gedimmtes Hellgrau, dunkles X.
- [x] **Match-Substring im Autocomplete** ist akzent-hervorgehoben. Style nach UX-Review: Akzentfarbe + Font-Weight `semibold` (statt zusätzlichem Background-Tint — der Tint verschwamm auf warmem Card-Background). Konsistent angewendet auch in der Library-Suche aus ios-041.
- [x] Klick auf X im Lehrer-Feld leert das Feld. Der Autocomplete-Dropdown bleibt geschlossen — konsistent mit der Library-Suche aus ios-041 (leeres Feld = keine Vorschlaege).
- [x] **Save-Button** disabled (gedimmt, nicht tappbar) wenn `teacher.trim().isEmpty || name.trim().isEmpty`. Tint = `theme.interactive`, damit er bei valider Eingabe als Primaer-Action sichtbar bleibt.
- [x] Return-Taste im Lehrer-Feld setzt Fokus auf Name-Feld; Return-Taste im Name-Feld triggert Save (falls valid). `submitLabel(.next)` bzw. `.done`.
- [x] **Placeholder**: Lehrer-Feld „Wer leitet die Meditation an?", Name-Feld „Wie heisst diese Meditation?". Lokalisiert DE + EN.
- [x] Der String `"Unknown Artist"` erscheint nirgendwo neu im UI — weder als Default-Wert, Suggestion noch Placeholder. Bestehende Library-Eintraege mit `teacher = "Unknown Artist"` werden NICHT migriert — die Migration betrifft nur den Override-Mechanismus, nicht inhaltliche Werte.
- [x] Keine Banner, keine Source-Badges, keine sonstigen visuellen Prefill-Indikatoren.
- [x] **Name-Feld waechst vertikal mit `axis: .vertical, lineLimit: 1...3`** — lange Titel wie „MSC Liebende Guete fuer ein geliebtes Wesen" werden nicht mehr in der Mitte abgeschnitten, sondern brechen umgebrochen. Wichtig, weil das Name-Feld das primaere Korrektur-Feld ist.
- [x] **Datei-Info als kompakter, zweizeiliger Footer** unter der Name-Card: `[Doc-Icon] {filename} · {duration}`. `lineLimit(2)` mit `.byTruncatingTail` als Fallback. Sichtbar in **beiden** Modi (Reality-Check beim Import, gewohnter Look beim Edit).
- [x] **Toolbar-Vereinfachung**: kein Sheet-Titel (`principal` ToolbarItem entfaellt). Cancel als minimaler X-Icon-Button (`xmark`, 15pt, `textSecondary`), Save-Action behaelt prominentes Pill-Label mit `theme.interactive` als Tint. Begruendung: in iOS 26 (Liquid Glass) rendern Pill-Buttons schwerer; ein langer Titel + zwei Pill-Buttons fuehrte zu Truncation („Meditation..."). Die asymmetrische Toolbar reflektiert die Hierarchie (sekundaer / primaer).
- [x] **Autocomplete-Dropdown im Plain-Look**: keine eigene Card mit Shadow mehr. Subtile Trennlinie ueber dem ersten Vorschlag (zum Input), duenne Trennlinien zwischen Vorschlaegen, transparenter Hintergrund. Vermeidet den Eindruck „alle Eintraege selektiert" auf warmem Card-Background.
- [x] **Kompaktes Section-Spacing** zwischen Lehrer- und Name-Card via `.listSectionSpacing(.compact)` (iOS 17+). iOS 16 nutzt Standard-Spacing — akzeptierter Trade-off, weil die Sections-Trennung wichtiger ist als der minimale Gap.

### Filename-Preprocessing (Erweiterung von ios-043)

- [x] `ImportPrefill.preprocessFilename` fuegt Spaces an Wort-Grenzen ein, die in Filesharing-Dateinamen oft an Stelle echter Trenner stehen:
  - **CamelCase**: `MomentMal` → `Moment Mal` (Klein → Gross)
  - **Akronym-Ende**: `MBSRBodyscan` → `MBSR Bodyscan` (mehrere Gross gefolgt von Klein)
  - **Zahl/Wort**: `04Fuesse` → `04 Fuesse` (Zahl direkt vor Buchstabe oder umgekehrt)
- [x] Konkretes User-Beispiel: `Moment-mal-04Fuesse.mp3` → Prefill-Vorschlag `Moment mal 04 Fuesse` statt `Moment mal 04Fuesse`.
- [x] Diakritika-Rueckabbildung (`ue`→`ü`, `oe`→`ö`, `ae`→`ä`, `ss`→`ß`) findet **bewusst nicht** statt — die Heuristik produziert zu viele false positives (z. B. `Quelle` → `Quölle`). Verbliebene Sonderzeichen korrigiert der User manuell.

### Nur Import-Modus

- [x] Beim Import erscheint das Edit-Sheet mit `prefill.teacher` / `prefill.name` als Default in den Feldern; nil-Werte ergeben leere Felder.
- [x] **Autofocus**: wenn `prefill.name == nil` → Name-Feld autofocus (Tastatur sofort). Sonst → kein Autofocus. Reine Modus-Logik (`shouldAutofocusName(prefilledName:)`) wird in `GuidedMeditationEditSheetModeTests` getestet.
- [x] **Save** ruft `meditationService.addMeditation(url, metadata, teacher, name)` auf — erst dann wird die Datei in den App-Container kopiert und der Library-Eintrag angelegt.
- [x] **Cancel** persistiert nichts: keine Datei-Kopie, kein Library-Eintrag, kein Bookmark. Die Quelle (URL aus Share-Sheet / Inbox) wird sauber freigegeben.
- [x] Auch ein Modal-Swipe-Down (interactive dismiss) verhaelt sich wie Cancel. Implementierung: `.sheet(onDismiss:)`-Closure ruft `cancelImport()` falls `pendingImport != nil`.

### Nur Edit-Modus

- [x] Sheet zeigt die persistierten Werte unveraendert — auch wenn `teacher` z. B. `"Unknown Artist"` enthaelt (Alt-Library, nicht migriert). Der Wert bleibt erhalten, falls der User ihn nicht aendert.
- [x] Kein Autofocus.
- [x] **Save** ruft `meditationService.updateMeditation(...)` auf.
- [x] **Cancel** laesst die Meditation unveraendert.
- [x] X-Button, Pflichtfeld-Validation und Match-Highlight funktionieren identisch zum Import-Modus.

### Tests

- [x] Unit-Test Migration: Eintrag mit `customTeacher = "X"` und `teacher = "Y"` wird beim Load zu `teacher = "X"`, `customTeacher` entfernt. Eintrag ohne `customTeacher` bleibt unveraendert. Zweiter Lauf macht nichts. (`GuidedMeditationServiceTests+Migration`)
- [x] Unit-Test `EditSheetState`: `isValid` ist false wenn `editedTeacher` ODER `editedName` leer; true sonst. `applyChanges()` liefert eine `GuidedMeditation` mit `teacher = editedTeacher`, `name = editedName`. `hasChanges` semantisch unveraendert. (`EditSheetStateTests`)
- [x] Unit-Test Match-Highlight: `LibrarySearchEngine.highlightRanges(in:"Tara Brach", query:"T")` liefert die Range fuer das `T`. (Bestand aus ios-041.)
- [x] Unit-Test Autofocus-Regel (Import-Modus): `prefill.name == nil` → Autofocus Name; `prefill.name != nil` → kein Autofocus. (`GuidedMeditationEditSheetModeTests`)
- [x] Unit-Test Filename-Boundaries: `04Fuesse` → `04 Fuesse`, `MomentMal` → `Moment Mal`, `MBSRBodyscan` → `MBSR Bodyscan`. (`ImportPrefillTests`)
- [x] Snapshot-Tests UI: bewusst weggelassen — die UI-Polish-Iterationen waeren mit Snapshot-Tests teurer als der Mehrwert. Visuelle Pruefung lief ueber manuelle QA im Simulator.

### Dokumentation

- [x] CHANGELOG.md — user-sichtbare Verbesserungen des Import-Flows: X-Clear-Button, Pflichtfeld, Match-Highlight, vertikales Name-Feld, schickerer Autocomplete-Look, Filename-Parser mit CamelCase/Number-Split.

---

## Manueller Test

### Import-Modus

1. **ID3-Bestfall**: gut getaggte MP3 importieren (TPE1 + TIT2 gesetzt). Erwartung: beide Felder mit Tag-Wert, kein Autofocus, Save enabled.
2. **Lehrer im Dateinamen erkannt**: vorher mindestens eine Meditation mit Teacher „Tara Brach" anlegen. Datei `bodyscan-tara_brach.mp3` importieren. Erwartung: Lehrer = „Tara Brach", Name = „bodyscan", kein Autofocus (Name ist gefuellt), Save enabled.
3. **Filename-only**: `meditation-im-sitzen.mp3` importieren. Erwartung: Lehrer leer (Placeholder „Wer leitet die Meditation an?"), Name = „meditation im sitzen", kein Autofocus (Name ist gefuellt), Save disabled (Lehrer leer).
4. **Garbage-File**: `d067c0ea-2c04-b934-1e04-94b2dc2f13dd.mp3` importieren. Erwartung: beide Felder leer mit Placeholder, **Name autofocus** (Name ist leer), Save disabled.
5. **X-Button**: in einem gefuellten Feld auf das X tippen. Erwartung: Feld leer, Placeholder sichtbar, Save disabled. Beim Lehrer-Feld bleibt der Autocomplete-Dropdown geschlossen (analog Library-Suche: leeres Feld = keine Vorschlaege).

### Edit-Modus

6. Eine bestehende Meditation in der Library antippen, Overflow-Menue → „Bearbeiten". Erwartung: Sheet oeffnet sich mit den gespeicherten Werten, kein Autofocus, Save enabled.
7. Bei Alt-Eintrag mit `teacher = "Unknown Artist"`: Wert ist im Feld sichtbar. User aendert nichts, tippt Save. Erwartung: Wert wird unveraendert gespeichert (keine Migration).
8. Beim Edit X-Button im Lehrer-Feld tippen → Feld leer → Save disabled. User tippt „Joseph Goldstein" → Save enabled.

### Universell

9. **Match-Highlight**: mehrere Meditationen mit „Tara Brach" und eine mit „Jon Kabat-Zinn" anlegen. Im Edit-Sheet (Import oder Edit) im Lehrer-Feld „T" tippen. Erwartung: Eintrag „Tara Brach" sichtbar, „T" im Namen akzent-hervorgehoben.

---

## Out of Scope

- **Audio-Preview** im Edit-Sheet: bewusst nicht enthalten (siehe Design-Handoff Abschnitt „Out of Scope" — geplant als separates Library-Long-Press-Feature).
- **Cover/Glyph-Auswahl** und **Tags**: nicht spezifiziert, eigener spaeterer Designdurchlauf.
- **Migration bestehender Library-Eintraege** mit `"Unknown Artist"`: siehe ios-043 — Edit-Modus zeigt den persistierten Wert unveraendert.
- **Source-Badges und Prefill-Banner**: bewusst weggelassen (siehe Handoff „Prefill ist still").
- **Autocomplete-Counts** („X Meditationen" pro Eintrag): bewusst weggelassen — App-Philosophie „weniger ist mehr"; bei wenigen Lehrern Information ohne Entscheidungswert.
- **„Neue Lehrer:in anlegen"-Footer im Autocomplete**: bewusst weggelassen — bestaetigt nur, was Save ohnehin tut.
- **Avatar / Person-Icon im Autocomplete-Dropdown**: bewusst weggelassen (rein dekorativ, zieht visuell Richtung Kontaktliste).
- **Lehrer-Detail-Anzeige** (z. B. „zuletzt gehoert vor 3 Wochen"): `lastPlayedAt` wird heute nicht persistiert.
- **Edit-Modus mit nachtraeglichem Prefill** (z. B. „Auto-Vervollstaendigung bei leerem Lehrer-Feld in Alt-Eintraegen"): kein Auto-Fixing — der User editiert manuell.
- **Sheet-offen-bei-Save-Fehler / Retry-Flow**: Schlaegt der Save fehl (Disk voll, Quell-URL verloren, UserDefaults-Write-Fehler), wird der Fehler als Alert gezeigt und das Sheet schliesst sich. Der einzige realistisch durch Retry behebbare Fall ist „Speicher voll" — Frequenz zu niedrig, um einen Inline-Retry-Flow zu rechtfertigen. User sharet die Datei neu bzw. editiert erneut.

---

## Hinweise

- **Override-Cleanup zuerst**: Der Domain-Schritt (customTeacher/customName raus, Migration) kommt vor den UI-Aenderungen. Sonst arbeitet die View weiter gegen das alte Modell und der Bug aus ios-043 bleibt versteckt.
- `AutocompleteTextField` wird um Match-Highlight erweitert — der Substring der aktuellen Query im Eintrag wird akzent-eingefaerbt (`HighlightedText` aus ios-041 direkt wiederverwenden, ist im selben Module). Keine Aenderung der `[String]`-Datenstruktur.
- `AutocompleteTextField` bekommt zusaetzlich den X-Clear-Button. Fuer das Name-Feld entsteht eine neue Shared-Komponente `ClearableTextField` (TextField + X-Overlay nach `.whileEditing`-Regel). `AutocompleteTextField` nutzt `ClearableTextField` intern, damit der X-Button-Stil an einer Stelle gepflegt wird.
- Domain-State: `EditSheetState` bleibt interner Form-State der View, wird aber simpler — `applyChanges()` setzt `teacher`/`name` direkt (keine Override-Verzweigung mehr). `hasChanges`-Semantik bleibt (Vergleich gegen `originalMeditation.teacher`/`.name`).
- ViewModel (`GuidedMeditationsListViewModel`) bekommt einen zusaetzlichen Pfad: nach Datei-Auswahl wird `ImportPrefill.compute(...)` aufgerufen, das Edit-Sheet im Import-Modus geoeffnet, und erst bei Save wird `addMeditation(...)` aufgerufen. Der heutige Pfad „sofort persistieren, dann Edit-Sheet" entfaellt (war schon ios-043).
- Interactive Dismiss: `.sheet(isPresented:onDismiss:)` mit `onDismiss`-Closure faengt sowohl Cancel-Button-Tap als auch Modal-Swipe-Down. Im Import-Modus ruft die Closure `cancelImport()` falls `pendingImport != nil` (Security-Scope sauber freigeben, kein Library-Eintrag).
- Lokalisierung: alle neuen Strings DE + EN. Placeholder-Texte in beiden Sprachen testen.
- Accessibility: X-Button bekommt klares `accessibilityLabel("Feld leeren")`. Pflichtfeld-State wird ueber den disabled Save-Button signalisiert, plus `accessibilityHint` an leeren Feldern („Erforderlich").
