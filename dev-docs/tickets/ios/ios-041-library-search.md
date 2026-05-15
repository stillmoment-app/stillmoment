# Ticket ios-041: Suchfunktion fuer die Bibliothek

**Status**: [x] DONE
**Plan**: [Implementierungsplan](../plans/ios-041.md)
**Prioritaet**: MITTEL
**Komplexitaet**: mittel — Such-Logik (Tokens, Diakritika, Ranking) + Historie-Persistenz + neuer UI-State und Match-Highlight im Treffer-Text
**Abhaengigkeiten**: Keine
**Phase**: 3-Feature

---

## Was

Die Bibliothek geführter Meditationen bekommt eine Volltextsuche über Titel und Lehrer. Bei Fokus auf das Suchfeld wird eine Liste der zuletzt gesuchten Begriffe gezeigt, bei aktiver Eingabe eine flache Trefferliste mit Hervorhebung des Suchbegriffs in Akzentfarbe. Layout und Verhalten folgen dem Design-Handoff in `handoffs/library_search/`.

## Warum

Sobald die persoenliche Sammlung waechst, wird Browsen muehsam. Eine kleine, einfache Suche laesst User bekannte Meditationen schnell wiederfinden — ohne komplexe Filter oder Tags einzufuehren, und ohne den ruhigen Charakter der Library zu stoeren. Die Suchhistorie unterstuetzt wiederkehrende Wunsch-Sitzungen mit minimalem Aufwand.

---

## Akzeptanzkriterien

### Sichtbarkeit & Trigger

- [ ] Im Library-Tab erscheint ein Suchfeld unter dem Titel, sobald mindestens eine Meditation importiert ist
- [ ] Bei leerer Bibliothek ist kein Suchfeld sichtbar — der bestehende Empty-State bleibt unveraendert
- [ ] Live-Suche filtert ab dem ersten eingegebenen Zeichen
- [ ] Beim Verlassen des Library-Tabs wird die Eingabe zurueckgesetzt; die Historie bleibt
- [ ] Beim Oeffnen eines Treffers (Tap) wird die Eingabe ebenfalls zurueckgesetzt; nach Rueckkehr ist die Library wieder im Ruhezustand
- [ ] Beim Scrollen in der Trefferliste verschwindet die Tastatur

### Such-Verhalten

- [ ] Suche findet Treffer im Titel UND im Lehrernamen einer Meditation
- [ ] Suche ist case-insensitiv ("ATEM" findet "Atem")
- [ ] Suche ist diakritika-insensitiv ("ubung" findet "Übung")
- [ ] Suche findet Substrings auch mittendrin ("ata" findet "Tara")
- [ ] Mehrere durch Leerzeichen getrennte Woerter werden als UND verknuepft ("tara body" findet "Tara Brach — Body Scan", aber nicht "Tara Brach — Atemmeditation")
- [ ] Sortierung der Treffer (absteigende Relevanz):
  1. Treffer am Wortanfang im Titel
  2. Treffer am Wortanfang im Lehrer
  3. Treffer mittendrin im Titel
  4. Treffer mittendrin im Lehrer
- [ ] Bei gleichem Rang werden neuere Meditationen (nach Aufnahme in die Library) zuerst angezeigt

### Trefferliste

- [ ] Die Trefferliste ist flach — keine Lehrer-Sektionen wie im Ruhezustand
- [ ] Ueber der Liste steht eine Treffer-Anzahl ("5 Treffer")
- [ ] Pro Zeile: Titel, Lehrername als Untertitel, Dauer, Play-Symbol rechts
- [ ] Alle Vorkommen des Suchbegriffs im Titel- und Lehrer-Text sind in Akzentfarbe hervorgehoben (nicht nur das erste)
- [ ] Tap auf einen Treffer oeffnet den Player wie aus der normalen Liste
- [ ] Long-Press auf einen Treffer startet die Vorschau wie heute
- [ ] Swipe auf einen Treffer bietet Bearbeiten und Loeschen wie heute

### Empty-Treffer-State

- [ ] Bei 0 Treffern erscheint ein zentrierter Block mit Lupen-Symbol, Headline "Nichts gefunden" und Subline "Keine Treffer für „{Eingabe}""
- [ ] Der Empty-State wird durch VoiceOver beim Erscheinen automatisch angesagt

### Suchhistorie

- [ ] Die Historie wird angezeigt, sobald das Suchfeld fokussiert ist UND die Eingabe leer ist
- [ ] Ueber der Historie steht "Zuletzt gesucht" und rechts ein "Leeren"-Button
- [ ] Die Historie umfasst maximal 6 Eintraege; aelteste fallen heraus, neuester steht oben
- [ ] Ein Suchbegriff wird in die Historie aufgenommen, wenn der User mit Return bestaetigt ODER auf einen Treffer tippt
- [ ] Suchen, die keine Treffer hatten, werden nicht in die Historie aufgenommen
- [ ] Doppelte Eintraege werden nicht erzeugt: ein bereits vorhandener Begriff (case- und diakritika-insensitiv normalisiert) wandert stattdessen nach oben
- [ ] Tap auf einen Historie-Eintrag setzt den Begriff ins Suchfeld und startet die Suche sofort
- [ ] "Leeren" entfernt die gesamte Historie
- [ ] Die Historie ueberlebt App-Neustarts
- [ ] Die Historie verbleibt rein auf dem Geraet (keine Cloud, keine Synchronisation, kein Tracking)

### Design

- [ ] UI entspricht dem Design-Handoff in `handoffs/library_search/` (Suchfeld-Styling, Caret, Clear-X, Highlight-Farben, Empty-State-Lupe, Historie-Zeile mit Uhr- und Diagonal-Pfeil-Icon)
- [ ] Theme-Wechsel (Kupfer / Salbei / Daemmerung) trifft Suchfeld, Trefferliste, Empty-State und Match-Highlight korrekt
- [ ] Im Light- und Dark-Mode bleibt der Kontrast des Match-Highlights gut lesbar

### Lokalisierung

- [ ] Neue Strings sind in Deutsch und Englisch vorhanden:
  - Such-Prompt: "Nach Titel oder Sprecher suchen" / "Search by title or teacher"
  - Trefferanzahl: "%d Treffer" / "%d results"
  - Empty-Title: "Nichts gefunden" / "No results"
  - Empty-Message: "Keine Treffer für „%@"" / "No matches for "%@""
  - History-Header: "Zuletzt gesucht" / "Recent searches"
  - History-Clear-Button: "Leeren" / "Clear"

### Accessibility

- [ ] Suchfeld traegt ein klares VoiceOver-Label im Sinne von "Bibliothek durchsuchen"
- [ ] Der Clear-Button am Suchfeld traegt das Label "Suche leeren"
- [ ] Historie-Eintraege sind als "Erneut suchen: {Begriff}" labelled
- [ ] Match-Highlight benoetigt keinen zusaetzlichen Screen-Reader-Marker — der Text wird normal vorgelesen
- [ ] Beruehrungsflaechen: Trefferzeilen mindestens 44 pt hoch, Suchfeld 44 pt hoch

### Tests

- [ ] Unit-Tests fuer die Such-Logik: Token-Splitting, Diakritika-Normalisierung, Multi-Token-UND, Substring-Match, leere Eingabe, Rangfolge der vier Buckets, Tiebreaker nach Aufnahmedatum
- [ ] Unit-Tests fuer die Suchhistorie: Hinzufuegen bei Submit und bei Tap auf Treffer, kein Speichern bei 0 Treffern, Deduplizierung (case + diakritika), FIFO-Limit 6, Persistenz ueber App-Neustarts
- [ ] ViewModel-Tests fuer die State-Uebergaenge idle ↔ history ↔ results ↔ empty

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung)

---

## Manueller Test

1. Library leer oeffnen → kein Suchfeld sichtbar, bestehender Empty-State
2. Eine Meditation importieren → Suchfeld erscheint unter dem Titel
3. Suchfeld antippen → Tastatur erscheint, Liste verschwindet, "Zuletzt gesucht" (zunaechst leer) wird gezeigt
4. "tara" eintippen → Trefferliste flach, alle Vorkommen von "tara" in Akzentfarbe markiert, oben steht "{N} Treffer"
5. Auf einen Treffer tippen → Player oeffnet sich; zurueck zur Library → Suche ist zurueckgesetzt
6. "tar" eintippen und auf einen Treffer tippen → "tar" steht jetzt oben in der Historie (erneut Suchfeld fokussieren, Eingabe leeren)
7. "xyz123" eintippen → Empty-State mit Lupen-Symbol und Hinweistext
8. Suchfeld leeren und erneut fokussieren → "xyz123" steht NICHT in der Historie (kein Treffer)
9. App komplett schliessen und neu starten → Historie ist unveraendert vorhanden
10. "Leeren" tippen → Historie ist sofort leer
11. Im Lehrer-Namen suchen (z.B. "slat" fuer "Elisabeth Slator") → Treffer erscheint, Match im Untertitel ist hervorgehoben
12. Zwei Tokens "tara body" eintippen → nur Treffer, die beide Tokens enthalten, erscheinen
13. Diakritika weglassen ("ubung") → "Übung" wird gefunden
14. Theme wechseln (Settings → Erscheinungsbild) → Suchfeld und Highlight uebernehmen die neue Akzentfarbe
15. In der Trefferliste scrollen → Tastatur klappt ein

---

## Referenz

- Design-Handoff: `handoffs/library_search/README.md` (pixelgenaue Vorgaben, Design-Tokens, Typografie, alle vier States)
- Library-View: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- Library-ViewModel: `ios/StillMoment/Application/ViewModels/GuidedMeditationsListViewModel.swift`
- Datenmodell: `ios/StillMoment/Domain/Models/GuidedMeditation.swift` (Felder `effectiveName`, `effectiveTeacher`, `dateAdded`)

---

## Hinweise

- Suchfeld via `.searchable(text:placement:.automatic, prompt:)` auf den `NavigationStack` des Library-Tabs. `placement: .automatic` ist bewusst gewaehlt: Apple platziert das Feld auf allen iOS-Versionen oben unter dem Titel. Eine iOS-26-Liquid-Glass-Bottombar wuerde mit der Tab-Bar kollidieren — der Designer hat sich explizit dagegen entschieden.
- Suchhistorie ueber den `.searchSuggestions(...)`-Modifier rendern: dieser zeigt seinen Inhalt automatisch nur, wenn das Suchfeld fokussiert UND die Eingabe leer ist.
- Match-Highlight mit `AttributedString` und Range-basiertem Foreground/Background, damit alle Vorkommen pro Text hervorgehoben werden — nicht nur das erste.
- Toleranz-Logik: `String.CompareOptions` mit `.caseInsensitive` + `.diacriticInsensitive` ist ausreichend. Keine externe Fuzzy-Library noetig — bewusste "Simplest solution first"-Entscheidung. Multi-Token-UND wird durch Whitespace-Splitting der Eingabe und einzelnen Substring-Check pro Token erreicht.
- Tastatur beim Scrollen einklappen via `.scrollDismissesKeyboard(.immediately)`.
- Den "Abbrechen"-Button rendert SwiftUI bei aktiver `.searchable` automatisch — nicht selbst nachbauen.
- Such-Logik (Score-Berechnung, Token-Normalisierung) als pure Funktion im Domain-Layer testbar machen — unabhaengig vom ViewModel.
- Persistenz der Historie: `UserDefaults` reicht (kleine Liste von Strings, kein Bedarf fuer eigenes Storage-Subsystem). Privacy-Konformitaet: Daten bleiben auf dem Geraet.
- Android folgt in einem separaten Ticket (Material 3 SearchBar). Cross-Platform-Konsistenz wird dort nachgezogen.
