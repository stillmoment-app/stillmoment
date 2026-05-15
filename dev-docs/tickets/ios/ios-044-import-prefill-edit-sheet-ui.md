# Ticket ios-044: Edit-Sheet Prefill-UI

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Komplexitaet**: Mehrere zusammenhaengende UI-Bausteine (X-Clear-Button, erweiterter Lehrer-Autocomplete mit Counts, Pflichtfeld-Validation, Modus-Trennung Import vs. Edit). Reine Presentation-Layer-Arbeit auf Basis des Domain-Services aus ios-043.
**Abhaengigkeiten**: ios-043 (Prefill-Service); ios-042 (kein Typ-Auswahl-Sheet mehr im Flow)
**Phase**: 3-Feature

---

## Was

Der `GuidedMeditationEditSheet` wird in zwei Modi betrieben:

- **Import-Modus** — nach erfolgreichem Datei-Import (Share-Sheet, „Oeffnen mit", Inbox-Download). Die Datei ist **noch nicht persistiert**. Felder sind mit den Vorschlaegen aus ios-043 vorbelegt. Der Prefill wird **still** dargestellt — kein Banner, kein Badge, keine Source-Markierung. Wenn der Vorschlag stimmt, weiter zum Save; wenn nicht, X-Button im Feld druecken und neu eingeben. **Save** persistiert die Meditation (ruft `addMeditation(url, metadata, teacher, name)` auf), **Cancel** verwirft die Datei ohne sie zu speichern.
- **Edit-Modus** — wenn der User aus dem Overflow-Menue einer bestehenden Meditation „Bearbeiten" antippt. Klassisches Editieren ohne Prefill-Spezifika. **Save** ruft `updateMeditation(...)` auf, **Cancel** laesst die Meditation unveraendert.

Beide Modi nutzen die **gleiche** SwiftUI-View. Die View bleibt bewusst dumm: sie kennt nur zwei `String`-Bindings (Teacher, Name), die `availableTeachers`-Liste, einen `mode`-Wert (steuert Autofocus und ggf. die File-Info-Section) und zwei Closures (`onSave`, `onCancel`). Persistenz-Logik, `hasChanges`-Vergleich und der Aufruf der korrekten Service-Methode liegen **ausserhalb** der View im ViewModel/Caller.

**Domain-State sauber trennen.** Das bestehende `EditSheetState` ist Edit-spezifisch — `originalMeditation: GuidedMeditation` ist required, `hasChanges` und `applyChanges() -> GuidedMeditation` setzen eine zu mutierende Meditation voraus. Im Import-Modus gibt es keine bestehende Meditation, gegen die man vergleichen koennte. Empfohlene Form: **zwei getrennte Domain-Typen** — `EditSheetState` bleibt unveraendert; neu hinzu kommt ein leichter `ImportDraft { teacher: String; name: String; isValid: Bool }`. Alternative: ein Enum mit zwei Cases — nur waehlen, wenn die View-Verdrahtung dadurch nachweislich einfacher wird. Default ist die zwei-Typen-Variante (klarere DDD-Grenze, weniger Switch-Logik im ViewModel).

Save-Verhalten und Initial-Felder bleiben pro Modus klar getrennt:
- Save: `addMeditation(url, metadata, teacher, name)` vs. `updateMeditation(...)` (vom Caller entschieden, nicht von der View).
- Initial-Felder: `prefill.teacher ?? ""` / `prefill.name ?? ""` vs. `meditation.effectiveTeacher` / `meditation.effectiveName`.

### Universell (beide Modi)

- **X-Clear-Button** im Textfeld, erscheint sobald das Feld einen Wert enthaelt, leert das Feld in einem Tap.
- **Lehrer wird Pflichtfeld** — Save-Button disabled wenn Lehrer:in oder Name leer.
- **Lehrer-Autocomplete erweitert** — pro Eintrag „X Meditationen", Match-Substring akzent-hervorgehoben, Footer-Eintrag „neue Lehrer:in anlegen" falls Query keinem bekannten Namen exakt entspricht.
- **Placeholder-Texte** als Hilfe bei leeren Feldern: Lehrer „Wer leitet die Meditation an?", Name „Wie heisst diese Meditation?". Lokalisiert DE + EN.

### Nur Import-Modus

- **Autofocus** auf das Name-Feld, **wenn der Name-Vorschlag leer ist** (`prefill.name == nil`). Sonst kein Autofocus — der User soll erst sehen, was vorgeschlagen wurde, und kann jederzeit antippen, wenn er korrigieren will.

## Warum

Die Prefill-Kaskade aus ios-043 liefert bessere Defaults. Der Handoff verzichtet bewusst auf visuelle Indikatoren („Prefill-Indikatoren — keine Banner, keine Badges. Die Tatsache dass ein Wert vorausgefuellt wurde wird nicht visuell hervorgehoben"): wenn der Wert stimmt, weiter; wenn nicht, X-Button und neu tippen. Das passt zur App-Philosophie „Ruhe statt Information" — die Maske gibt der User:in einen ausgefuellten Startpunkt, ohne sich selbst zu erklaeren.

Der X-Button macht das Verwerfen eines schlechten Vorschlags zu einer einzigen Geste — wichtiger als ein dekoratives Badge, das nur sagt „dieser Wert ist abgeleitet".

Lehrer-Pflichtfeld haelt die neu importierte Library konsistent — wer beim Anchor-Worst-Case eine UUID-Datei reinwirft, wird zum Ausfuellen gezwungen statt mit Lehrer-Default `"Unknown Artist"` weiterzulaufen. Im Edit-Modus gilt die gleiche Pflicht: User darf Werte editieren, aber nicht leer speichern.

Das gleiche Sheet fuer beide Modi vermeidet Code-Duplikation. Die Form-Struktur, Autocomplete-Verdrahtung, X-Clear-Logik, Pflichtfeld-Validierung, Placeholder und Toolbar sind in beiden Modi identisch — zwei separate Sheets wuerden den gesamten Block duplizieren. Die einzigen modus-spezifischen Unterschiede leben **ausserhalb** der View: Save-Closure (welche Service-Methode), Initial-Werte, Autofocus-Regel.

## Referenz

- Design-Handoff: `handoffs/design_handoff_edit_meta_prefill/` (insbesondere `README.md` Abschnitte „Prefill-Indikatoren", „Clear-Button (×)", „FieldCard", „Lehrer-Autocomplete-Dropdown", „Tastatur-Verhalten" und die Mocks in `screens.html`).
- Begleit-Ticket fuer die Domain-Logik: [ios-043 — Prefill-Service](ios-043-import-prefill-service.md)
- iOS-Code-Bereich:
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` (eine Aufrufstelle in `GuidedMeditationsListView.swift:117`)
  - `ios/StillMoment/Domain/Models/EditSheetState.swift`
  - `ios/StillMoment/Presentation/Views/Shared/AutocompleteTextField.swift` (Erweiterung um Counts-Anzeige und „neue Lehrer:in anlegen"-Footer)

---

## Akzeptanzkriterien

### Universell (beide Modi)

- [ ] **X-Clear-Button** in jedem Textfeld: erscheint sobald das Feld einen Wert enthaelt, leert das Feld bei Tap, verbirgt sich bei leerem Feld. Accessibility-Label „Feld leeren". Style gemaess Handoff (20×20 px Kreis, gedimmtes Hellgrau, dunkles X).
- [ ] **Lehrer-Autocomplete** zeigt pro Eintrag „X Meditationen" (Singular `1 Meditation` / Plural `N Meditationen`, lokalisiert).
- [ ] Match-Substring im Autocomplete ist akzent-hervorgehoben (Stil konsistent mit ios-041 Library-Search-Highlight).
- [ ] Wenn die aktuelle Lehrer-Eingabe **keinem** bekannten Eintrag exakt entspricht (case-insensitive, trimmed) und nicht leer ist: am Ende der Liste ein Footer-Eintrag „`„{query}" als neue Lehrer:in anlegen`". Tap uebernimmt den Wert ins Feld und schliesst das Dropdown.
- [ ] Klick auf X im Lehrer-Feld leert das Feld UND oeffnet den Autocomplete-Dropdown mit der vollen Lehrer-Liste (gemaess Handoff „Clear-Button — Klick-Verhalten").
- [ ] **Save-Button** disabled (gedimmt, nicht tappbar) wenn `teacher.trim().isEmpty || name.trim().isEmpty`.
- [ ] Return-Taste im Lehrer-Feld setzt Fokus auf Name-Feld; Return-Taste im Name-Feld triggert Save (falls valid).
- [ ] **Placeholder**: Lehrer-Feld „Wer leitet die Meditation an?", Name-Feld „Wie heisst diese Meditation?". Lokalisiert DE + EN.
- [ ] Der String `"Unknown Artist"` erscheint nirgendwo neu im UI — weder als Default-Wert, Suggestion noch Placeholder. (Bestehende Library-Eintraege koennen den Wert weiterhin tragen — keine Migration.)
- [ ] Keine Banner, keine Source-Badges, keine sonstigen visuellen Prefill-Indikatoren.

### Nur Import-Modus

- [ ] Beim Import erscheint das Edit-Sheet mit `prefill.teacher` / `prefill.name` als Default in den Feldern; nil-Werte ergeben leere Felder.
- [ ] **Autofocus**: wenn `prefill.name == nil` → Name-Feld autofocus (Tastatur sofort). Sonst → kein Autofocus.
- [ ] **Save** ruft `meditationService.addMeditation(url, metadata, teacher, name)` auf — erst dann wird die Datei in den App-Container kopiert und der Library-Eintrag angelegt.
- [ ] **Cancel** persistiert nichts: keine Datei-Kopie, kein Library-Eintrag, kein Bookmark. Die Quelle (URL aus Share-Sheet / Inbox) wird sauber freigegeben.
- [ ] Auch ein Modal-Swipe-Down (interactive dismiss) verhaelt sich wie Cancel.

### Nur Edit-Modus

- [ ] Sheet zeigt die persistierten Werte unveraendert — auch wenn `teacher` z. B. `"Unknown Artist"` enthaelt (Alt-Library, nicht migriert). Der Wert bleibt erhalten, falls der User ihn nicht aendert.
- [ ] Kein Autofocus.
- [ ] **Save** ruft `meditationService.updateMeditation(...)` auf.
- [ ] **Cancel** laesst die Meditation unveraendert.
- [ ] X-Button, Pflichtfeld-Validation und Autocomplete-Erweiterungen funktionieren identisch zum Import-Modus.

### Tests

- [ ] Unit-Test `EditSheetState` (Edit-Pfad): `isValid` ist false wenn `teacher` ODER `name` leer; true sonst; `hasChanges`/`applyChanges` unveraendert in der Semantik.
- [ ] Unit-Test `ImportDraft` (Import-Pfad, falls als separater Typ implementiert): `isValid` ist false wenn `teacher` ODER `name` leer; true sonst.
- [ ] Unit-Test X-Clear-Button: Tap leert Feld, disabled Save. Bei Lehrer-Feld: oeffnet Autocomplete.
- [ ] Unit-Test Autocomplete-Counts: Singular/Plural lokalisiert, Aggregation aus `loadMeditations()` korrekt.
- [ ] Unit-Test Autocomplete-Footer: bei exaktem Match nicht angezeigt, sonst angezeigt; bei leerer Query nicht angezeigt.
- [ ] Unit-Test Autofocus-Regel (Import-Modus): `prefill.name == nil` → Autofocus Name; `prefill.name != nil` → kein Autofocus.
- [ ] Unit-Test Edit-Modus: Sheet mit `prefill == nil` rendert keinen Autofocus; persistierte Werte (auch `"Unknown Artist"`) bleiben unveraendert sichtbar.
- [ ] Snapshot-Test: Sheet im ID3-Bestfall (beide Felder vorbelegt) vs. Garbage-Fall (beide leer mit Placeholder).

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Verbesserung des Import-Flows: bessere Vorschlaege, schnelles Korrigieren via X-Button).

---

## Manueller Test

### Import-Modus

1. **ID3-Bestfall**: gut getaggte MP3 importieren (TPE1 + TIT2 gesetzt). Erwartung: beide Felder mit Tag-Wert, kein Autofocus, Save enabled.
2. **Lehrer im Dateinamen erkannt**: vorher mindestens eine Meditation mit Teacher „Tara Brach" anlegen. Datei `bodyscan-tara_brach.mp3` importieren. Erwartung: Lehrer = „Tara Brach", Name = „bodyscan", kein Autofocus (Name ist gefuellt), Save enabled.
3. **Filename-only**: `meditation-im-sitzen.mp3` importieren. Erwartung: Lehrer leer (Placeholder „Wer leitet die Meditation an?"), Name = „meditation im sitzen", kein Autofocus (Name ist gefuellt), Save disabled (Lehrer leer).
4. **Garbage-File**: `d067c0ea-2c04-b934-1e04-94b2dc2f13dd.mp3` importieren. Erwartung: beide Felder leer mit Placeholder, **Name autofocus** (Name ist leer), Save disabled.
5. **X-Button**: in einem gefuellten Feld auf das X tippen. Erwartung: Feld leer, Placeholder sichtbar, Save disabled. Bei Lehrer-Feld zusaetzlich: Autocomplete-Dropdown oeffnet sich.

### Edit-Modus

6. Eine bestehende Meditation in der Library antippen, Overflow-Menue → „Bearbeiten". Erwartung: Sheet oeffnet sich mit den gespeicherten Werten, kein Autofocus, Save enabled.
7. Bei Alt-Eintrag mit `teacher = "Unknown Artist"`: Wert ist im Feld sichtbar. User aendert nichts, tippt Save. Erwartung: Wert wird unveraendert gespeichert (keine Migration).
8. Beim Edit X-Button im Lehrer-Feld tippen → Feld leer → Save disabled. User tippt „Joseph Goldstein" → Save enabled.

### Universell

9. **Autocomplete-Counts**: mehrere Meditationen mit „Tara Brach" und eine mit „Jon Kabat-Zinn" anlegen. Im Edit-Sheet (Import oder Edit) im Lehrer-Feld „T" tippen. Erwartung: Eintrag „Tara Brach" mit „N Meditationen", Match-Substring akzent-hervorgehoben.
10. **Neue Lehrer:in anlegen**: „Joseph G" tippen wenn nur „Joseph Goldstein" und „Jon Kabat-Zinn" bekannt sind und keiner exakt matched. Erwartung: am Ende der Liste „„Joseph G" als neue Lehrer:in anlegen". Tap uebernimmt und schliesst.

---

## Out of Scope

- **Audio-Preview** im Edit-Sheet: bewusst nicht enthalten (siehe Design-Handoff Abschnitt „Out of Scope" — geplant als separates Library-Long-Press-Feature).
- **Cover/Glyph-Auswahl** und **Tags**: nicht spezifiziert, eigener spaeterer Designdurchlauf.
- **Migration bestehender Library-Eintraege** mit `"Unknown Artist"`: siehe ios-043 — Edit-Modus zeigt den persistierten Wert unveraendert.
- **Source-Badges und Prefill-Banner**: bewusst weggelassen (siehe Handoff „Prefill ist still"). Wenn spaeter doch gewuenscht, kann ios-043 additiv eine Source-Markierung liefern.
- **Avatar / Person-Icon im Autocomplete-Dropdown**: der Handoff zeigt einen 28 px Avatar-Kreis links neben jedem Eintrag. Bewusst weggelassen — App-Philosophie „weniger ist mehr"; ein rein dekoratives Element ohne Informationsgehalt zieht visuell in Richtung Kontaktliste. Wenn spaeter echte Lehrer-Bilder hinzukommen, eigenes Feature.
- **Lehrer-Detail-Anzeige** (z. B. „zuletzt gehoert vor 3 Wochen"): bewusst weggelassen, weil `lastPlayedAt` heute nicht persistiert wird.
- **Edit-Modus mit nachtraeglichem Prefill** (z. B. „Auto-Vervollstaendigung bei leerem Lehrer-Feld in Alt-Eintraegen"): kein Auto-Fixing — der User editiert manuell.

---

## Hinweise

- `AutocompleteTextField` (bzw. das aktuelle Pendant) muss um die Count-Anzeige und den Footer-Eintrag erweitert werden. Statt `[String]` wird ein Wert-Typ mit `(name: String, count: Int)` uebergeben. Aggregation macht der Caller (ViewModel) — Counts pro `effectiveTeacher` aufsummieren, Lehrer mit `sanitize(_:) == nil` ausschliessen (Konsistenz mit ios-043).
- Domain-State: `EditSheetState` bleibt fuer den Edit-Pfad unveraendert (mit `originalMeditation`, `hasChanges`, `applyChanges`). Fuer den Import-Pfad neuen, schmalen Typ `ImportDraft` einfuehren (siehe Abschnitt „Was"). Die View bekommt nur Bindings + `mode` + Closures und kennt keinen der beiden Domain-Typen direkt. Modus-spezifische Service-Aufrufe (`addMeditation` vs. `updateMeditation`) macht das ViewModel im jeweiligen Save-Callback.
- ViewModel (`GuidedMeditationsListViewModel`) bekommt einen zusaetzlichen Pfad: nach Datei-Auswahl wird `ImportPrefill.compute(...)` aufgerufen, das Edit-Sheet im Import-Modus geoeffnet, und erst bei Save wird `addMeditation(...)` aufgerufen. Der heutige Pfad „sofort persistieren, dann Edit-Sheet" entfaellt.
- Lokalisierung: alle neuen Strings DE + EN. Placeholder-Texte und Autocomplete-Counts in beiden Sprachen testen.
- Accessibility: X-Button bekommt klares `accessibilityLabel("Feld leeren")`. Pflichtfeld-State wird ueber den disabled Save-Button signalisiert, plus `accessibilityHint` an leeren Feldern („Erforderlich").
