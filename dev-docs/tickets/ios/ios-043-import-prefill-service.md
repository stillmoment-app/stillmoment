# Ticket ios-043: Prefill-Service fuer Meditation-Import

**Status**: [x] DONE
**Plan**: [Implementierungsplan](../plans/ios-043.md)
**Prioritaet**: HOCH
**Komplexitaet**: Schlanke Pipeline (sanitize → preprocess → garbage-check → zwei Kaskaden), jede Stufe trivial. Reine Domain/Application-Layer-Arbeit ohne UI.
**Abhaengigkeiten**: ios-042 (Share-Import immer als Meditation)
**Phase**: 3-Feature

---

## Ziel

Beim Import einer Audiodatei sollen sinnvolle Werte fuer `teacher` und `name` automatisch vorgeschlagen werden — und **schlechte Werte** (Encoder-Platzhalter wie `"Unknown Artist"`, UUID-Schrott, Server-Defaults wie `audio.mp3`) als solche erkannt und ausgelassen werden, damit das Edit-Sheet (ios-044) nicht Muell als Default praesentiert.

`teacher` und `name` werden **getrennt** behandelt: pro Feld eine eigene Kaskade. Die beiden Kaskaden laufen unabhaengig — z. B. Teacher aus ID3 + Name aus Dateiname ist ein gewollter, sauber abgebildeter Fall.

---

## Domain-Modell

```swift
struct ImportPrefill: Equatable {
    let teacher: String?
    let name: String?
}
```

Zwei Optionals, das ist alles. `nil` bedeutet „kein Vorschlag, das Feld bleibt im Edit-Sheet leer". Quelle (ID3 vs. Filename) wird nicht persistiert — der Handoff verzichtet bewusst auf Source-Badges und Banner („Prefill ist still"), also wird die Information auch nicht in der Domain benoetigt.

---

## Sanitize-Funktion

`sanitize(_ raw: String?) -> String?` — zentrale Filterung. Wird angewendet auf **ID3-Werte**, auf die `knownTeachers`-Liste **und** auf den preprocessed Filename. Damit gibt es genau **eine** Stelle, an der Platzhalter-Strings ausgesiebt werden.

Schritte:

1. Whitespace trimmen → wenn leer: `nil`.
2. **Erzeuge eine temporaere Vergleichs-Kopie** des getrimmten Werts: lowercase + alle Trenner (`_`, `-`, `.`, ` `, `/`) entfernt. Diese Kopie wird ausschliesslich fuer die naechsten zwei Schritte verwendet — nie zurueckgegeben.
3. Wenn die Vergleichs-Kopie **exakt** (Set-Membership, nicht Substring) in der Blacklist liegt → `nil`.
4. Wenn die Vergleichs-Kopie eine reine Track-Nummerierung ist (`^(track)?\d{1,3}$`) → `nil`.
5. Sonst: **getrimmter Original-Wert** zurueck — Whitespace und Casing im Inhalt unveraendert. Beispiel: `"Body Scan"` → `"Body Scan"`, nicht `"bodyscan"`.

**Blacklist** (normalisiert, case-insensitive):
```
unknown, unknownartist, untitled, audio, recording, voicememo, voicerecording
```

Hypothetische Werte wie `noartist`, `artist`, `performer`, `title` sind bewusst nicht enthalten — falls sie in der Praxis je auftreten, kann die Liste additiv erweitert werden.

---

## Filename-Preprocessing

Der Dateiname wird vor der Verwendung in beiden Kaskaden gesaeubert. Schritte:

1. Endung entfernen (`.mp3`, `.m4a`).
2. **Track-Nummer-Praefix entfernen**: `^\d{1,3}[-_.\s]+` (z. B. `01-body-scan` → `body-scan`).
3. Trenner `_`, `-`, `.` zu Spaces normalisieren, multiple Spaces zu single Space kollabieren, Trim.
4. **Casing wird NICHT veraendert** — der Filename wird verbatim uebernommen. Wenn der User `meditation-im-sitzen` schreibt, ergibt das `"meditation im sitzen"`; bei `Meditation-im-Sitzen` bleibt das so. Respektiert die Intention des Filenames, vermeidet falsches Title-Case (gerade im Deutschen mit Praepositionen wie „im", „und", „zur") und macht eine separate Akronym-Preservation-Regel ueberfluessig — Grossschreibung kommt automatisch aus dem Quelltext.

Das Ergebnis ist ein „cleaned filename" — ein einfacher Space-getrennter String.

**Bewusst out of scope** (additiv erweiterbar, falls real haeufig): Bracket-Praefixe (`[Channel] Title`), Datum-Praefixe (`2024-03-15-…`), Versionssuffixe (`_v2`, `_FINAL`). Sind plattform-/workflow-spezifisch und kommen bei dem typischen Importer-Flow selten vor.

---

## Garbage-Detection

Der preprocessed Filename gilt als unbrauchbar, wenn **eine** der folgenden Heuristiken zutrifft. Bei Garbage bleibt der Title-Vorschlag `nil`:

- **UUID-v4-Pattern** (case-insensitive): `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$` — der Anchor-Fall.
- **Einzelnes Token ohne Trenner**: Laenge >= 24 und kein `_ - . ` `/` darin (faengt Hash-IDs ab).
- **Leer nach Preprocessing** (Track-Praefix war alles).

Platzhalter wie `audio`, `voicememo`, `untitled` werden bereits durch die Sanitize-Funktion gefiltert (die nach dem Preprocessing auf den Filename angewendet wird) — keine Verdopplung hier.

---

## Teacher-Kaskade

1. **ID3-Artist**: `sanitize(metadata.artist)` → wenn nicht-nil: dieser Wert.
2. **Match in `knownTeachers`** gegen preprocessed Filename:
   - Liste vorher mit `sanitize(_:)` filtern — Alt-Library-Eintraege `"Unknown Artist"` werden so vom Match ausgeschlossen.
   - Nach Laenge **absteigend** sortieren (Praezedenz `"Tara Brach"` vor `"Tara"`).
   - Nur Namen matchen, die **>= 2 Worte ODER >= 6 Zeichen** haben (verhindert false positives bei kurzen Vornamen wie `"Tara"` im Wort `"Tarantino"`).
   - Match: Lehrer-Name als zusammenhaengender Substring im (lowercased) Filename.
   - Bei Treffer: Original-Casing des Eintrags aus `knownTeachers`.
3. Sonst: `nil`.

---

## Title-Kaskade

1. **ID3-Title**: `sanitize(metadata.title)` → wenn nicht-nil: dieser Wert.
2. **Filename ohne Teacher**: wenn Teacher (aus Stufe 1 oder Stufe 2 der Teacher-Kaskade) als zusammenhaengender Substring (case-insensitive) im preprocessed Filename vorkommt:
   - Teacher-Substring aus dem preprocessed Filename entfernen.
   - Spaces re-normalisieren (multiple → single, Trim).
   - Casing **nicht** veraendern (siehe Preprocessing).
   - Auf das Ergebnis `sanitize(_:)` anwenden (filtert Garbage-Reste).
   - Wenn Resultat nicht-nil und >= 3 Zeichen: dieser Wert.
3. **Filename komplett** (wenn Stufe 2 nicht griff): wenn preprocessed Filename **nicht Garbage**:
   - `sanitize(preprocessedFilename)` anwenden — filtert Platzhalter-Strings wie `audio`.
   - Wenn Resultat nicht-nil und >= 3 Zeichen: dieser Wert.
4. Sonst: `nil`.

**Wichtig:** Stufe 2 greift unabhaengig davon, ob der Teacher aus ID3 oder aus dem Filename-Match kam. Realistischer Fall: ID3-`artist` ist gesetzt **und** der Teacher-Name steht zufaellig auch im Filename (Podcast-Plattformen schreiben oft beides). Ohne diese Logik wuerde Stufe 3 den Teacher-Namen erneut im Titel landen lassen (z. B. `name = "bodyscan tara brach"`).

---

## Warum

Der Import ist ein Kern-Feature der App. Heute landet die User:in nach einem Share oft vor einer Maske mit Percent-Encoded-URL-Schrott als Titel und `"Unknown Artist"` als Teacher — erster Eindruck = Reibung statt Komfort. Echte Beispieldaten zeigen, dass der Worst Case haeufig ist: Anchor-Podcast-Audio kommt mit ID3v2-Header, aber **ohne** `TIT2`/`TPE1` (nur `TSS` = Encoder), `Content-Disposition` fehlt, Dateiname ist UUID.

Eine getrennte Behandlung pro Feld ist sauberer als die einkanalige Kaskade aus dem urspruenglichen Entwurf: in der Praxis sind Teacher und Title nicht gekoppelt (oft ist eines vorhanden, das andere nicht).

Die Sanitize-Funktion zentralisiert die „nutzlose Werte verwerfen"-Logik. Sie laeuft an drei Stellen: auf ID3-Werte, auf die `knownTeachers`-Liste (sodass alte `"Unknown Artist"`-Strings nicht via Filename-Match-Pfad zurueckkommen) und auf den preprocessed Filename (filtert Server-Default-Strings wie `audio` zentral statt sie nochmal in die Garbage-Detection zu duplizieren).

---

## Referenz

- Design-Handoff: `handoffs/design_handoff_edit_meta_prefill/README.md` (Abschnitt „Prefill-Kaskade (Kern-Logik)" und „Prefill-Indikatoren — keine Banner, keine Badges").
- Begleit-Ticket fuer die UI: [ios-044 — Edit-Sheet Prefill-UI](ios-044-import-prefill-edit-sheet-ui.md)
- Bestehende Stellen:
  - `GuidedMeditationService.addMeditation` (heute Default-Fallback `"Unknown Artist"` und nackter `lastPathComponent`).
  - `GuidedMeditationsListViewModel.importMeditation` (heute ruft `addMeditation` sofort beim Import auf; muss umgebaut werden — Prefill berechnen, Edit-Sheet oeffnen, erst bei Save persistieren).

---

## Akzeptanzkriterien

### Sanitize-Funktion

- [ ] `sanitize(nil)` und `sanitize("   ")` → `nil`.
- [ ] `sanitize("Unknown Artist")` → `nil`. Ebenso `"unknown_artist"`, `"unknown-artist"`, `"UNKNOWN ARTIST"`, `"Unknown   Artist"` (alle case-insensitive, trenner-insensitiv).
- [ ] `sanitize("Untitled")` → `nil`. Ebenso `"audio"`, `"recording"`, `"voice memo"`, `"voice_memo"`.
- [ ] `sanitize("Track 01")` → `nil`. Ebenso `"01"`, `"1"`, `"track 03"`, `"track03"`.
- [ ] `sanitize("Tara Brach")` → `"Tara Brach"` (unveraendert ausser Trim).
- [ ] `sanitize("  Body Scan  ")` → `"Body Scan"` (Whitespace getrimmt, Inhalt unveraendert).

### Filename-Preprocessing

- [ ] `preprocess("01-body-scan.mp3")` → `"body scan"` (Track-Praefix weg, Trenner zu Space, Lowercase erhalten).
- [ ] `preprocess("Bodyscan.mp3")` → `"Bodyscan"`.
- [ ] `preprocess("meditation-im-sitzen.mp3")` → `"meditation im sitzen"`.
- [ ] `preprocess("Anleitung-Bodyscan-Deutsch-MBSR.mp3")` → `"Anleitung Bodyscan Deutsch MBSR"` (Casing verbatim, MBSR bleibt UPPERCASE weil im Quelltext UPPERCASE).
- [ ] Casing wird durchgaengig verbatim aus dem Quelltext uebernommen (keine Title-Case-Transformation).

### Garbage-Detection

- [ ] `d067c0ea-2c04-b934-1e04-94b2dc2f13dd` → Garbage (UUID).
- [ ] Sehr langes Token ohne Trenner (`thisistheverylongunbrokenfilename`, `abc123def456ghi789jklmnop`) → Garbage.
- [ ] Leer nach Preprocessing (`01.mp3`) → Garbage.

### Teacher-Kaskade

- [ ] `metadata.artist = "Tara Brach"`: → `teacher = "Tara Brach"`.
- [ ] `metadata.artist = "Unknown Artist"`, `knownTeachers = []`: → `teacher = nil`.
- [ ] `metadata.artist = nil`, `filename = "bodyscan-tara_brach.mp3"`, `knownTeachers = ["Tara Brach"]`: → `teacher = "Tara Brach"`.
- [ ] `knownTeachers` enthaelt `"Unknown Artist"` (Alt-Library): wird NICHT gematched, weil sanitize ihn vor dem Match auf nil mappt.
- [ ] Praezedenz `"Tara Brach"` vor `"Tara"` wenn beide in `knownTeachers`.
- [ ] Filename-Match nur, wenn Teacher-Name >= 2 Worte ODER >= 6 Zeichen.
- [ ] `knownTeachers = []`: Stufe 2 inaktiv, faellt auf `nil` durch.

### Title-Kaskade

- [ ] `metadata.title = "Body Scan"`: → `name = "Body Scan"`.
- [ ] `metadata.title = "Untitled"`, Filename `"Anleitung-Bodyscan-Deutsch-MBSR.mp3"`: → `name = "Anleitung Bodyscan Deutsch MBSR"`.
- [ ] `metadata.title = nil`, Filename `"meditation-im-sitzen.mp3"`: → `name = "meditation im sitzen"` (Casing aus dem Filename respektiert, kein erzwungenes Title-Case).
- [ ] `metadata.title = nil`, Filename `"bodyscan-tara_brach.mp3"`, Teacher gematched in Kaskade 2 (`knownTeachers = ["Tara Brach"]`): Rest „bodyscan" → `name = "bodyscan"`.
- [ ] `metadata.artist = "Tara Brach"`, `metadata.title = nil`, Filename `"bodyscan-tara_brach.mp3"`: Teacher kommt aus ID3 (Stufe 1), trotzdem Substring im Filename → wird entfernt → `name = "bodyscan"`. (NICHT `"bodyscan tara brach"`.)
- [ ] `metadata.artist = "Tara Brach"`, `metadata.title = nil`, Filename `"morning-meditation.mp3"`: Teacher aus ID3, **nicht** im Filename → Stufe 2 greift nicht, Stufe 3 nimmt komplett → `name = "morning meditation"`.
- [ ] Filename = `"d067c0ea-2c04-b934-1e04-94b2dc2f13dd.mp3"`, kein ID3: → `name = nil` (Garbage).
- [ ] Filename = `"audio.mp3"`, kein ID3: → `name = nil` (Sanitize filtert nach Preprocessing).
- [ ] Filename = `"01-body-scan.mp3"`, kein ID3: → `name = "body scan"`.

### Integration

- [ ] `GuidedMeditationService.addMeditation` bekommt zwei neue Parameter `teacher: String` und `name: String` — sie werden direkt in den persistierten Eintrag uebernommen. Der `metadata.artist ?? "Unknown Artist"`-Default und der `metadata.title ?? lastPathComponent`-Default fallen ersatzlos weg.
- [ ] Persistenz-Lifecycle: Beim Import wird `addMeditation` **erst nach Save** im Edit-Sheet aufgerufen. Die Datei-Kopie in den App-Container und der Bookmark werden ebenfalls erst dann angelegt. Cancel im Import-Modus persistiert nichts (kein Library-Eintrag, keine Datei-Leiche).
- [ ] Die Prefill-Berechnung passiert im ViewModel (`GuidedMeditationsListViewModel`) **vor** dem Edit-Sheet, nicht im Service. Der Service kennt `ImportPrefill` nicht.
- [ ] Aggregation der `knownTeachers`-Liste (ViewModel-Seite): `loadMeditations()` → `.compactMap { $0.effectiveTeacher }` → `Array(Set(...))` → an `ImportPrefill.compute` uebergeben.
- [ ] Bestehende Library-Eintraege werden nicht migriert — `"Unknown Artist"` bleibt dort als gespeicherter String erhalten und kann via Edit-Sheet manuell ueberschrieben werden.

### Tests

- [ ] Pro Akzeptanzkriterium oben ein dedizierter Test.
- [ ] Integration-Test ViewModel-Pfad: Import einer UUID-Datei ohne ID3 → Edit-Sheet bekommt `ImportPrefill(teacher: nil, name: nil)`, beide Felder leer; Cancel laesst Library unveraendert; Save mit ausgefuellten Feldern persistiert ueber `addMeditation`.

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Verbesserung: bessere Vorschlaege beim Import).

---

## Out of Scope (moegliche spaetere Erweiterungen)

- **Bracket-/Datum-/Versionssuffix-Cleanup im Filename**: plattform-spezifisch, additiv erweiterbar wenn in der Praxis haeufig gesehen.
- **Erweiterte Garbage-Heuristiken** (Hex-Dominanz, Pure Timestamps, `IMG_xxx`): kommen bei Meditations-Audio realistisch kaum vor; falls noetig additiv ergaenzen.
- **„Artist - Title"-Splitter** im Filename (z. B. `"Tara Brach - Body Scan.mp3"`). Funktioniert heute schon, wenn Teacher in `knownTeachers` ist (Substring-Match greift). Expliziter Split nur fuer den Fall, dass der Teacher unbekannt ist — selten und ambivalent.
- **Album-Tag als Fallback fuer Teacher** (`metadata.album`).
- **Bundled-Liste prominenter Lehrer:innen** als Onboarding-Fallback bei leerer Library.
- **Edit-Sheet-UI** (X-Button, erweiterter Lehrer-Autocomplete, Pflichtfeld-Lehrer): kommt in ios-044.
- **Migration bestehender Library-Eintraege**.
- **Source-Markierung pro Feld** (ID3 vs. Filename). Bewusst nicht im Output — die UI ist „still" (keine Banner, keine Badges).

---

## Manueller Test

Eingeschraenkt sinnvoll, weil die UI erst mit ios-044 nachzieht. Trotzdem:

1. App in Xcode bauen, Breakpoint in `ImportPrefill.compute`.
2. Verschiedene Dateien per Share importieren und im Debugger pruefen:
   - Gut getaggte MP3 (TPE1 + TIT2 gesetzt) → beide Felder gefuellt aus ID3.
   - `bodyscan-tara_brach.mp3` **ohne ID3**, `knownTeachers = ["Tara Brach"]` → Teacher aus Filename-Match, Title = `"bodyscan"`.
   - `bodyscan-tara_brach.mp3` **mit ID3-`artist = "Tara Brach"`**, kein Title → Teacher aus ID3, Title = `"bodyscan"`.
   - `anleitung-bodyscan-deutsch-mbsr.mp3` → Teacher `nil`, Title = `"anleitung bodyscan deutsch mbsr"` (Casing verbatim).
   - `d067c0ea-….mp3` ohne ID3 → beide `nil`.
   - `audio.mp3` → beide `nil`.
   - `01-body-scan.mp3` → Track-Praefix weg, Title = `"body scan"`.

---

## Hinweise

- ID3-Tag-Extraktion bleibt unveraendert in `AudioMetadataService` — der Service konsumiert das bestehende `AudioMetadata`-Wert-Objekt.
- Filename-Preprocessing und Garbage-Detection sind interne Hilfen — `private static`-Methoden im Service oder eine Helper-Datei. Nicht oeffentlich.
- Die Sanitize-Funktion ist Domain-rein (kein AVFoundation, kein UIKit) — kann unabhaengig getestet werden.
