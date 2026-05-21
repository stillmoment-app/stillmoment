# Ticket shared-103: Share-Import-Verbesserungen (Android-Sync)

**Status**: [x] DONE
**Prioritaet**: HOCH
**Komplexitaet**: Mittel — buendelt drei zusammenhaengende iOS-Tickets (`ios-042`/`ios-043`/`ios-044`). Pipeline aus Sanitize-Funktion, Filename-Preprocessing und Garbage-Detection ist Domain-rein, aber die Persistenz-Reihenfolge im ViewModel muss umgebaut werden (Persist erst beim Save, nicht beim Import). Edit-Sheet bekommt zusaetzlich X-Clear-Button, Pflichtfeld-Validation und Match-Highlight im Autocomplete.
**Phase**: 3-Feature

---

## Was

Der Share-Import-Flow auf Android wird in drei verbundenen Schritten verbessert:

1. **Share-Import immer als Meditation.** Die Typ-Auswahl ("Meditation" vs. "Hintergrund-Sound") aus `shared-073` entfaellt im Share-Pfad. Geteilte Audiodateien werden direkt als Meditation in die Library uebernommen — Hintergrund-Sounds importiert man weiterhin im Settings-Pfad bei der Sound-Auswahl.
2. **Bessere Prefill-Vorschlaege fuer Lehrer und Titel.** Beim Import werden sinnvolle Werte fuer `teacher` und `name` automatisch vorgeschlagen — und unbrauchbare Werte (Encoder-Platzhalter `Unknown Artist`/`Untitled`, UUID-Dateinamen, Server-Defaults `audio.mp3`) als solche erkannt und ausgelassen, damit das Edit-Sheet nicht Muell als Default zeigt.
3. **Edit-Sheet-UI im Import-Modus.** X-Clear-Button in jedem Textfeld, Lehrer + Titel als Pflichtfelder, Match-Highlight im Lehrer-Autocomplete, vertikal wachsendes Titel-Feld, schlankere Toolbar (kein Sheet-Titel mehr, Cancel als X-Icon), Datei-Info als kompakter Footer.

## Warum

Der Import ist ein Kern-Feature der App. Heute landen User nach einem Share oft vor einer Maske mit Percent-Encoded-URL-Schrott als Titel und `Unknown Artist` als Teacher — erster Eindruck = Reibung statt Komfort. Anchor-Podcast-MP3s kommen z. B. ohne `TIT2`/`TPE1`-Tags, der Dateiname ist eine UUID. Eine getrennte Behandlung pro Feld (Teacher und Title separate Kaskaden) ist sauberer als gekoppelte Logik.

Der X-Button macht das Verwerfen eines schlechten Vorschlags zu einer einzigen Geste — wichtiger als ein dekoratives Badge. Lehrer-Pflichtfeld haelt die Library konsistent: wer eine UUID-Datei reinwirft, wird zum Ausfuellen gezwungen statt mit leerem Lehrer-Feld weiterzulaufen.

Die Typ-Auswahl im Share-Pfad ist ein zusaetzlicher Klick ohne Mehrwert — Hintergrund-Sounds werden inzwischen direkt im Settings-Pfad importiert.

---

## Plattform-Status

| Plattform | Status | Anmerkung |
|-----------|--------|-----------|
| iOS       | [x]    | Bereits umgesetzt via `ios-042` + `ios-043` + `ios-044` |
| Android   | [x]    | -                                                       |

---

## Akzeptanzkriterien

### Teil 1 — Share-Import immer als Meditation

- [ ] Eine via Share oder "Oeffnen mit" empfangene MP3/M4A erscheint ohne Zwischenfrage in der Library als Meditation
- [ ] Direkt nach dem Import oeffnet sich das Edit-Sheet fuer die importierte Meditation, der Library-Tab ist aktiv
- [ ] Eine doppelte Datei (gleicher Name + Groesse wie eine bereits importierte Meditation) wird mit der bestehenden "bereits importiert"-Meldung abgelehnt
- [ ] Eine nicht unterstuetzte Datei (kein MP3/M4A) zeigt den bestehenden Format-Fehler-Alert
- [ ] Geteilter Link → Download → Import funktioniert wie zuvor; liefert der Link keine Audio-Datei, erscheint weiterhin der "kein Audio gefunden"-Alert
- [ ] Die Auswahl-Halbblende ("Worum handelt es sich?" aus `shared-073`) ist im Share-Flow nicht mehr sichtbar — der Code-Pfad fuer Soundscape-Import via Settings bleibt erhalten

### Teil 2 — Prefill-Logik (Domain-rein, beide Felder separat)

**Sanitize-Funktion** filtert Platzhalter-Strings zentral fuer ID3-Werte, bekannte Lehrer und preprocessed Filename:

- [ ] `sanitize(null)` und `sanitize("   ")` → `null`
- [ ] Blacklist (case- und trenner-insensitiv): `unknown`, `unknownartist`, `untitled`, `audio`, `recording`, `voicememo`, `voicerecording`
- [ ] Pure Track-Nummerierung (`^(track)?\d{1,3}$`) → `null`
- [ ] `"Body Scan"` bleibt `"Body Scan"` (Whitespace getrimmt, Casing unveraendert)

**Filename-Preprocessing:**

- [ ] Endung entfernen (`.mp3`, `.m4a`)
- [ ] Track-Nummer-Praefix entfernen (`^\d{1,3}[-_.\s]+`)
- [ ] Trenner `_`, `-`, `.` zu Spaces normalisieren
- [ ] Wortgrenzen einfuegen: **CamelCase** (`MomentMal` → `Moment Mal`), **Akronym-Ende** (`MBSRBodyscan` → `MBSR Bodyscan`), **Zahl/Wort** (`04Fuesse` → `04 Fuesse`)
- [ ] Casing wird NICHT veraendert (kein erzwungenes Title-Case — gerade fuer Deutsch wichtig)
- [ ] Diakritika-Rueckabbildung (`ue`→`ü` etc.) findet bewusst **nicht** statt — zu viele false positives

**Garbage-Detection** (Filename gilt als unbrauchbar wenn):

- [ ] UUID-v4-Pattern
- [ ] Einzelnes Token ohne Trenner mit Laenge >= 24
- [ ] Leer nach Preprocessing

**Teacher-Kaskade:**

1. [ ] ID3-Artist via Sanitize → wenn nicht-null: dieser Wert
2. [ ] Match in `knownTeachers` gegen preprocessed Filename — Liste mit Sanitize vorgefiltert; nach Laenge absteigend sortiert; nur Namen mit >= 2 Worten ODER >= 6 Zeichen
3. [ ] Sonst: `null`

**Title-Kaskade:**

1. [ ] ID3-Title via Sanitize → wenn nicht-null: dieser Wert
2. [ ] Filename ohne Teacher: wenn Teacher als Substring im preprocessed Filename → entfernen, Sanitize anwenden, wenn nicht-null und >= 3 Zeichen: dieser Wert. Greift auch wenn Teacher aus ID3 kam und zufaellig im Filename steht
3. [ ] Filename komplett: wenn preprocessed Filename nicht Garbage und Sanitize nicht-null und >= 3 Zeichen: dieser Wert
4. [ ] Sonst: `null`

**Integration:**

- [ ] Beim Import wird **erst nach Save** im Edit-Sheet die Datei in den App-Container kopiert und der Library-Eintrag angelegt. Cancel im Import-Modus persistiert nichts (kein Library-Eintrag, keine Datei-Leiche)
- [ ] Prefill-Berechnung im ViewModel, nicht im Service — der Service kennt `ImportPrefill` nicht
- [ ] Bestehende Library-Eintraege werden nicht migriert — `Unknown Artist` bleibt als gespeicherter String erhalten, kann via Edit-Sheet manuell ueberschrieben werden

### Teil 3 — Edit-Sheet-UI (beide Modi: Import + Edit)

- [ ] **X-Clear-Button** in jedem Textfeld: erscheint sobald das Feld fokussiert ist UND einen Wert enthaelt, leert das Feld bei Tap, verbirgt sich bei leerem Feld oder Focus-Verlust. Accessibility-Label "Feld leeren"
- [ ] **Match-Substring im Lehrer-Autocomplete** ist akzent-hervorgehoben (Akzentfarbe + Font-Weight Medium, ohne Background-Tint — der Tint verschwamm auf warmem Card-Background)
- [ ] Klick auf X im Lehrer-Feld leert das Feld; Autocomplete-Dropdown bleibt geschlossen (analog Library-Suche: leeres Feld = keine Vorschlaege)
- [ ] **Save-Button** disabled wenn `teacher.trim().isEmpty || name.trim().isEmpty`. Tint = `theme.interactive`, damit er bei valider Eingabe als Primaer-Action sichtbar bleibt
- [ ] IME-Action im Lehrer-Feld setzt Fokus auf Name-Feld; IME-Action im Name-Feld triggert Save (falls valid)
- [ ] **Placeholder**: Lehrer "Wer leitet die Meditation an?", Name "Wie heisst diese Meditation?". Lokalisiert DE + EN
- [ ] **Name-Feld waechst vertikal mit `maxLines = 3`** — lange Titel brechen um statt mittig zu kuerzen
- [ ] **Datei-Info als kompakter, zweizeiliger Footer** unter der Name-Card: `[Doc-Icon] {filename} · {duration}` mit `maxLines = 2`. Sichtbar in beiden Modi
- [ ] **Toolbar-Vereinfachung**: kein Sheet-Titel, Cancel als minimaler X-Icon-Button, Save-Action behaelt prominentes Pill-Label
- [ ] **Autocomplete-Dropdown im Plain-Look**: keine eigene Card mit Shadow, transparenter Hintergrund, duenne Trennlinien zwischen Vorschlaegen

### Teil 3 — Edit-Sheet-UI, nur Import-Modus

- [ ] Edit-Sheet erscheint mit `prefill.teacher` / `prefill.name` als Default; null-Werte ergeben leere Felder
- [ ] **Autofocus**: wenn `prefill.name == null` → Name-Feld autofocus (Tastatur sofort). Sonst kein Autofocus
- [ ] **Save** persistiert (Datei-Kopie + Library-Eintrag), **Cancel** verwirft die Quelle ohne zu persistieren
- [ ] Modal-Swipe-Down verhaelt sich wie Cancel

### Teil 3 — Edit-Sheet-UI, nur Edit-Modus

- [ ] Sheet zeigt die persistierten Werte unveraendert — auch wenn `teacher = "Unknown Artist"` (Alt-Library, nicht migriert)
- [ ] Kein Autofocus
- [ ] Save ruft Update-Pfad auf, Cancel laesst die Meditation unveraendert

### Tests

- [ ] Pro Sanitize-Akzeptanzkriterium ein dedizierter Test
- [ ] Filename-Preprocessing-Tests (inkl. CamelCase / Akronym / Zahl-Boundaries)
- [ ] Garbage-Detection-Tests (UUID, langes Token, leer)
- [ ] Teacher- und Title-Kaskaden-Tests (alle Stufen, alle Edge-Cases aus `ios-043`)
- [ ] Integration-Test ViewModel-Pfad: Import einer UUID-Datei ohne ID3 → Edit-Sheet mit leeren Feldern; Cancel laesst Library unveraendert; Save mit ausgefuellten Feldern persistiert
- [ ] Autofocus-Regel: `prefill.name == null` → Autofocus Name; sonst kein Autofocus
- [ ] Lehrer + Titel als Pflichtfelder: Save disabled wenn eines leer

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Verbesserung des Import-Flows: keine Typ-Auswahl mehr, bessere Vorschlaege, X-Button, Pflichtfelder, Match-Highlight, schlankere Toolbar)

---

## Manueller Test

### Teil 1 — Share-Import

1. Library mit mind. einer Meditation vorbereiten (fuer Duplikat-Test)
2. Neue MP3 in Files-App per "Teilen" → "Still Moment" → kein Auswahl-Sheet, Library-Tab aktiv, Edit-Sheet oeffnet sich
3. Dieselbe Datei nochmal teilen → "bereits importiert"-Alert
4. Eine PDF teilen → "nicht unterstuetztes Format"-Alert
5. Audio-URL aus Browser teilen → Download → Edit-Sheet wie unter Schritt 2

### Teil 2 — Prefill

6. **ID3-Bestfall** (gut getaggte MP3) → beide Felder gefuellt aus ID3, kein Autofocus, Save enabled
7. **Lehrer im Dateinamen erkannt**: vorher Meditation mit Teacher "Tara Brach" anlegen. `bodyscan-tara_brach.mp3` importieren → Lehrer "Tara Brach", Name "bodyscan"
8. **Filename-only**: `meditation-im-sitzen.mp3` → Lehrer leer, Name "meditation im sitzen", kein Autofocus, Save disabled
9. **Garbage-File**: `d067c0ea-2c04-….mp3` → beide Felder leer, Name autofocus, Save disabled
10. **CamelCase**: `Moment-mal-04Fuesse.mp3` → Vorschlag "Moment mal 04 Fuesse"

### Teil 3 — Edit-Sheet-UI

11. X-Button im gefuellten Feld tippen → Feld leer, Placeholder sichtbar, Save disabled
12. Edit-Modus oeffnen (Overflow-Menue → "Bearbeiten") → Sheet mit gespeicherten Werten, kein Autofocus, Save enabled
13. Alt-Eintrag mit `teacher = "Unknown Artist"` editieren → Wert ist sichtbar, nicht migriert
14. Im Lehrer-Feld "T" tippen → Eintrag "Tara Brach" mit hervorgehobenem T sichtbar
15. Sehr langer Titel: Name-Feld waechst vertikal, kein Truncation in der Mitte

---

## Referenz

- iOS-Pendants:
  - [ios-042](../ios/ios-042-share-import-immer-meditation.md) — Share-Import immer als Meditation
  - [ios-043](../ios/ios-043-import-prefill-service.md) — Prefill-Service (Sanitize + Kaskaden)
  - [ios-044](../ios/ios-044-import-prefill-edit-sheet-ui.md) — Edit-Sheet Prefill-UI
- iOS-Design-Handoff: `handoffs/design_handoff_edit_meta_prefill/`
- Vorgaenger-Ticket: [shared-073](shared-073-import-typ-auswahl.md) (fachlich abgeloest)
- Andere Share-Pipeline-Tickets: [shared-046](shared-046-share-extension.md), [shared-045](shared-045-share-sheet-file-association.md)

---

## Hinweise

- **Prefill-Pipeline als pure Domain-Funktion** im Domain-Layer halten — `ImportPrefill.compute(metadata, filename, knownTeachers)`. Keine Android-Framework-Abhaengigkeit, direkt portierbar aus der iOS-Implementierung.
- **ID3-Tag-Extraktion** ueber `MediaMetadataRetriever` — extrahiert `TPE1` (artist) und `TIT2` (title) in ein Android-`AudioMetadata`-Wert-Objekt analog zum iOS-Service.
- **Persistenz-Lifecycle umbauen**: Heute wird die Datei beim Import sofort in den App-Container kopiert und der Eintrag persistiert. Neu: Prefill berechnen → Edit-Sheet im Import-Modus oeffnen → erst bei Save persistieren. Cancel im Import-Modus muss die Quelle sauber freigeben.
- **Domain-Cleanup vor UI**: Wenn das Android-`GuidedMeditation`-Modell analog zu iOS Override-Felder (`customTeacher`/`customName`) hat, entfaellt der Override-Mechanismus mit der Migration aus `ios-044`. Pruefen, ob das Android-Modell ihn hat — falls ja, Migration analog umsetzen (alte Werte falten beim Decoden, einmaliger Re-Save).
- **Same Edit-Sheet fuer beide Modi**: gleiches Composable, unterschiedlicher `mode`-Parameter (steuert Autofocus, Save-Button-Text). Persistenz-Logik liegt ausserhalb des Composables im ViewModel.
- **Match-Highlight im Autocomplete** ueber `buildAnnotatedString` — Substring der aktuellen Query im Eintrag akzent-eingefaerbt. Gleicher Mechanismus wie in `shared-101`.
- **Auto-Save-Pattern aus `android-073`** ist hier nicht passend — Import-Modus braucht expliziten Save (sonst landet jeder Import auch ohne Bestaetigung in der Library). Edit-Modus kann beim Auto-Save bleiben oder explizit umgestellt werden (Konsistenz mit iOS pruefen).
