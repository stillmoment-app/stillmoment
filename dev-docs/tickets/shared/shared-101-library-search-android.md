# Ticket shared-101: Library-Suche (Android-Sync)

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel — Such-Logik (Tokens, Diakritika, Ranking) + Historie-Persistenz + neuer UI-State und Match-Highlight im Treffer-Text. Such-Engine ist auf iOS bereits als pure Domain-Funktion testbar geschrieben; Compose bietet Material 3 SearchBar als idiomatischen Container.
**Phase**: 3-Feature

---

## Was

Die Bibliothek gefuehrter Meditationen auf Android bekommt eine Volltextsuche ueber Titel und Lehrer. Bei Fokus auf das Suchfeld wird eine Liste der zuletzt gesuchten Begriffe gezeigt, bei aktiver Eingabe eine flache Trefferliste mit Hervorhebung des Suchbegriffs in Akzentfarbe. Verhalten und Such-Engine sind identisch zur iOS-Version.

## Warum

Sobald die persoenliche Sammlung waechst, wird Browsen muehsam. Eine kleine, einfache Suche laesst User bekannte Meditationen schnell wiederfinden — ohne komplexe Filter oder Tags einzufuehren, und ohne den ruhigen Charakter der Library zu stoeren. Die Suchhistorie unterstuetzt wiederkehrende Wunsch-Sitzungen mit minimalem Aufwand.

---

## Plattform-Status

| Plattform | Status | Anmerkung |
|-----------|--------|-----------|
| iOS       | [x]    | Bereits umgesetzt via `ios-041` |
| Android   | [ ]    | Dieses Ticket |

---

## Akzeptanzkriterien

### Sichtbarkeit & Trigger

- [ ] Im Library-Tab erscheint ein Suchfeld, sobald mindestens eine Meditation importiert ist
- [ ] Bei leerer Bibliothek ist kein Suchfeld sichtbar — der bestehende Empty-State bleibt unveraendert
- [ ] Live-Suche filtert ab dem ersten eingegebenen Zeichen
- [ ] Beim Verlassen des Library-Tabs wird die Eingabe zurueckgesetzt; die Historie bleibt
- [ ] Beim Oeffnen eines Treffers (Tap) wird die Eingabe ebenfalls zurueckgesetzt; nach Rueckkehr ist die Library im Idle-Zustand
- [ ] Beim Scrollen in der Trefferliste verschwindet die Tastatur

### Such-Verhalten (identisch zu iOS)

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
- [ ] Bei gleichem Rang werden neuere Meditationen (nach `dateAdded`) zuerst angezeigt

### Trefferliste

- [ ] Die Trefferliste ist flach — keine Lehrer-Sektionen wie im Ruhezustand
- [ ] Ueber der Liste steht eine Treffer-Anzahl ("5 Treffer")
- [ ] Pro Zeile: Titel, Lehrername als Untertitel, Dauer, Play-Symbol rechts
- [ ] Alle Vorkommen des Suchbegriffs in Titel und Lehrer sind in Akzentfarbe hervorgehoben (nicht nur das erste)
- [ ] Tap auf einen Treffer oeffnet den Player wie aus der normalen Liste
- [ ] Long-Press auf einen Treffer startet die Vorschau wie heute (`shared-075`)
- [ ] Swipe auf einen Treffer bietet Bearbeiten und Loeschen wie heute

### Empty-Treffer-State

- [ ] Bei 0 Treffern erscheint ein zentrierter Block mit Lupen-Symbol, Headline "Nichts gefunden" und Subline "Keine Treffer für „{Eingabe}""
- [ ] Der Empty-State wird durch TalkBack beim Erscheinen automatisch angesagt

### Suchhistorie

- [ ] Die Historie wird angezeigt, sobald das Suchfeld fokussiert ist UND die Eingabe leer ist
- [ ] Ueber der Historie steht "Zuletzt gesucht" und rechts ein "Leeren"-Button
- [ ] Die Historie umfasst maximal 6 Eintraege; aelteste fallen heraus, neuester steht oben
- [ ] Ein Suchbegriff wird in die Historie aufgenommen, wenn der User mit IME-Action bestaetigt ODER auf einen Treffer tippt
- [ ] Suchen, die keine Treffer hatten, werden nicht in die Historie aufgenommen
- [ ] Doppelte Eintraege werden nicht erzeugt — ein bereits vorhandener Begriff (case- und diakritika-insensitiv normalisiert) wandert nach oben
- [ ] Tap auf einen Historie-Eintrag setzt den Begriff ins Suchfeld und startet die Suche sofort
- [ ] "Leeren" entfernt die gesamte Historie
- [ ] Die Historie ueberlebt App-Neustarts
- [ ] Die Historie verbleibt rein auf dem Geraet (keine Cloud, keine Synchronisation, kein Tracking)

### Design

- [ ] Suchfeld nutzt das aktuelle Theme (`shared-094` Kerzenschein 2.0) — Akzentfarbe in Caret, Clear-X und Match-Highlight
- [ ] Light- und Dark-Mode lesbar; im Dark-Mode greift die Card-Border-Strategie wie in `shared-094`

### Lokalisierung

- [ ] Neue Strings in DE und EN:
  - Such-Prompt: "Nach Titel oder Sprecher suchen" / "Search by title or teacher" (lange Variante; in `shared-102` ggf. auf "Suchen" / "Search" verkuerzt)
  - Trefferanzahl: "%d Treffer" / "%d results"
  - Empty-Title: "Nichts gefunden" / "No results"
  - Empty-Message: "Keine Treffer für „%@"" / "No matches for "%@""
  - History-Header: "Zuletzt gesucht" / "Recent searches"
  - History-Clear-Button: "Leeren" / "Clear"

### Accessibility

- [ ] Suchfeld traegt ein klares TalkBack-Label "Bibliothek durchsuchen"
- [ ] Der Clear-Button am Suchfeld traegt das Label "Suche leeren"
- [ ] Historie-Eintraege sind als "Erneut suchen: {Begriff}" labelled
- [ ] Match-Highlight benoetigt keinen zusaetzlichen Screen-Reader-Marker — der Text wird normal vorgelesen
- [ ] Beruehrungsflaechen: Trefferzeilen mindestens 48 dp, Suchfeld mindestens 48 dp

### Tests

- [ ] Unit-Tests fuer die Such-Logik: Token-Splitting, Diakritika-Normalisierung, Multi-Token-UND, Substring-Match, leere Eingabe, Rangfolge der vier Buckets, Tiebreaker nach Aufnahmedatum
- [ ] Unit-Tests fuer die Suchhistorie: Hinzufuegen bei Submit und bei Tap auf Treffer, kein Speichern bei 0 Treffern, Deduplizierung (case + diakritika), FIFO-Limit 6, Persistenz ueber App-Neustarts (DataStore oder vergleichbar)
- [ ] ViewModel-Tests fuer die State-Uebergaenge idle ↔ history ↔ results ↔ empty

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung)

---

## Manueller Test

1. Library leer oeffnen → kein Suchfeld sichtbar, bestehender Empty-State
2. Eine Meditation importieren → Suchfeld erscheint
3. Suchfeld antippen → Tastatur erscheint, Liste verschwindet, "Zuletzt gesucht" (zunaechst leer) wird gezeigt
4. "tara" eintippen → Trefferliste flach, alle Vorkommen von "tara" in Akzentfarbe markiert, oben steht "{N} Treffer"
5. Auf einen Treffer tippen → Player oeffnet sich; zurueck zur Library → Suche ist zurueckgesetzt
6. "tar" eintippen und auf einen Treffer tippen → "tar" steht jetzt oben in der Historie
7. "xyz123" eintippen → Empty-State mit Lupen-Symbol und Hinweistext
8. Suchfeld leeren und erneut fokussieren → "xyz123" steht NICHT in der Historie (kein Treffer)
9. App komplett schliessen und neu starten → Historie ist unveraendert vorhanden
10. "Leeren" tippen → Historie ist sofort leer
11. Im Lehrer-Namen suchen ("slat" fuer "Elisabeth Slator") → Treffer erscheint, Match im Untertitel ist hervorgehoben
12. Zwei Tokens "tara body" eintippen → nur Treffer, die beide Tokens enthalten
13. Diakritika weglassen ("ubung") → "Übung" wird gefunden
14. In der Trefferliste scrollen → Tastatur klappt ein

---

## Referenz

- iOS-Pendant: [ios-041](../ios/ios-041-library-search.md)
- iOS-Design-Handoff: `handoffs/library_search/README.md`
- iOS-Such-Engine (zur Referenz): `LibrarySearchEngine` im Domain-Layer (pure Funktion, ranking-Buckets)
- Android-Library-View und -ViewModel im Library-Tab

---

## Hinweise

- **Such-Engine als pure Domain-Funktion** halten — Token-Normalisierung, Diakritika-Folding, Multi-Token-UND, Score-Buckets. Direkt portierbar aus der iOS-Implementierung.
- **Suchfeld**: Material 3 `SearchBar` oder einfaches `TextField` in einem Card-Container — Designer-Vorgabe ist visuelle Konsistenz mit iOS, nicht zwingend Material-3-Default. Light Mode mit Schatten, Dark Mode mit Border (Memory-Notiz `shared-094`).
- **History-Persistenz** ueber DataStore (kein neues Storage-Subsystem noetig) — kleine `List<String>`, Privacy-konform lokal.
- **Tastatur einklappen** beim Scrollen via `Modifier.scrollable` + `LocalSoftwareKeyboardController`.
- **Match-Highlight** ueber `buildAnnotatedString { ... }` mit `SpanStyle(color = theme.interactive)` — alle Vorkommen, nicht nur das erste.
- **Diakritika-Normalisierung**: Java `Normalizer.normalize(text, NFD)` + Strip-Combining-Marks; case-insensitive ueber `String.equals(ignoreCase = true)` bzw. `lowercase()`.
- **Header-Layout** mit immer sichtbarem Suchfeld kommt in `shared-102` (Folge-Ticket, baut darauf auf).
