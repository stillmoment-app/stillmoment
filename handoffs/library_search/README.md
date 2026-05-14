# Handoff: Library Search — Suchfunktion für die Bibliothek

## Übersicht

Dies ist die **Suchfunktion für die Bibliothek "Geführte Meditationen"** der Meditations-App "Still Moment". Der Nutzer findet eine ihm bekannte Meditation aus seiner persönlichen Sammlung (importierte Aufnahmen) durch Tippen im Suchfeld.

**Designprinzip:** Browse-first — die Bibliothek wird gescrollt und gestöbert, gesucht wird nur gelegentlich. Daher folgt das Design Apples HIG-Empfehlung und platziert das Suchfeld **oben unter dem Titel**, nicht in der Bottom-Bar (Liquid-Glass-Pill würde mit der bestehenden Tab-Bar kollidieren).

## Über die Design-Dateien

Die Dateien sind **HTML-Design-Referenzen** — Prototypen, die das beabsichtigte Aussehen zeigen, **kein Produktionscode**. Aufgabe: Diese Designs in der Ziel-Codebase mit deren etablierten Patterns nachbauen.

**Empfohlene native Implementation (SwiftUI):** mit `.searchable(text:placement:.automatic, prompt:)` auf den NavigationStack des Bibliotheks-Tabs. Apple wählt dann je iOS-Version das passende Layout (auf iOS 26 ggf. mit Liquid-Glass-Akzent unter dem Titel, auf älteren iOS ein klassisches UISearchBar). Das hier vorliegende Design entspricht der **iOS-übergreifenden Top-Placement-Konvention** und matched, was `.searchable` standardmäßig in einem TabView-Tab rendert.

## Fidelity

**High-fidelity (hifi).** Alle Maße, Farben, Typografie und Verhalten sind final. Pixelgenau nachbauen.

## Bildschirm

### Name
**Library Search — Suchfunktion in der Bibliothek**

### Zweck
Nutzer findet eine bekannte Meditation in seiner persönlichen Sammlung über Volltextsuche in Titel + Sprecher.

### Scope
- Sucht **gleichzeitig** in Titel und Sprecher (case-insensitive Substring-Match)
- **Keine** Scope-Bar / Filter-Pills — bewusst entschieden gegen UI-Komplexität
- Match-Highlight im Akzent zeigt visuell, *wo* der Treffer sitzt

### Layout (Frame: 393 × 852, iPhone 15/16/17 Pro logical)

```
┌───────────────────────────────────────┐
│ Status Bar (54 px)                    │  09:41 + Signal/Wifi/Battery
├───────────────────────────────────────┤
│                                       │
│  Geführte Meditationen      [+] [ⓘ]   │  H-Display 22, padding 8/20
│                                       │
│  ┌─────────────────────────────────┐  │  Suchfeld (10/14 padding)
│  │ 🔍  Nach Titel oder Sprecher…   │  │  unfocused: text-3
│  └─────────────────────────────────┘  │  focused: text + caret + glow
│                                       │
│  [Content nach State — s.u.]          │
│                                       │
├───────────────────────────────────────┤
│  Tab Bar (96 px reserviert)           │  Timer | Meditationen | Einstellungen
└───────────────────────────────────────┘
```

## States

### 1. Inaktiv (`state="idle"`)
- Suchfeld unter Titel, **unfokussiert**, Placeholder „Nach Titel oder Sprecher suchen"
- Darunter: bestehende Bibliotheks-Ansicht (nach Sprecher gruppiert, Karten)
- Tab-Bar unverändert

### 2. Fokussiert + Feld leer (`state="history"`)
- Suchfeld bekommt Akzent-Border (1 px) + 3 px Glow `rgba(196,122,94,0.10)`
- Bestehende Liste verschwindet; stattdessen erscheint **„Zuletzt gesucht"** als vertikale Liste
- Trailing: „Leeren"-Button (Akzent-Text-Farbe)
- Listenzeile: Uhr-Icon (15×15, text-3) + Suchbegriff (Newsreader-ähnlich, 15 px) + Diagonal-Pfeil-Icon
- Trennung der Zeilen: 1px `rgba(235,226,214,0.04)` unten

### 3. Treffer (`state="results"`)
- Suchfeld zeigt Query in `var(--sm-text)`, Caret blinkt, kleines Clear-X rechts
- Darunter: Eyebrow „N Treffer" (text-3, 11 px, uppercase, 0.08em letter-spacing)
- Card mit **flacher Trefferliste**:
  - Titel: Newsreader 15 px, mit Match-Highlight
  - Subtitle: Sprecher (Highlight möglich) · Dauer, in text-2
  - Play-Badge rechts (36×36 Kupfer-Gradient-Kreis mit Play-Glyph)
  - Trennung: 1px `rgba(235,226,214,0.04)` zwischen Reihen

### 4. Kein Treffer (`state="empty"`)
- Suchfeld unverändert (zeigt Query)
- Großer Kreis (56×56) mit Lupen-Icon, neutral (text-3, kein Akzent)
- Headline „Nichts gefunden" (Newsreader 17, text)
- Subline „Keine Treffer für „{q}"" (text-3, 13 px)
- Zentriert, padding-top 56 px

## Komponenten

### `LibrarySearch({ state, q, activeTab, setActiveTab })`
Datei: `library-search.jsx`

Top-Level-Component. Rendert Phone-Frame mit StatusBar, Header, Suchfeld und je nach `state` den passenden Body-Bereich.

**Props:**
- `state`: `"idle" | "history" | "results" | "empty"` (default: `"idle"`)
- `q`: aktueller Suchstring (default: `""`)
- `activeTab` / `setActiveTab`: für die Tab-Bar (Bestandsschnittstelle)

### `HeaderS()`
Titel + zwei Icon-Buttons (Plus, Info). Bestehende `.icon-btn`-Klasse aus `styles.css`.

### `SearchBarS({ q, focused })`
- Container: `padding: 4 20 14`
- Pill: `background rgba(235,226,214,0.05)`, `border 1px`, radius 14
- Unfocused: Border `rgba(235,226,214,0.06)`
- Focused: Border `rgba(196,122,94,0.4)` + box-shadow `0 0 0 3px rgba(196,122,94,0.10)`
- Lupen-Icon links (16×16, text-3), Text-Bereich (flex 1), Clear-X rechts (nur wenn `q`)
- Caret (1.5×em) blinkt nur wenn `focused`

### `HistoryListS()`
Mock-Daten: `["Breath", "Slator", "Achtsamkeit", "R.A.I.N."]`. In Produktion: persistent in User-Defaults / Room / SwiftData, FIFO max 6 Einträge.

### `ResultsListS({ q })`
Filtert `TRACKS_S` nach Titel- oder Sprecher-Substring (case-insensitive). Rendert Card mit `TrackRowS`-Zeilen.

### `TrackRowS({ t, q })`
Eine Trefferzeile. Title + Author beide via `HighlightS` → Match-Span bekommt:
- `color: var(--sm-accent-text)`
- `background: rgba(196,122,94,0.14)`
- `border-radius: 3px`
- `padding: 0 1px`

### `EmptyResultS({ q })`
Zentrierter Block mit großem neutralem Lupen-Kreis + Headline + Subline.

### `HighlightS({ text, q })`
Findet `q` als case-insensitive Substring in `text`, splittet in vor/match/nach. Match-Span mit Akzent-Background.

## Interaktionen & Verhalten

| Trigger | Effekt |
|---|---|
| Tap Suchfeld | Feld bekommt Fokus → Tastatur erscheint → state geht auf `history` |
| Tippen | state wechselt auf `results` (oder `empty`) sobald `q.length > 0` |
| Tap Clear-X | `q` → `""`, state → `history` |
| Tap Historie-Eintrag | `q` wird gesetzt, state → `results`/`empty` |
| Tap „Leeren" in Historie | Historie geleert (mit Confirm-Dialog empfohlen) |
| Tap Treffer-Zeile | Öffnet den Player im Vollbild (gleicher Flow wie aus der Standard-Liste) |
| Long-Press Treffer | Öffnet Inline-Preview mit Waveform (gleiches Verhalten wie Standard) |
| Swipe-Left auf Treffer | Edit / Delete (gleiches Verhalten wie Standard) |
| Cancel / Tap außerhalb | Feld verliert Fokus, `q` → `""`, state → `idle` |

**Debouncing:** Trefferliste sollte ab 1 Zeichen rendern, ohne Debounce — die Dataset-Größe ist klein (≤200 Einträge in Produktion).

**Match-Reihenfolge:** Die aktuelle Implementation behält die Eingangsreihenfolge bei. Empfehlung für Produktion: Treffer mit Match am **Wort-Anfang** nach oben sortieren (Titel-Match priorisieren vor Autor-Match), danach Bibliotheks-Default-Sortierung.

## State Management

```ts
type LibrarySearchState = {
  query: string;              // Eingabe, Live-gebunden ans Feld
  focused: boolean;           // Feld hat Fokus
  history: string[];          // max 6, FIFO, persistent
};

// State maps to render state:
// query === "" && !focused           → "idle"
// query === "" && focused            → "history"
// query !== "" && filteredCount > 0  → "results"
// query !== "" && filteredCount === 0 → "empty"
```

## Design Tokens

Alle Werte sind CSS-Variablen aus `styles.css` — kein neuer Hex-Wert wurde eingeführt. Theme-Wechsel (Akzent: Kupfer/Salbei/Dämmerung) trifft die Suche automatisch.

### Match-Highlight
- Text-Farbe: `var(--sm-accent-text)` (`#d99a7e` bei Kupfer-Theme)
- Background: `rgba(196,122,94,0.14)` — fixe Hex-Tönung, weil semi-transparent über variable Card-Backgrounds
- Border-Radius: 3 px
- Padding: `0 1px`

### Suchfeld
| Stelle | Wert |
|---|---|
| Container padding | `4px 20px 14px` |
| Feld padding | `10px 14px` |
| Feld background | `rgba(235,226,214,0.05)` |
| Feld border (unfocused) | `1px solid rgba(235,226,214,0.06)`, radius 14 |
| Feld border (focused) | `1px solid rgba(196,122,94,0.4)` + box-shadow `0 0 0 3px rgba(196,122,94,0.10)` |
| Lupen-Icon | 16×16, `var(--sm-text-3)`, stroke-width 1.7 |
| Clear-X-Hintergrund | 18×18 Kreis, `rgba(235,226,214,0.12)` |
| Caret | 1.5px breit, `var(--sm-accent)`, `1.05s steps(2,start) infinite` |
| Placeholder | „Nach Titel oder Sprecher suchen", color `var(--sm-text-3)` |

### Empty-State-Lupe
- 56×56 Kreis, background `rgba(235,226,214,0.04)`, border `1px rgba(235,226,214,0.06)`
- Icon 22×22, color `var(--sm-text-3)`
- Margin-bottom 18 px zum Headline-Text

### Typografie

| Stelle | Family | Size | Weight |
|---|---|---|---|
| Page-Titel | Newsreader | 22 | 400 |
| Suchfeld-Text + Placeholder | Geist | 15 | 400 |
| „N Treffer" Eyebrow | Geist | 11 | 400, 0.08em uppercase |
| Treffer-Titel | Newsreader | 15 | 400 |
| Treffer-Subtitle | Geist | 12 | 400 |
| Historie-Eintrag | Geist | 15 | 400 |
| Empty-State-Headline | Newsreader | 17 | 400 |
| Empty-State-Subline | Geist | 13 | 400 |

## Accessibility

- Suchfeld: `role="searchbox"`, `aria-label="Bibliothek durchsuchen"`, `inputMode="search"`
- Clear-X: `aria-label="Suche leeren"`
- Historie-Einträge: `aria-label={\`Erneut suchen: \${term}\`}`
- Match-Highlight: Hintergrund hat ausreichend Kontrast zum Text; Screen-Reader liest den Text normal vor (kein extra Marker nötig — die Hervorhebung ist rein visuell informativ)
- Min Touch-Target: Trefferzeilen sind 60 px hoch (deutlich über 44 px), Suchfeld 44 px hoch
- **Empty-State** sollte `role="status"` tragen, damit Screen-Reader die Veränderung „Nichts gefunden" automatisch ansagt
- Reduced motion: Caret-Blink optional via `prefers-reduced-motion: reduce` deaktivieren

## SwiftUI-Implementation (empfohlen)

```swift
@State private var query = ""
@State private var history: [String] = UserDefaults.standard.searchHistory

NavigationStack {
  LibraryListView(query: query, history: history)
    .navigationTitle("Geführte Meditationen")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) { AddButton() }
      ToolbarItem(placement: .topBarTrailing) { InfoButton() }
    }
}
.searchable(
  text: $query,
  placement: .automatic,            // iOS-übergreifend, Apple wählt
  prompt: Text("Nach Titel oder Sprecher suchen")
)
.onSubmit(of: .search) {
  history.prepend(query, max: 6)
}
```

`LibraryListView` rendert je nach State:
- `query.isEmpty && !isSearching` → bestehende gruppierte Liste
- `query.isEmpty && isSearching` → `HistoryView(history)`
- `query.isNotEmpty && !filtered.isEmpty` → `ResultsView(filtered, query)` mit Highlight
- `query.isNotEmpty && filtered.isEmpty` → `EmptyView(query)`

## Dateien in diesem Bundle

| Datei | Inhalt |
|---|---|
| `Library Search.html` | Lauffähiger Prototyp — alle 5 States nebeneinander |
| `library-search.jsx` | `LibrarySearch`-Component + alle Sub-Components |
| `shell.jsx` | `StatusBar`, `TabBar`, `Phone`-Wrapper, Icon-Set (unverändert) |
| `styles.css` | Design-Tokens und Basis-Klassen (unverändert) |

## Out of Scope dieses Handoffs

- **Voice-Search** (Mikrofon-Icon im Feld) — bewusst weggelassen, kann später folgen
- **Spell-Correction** / Fuzzy-Match — aktuell exaktes Substring
- **Suche über Tags** (Achtsamkeit, Schlaf, ...) — wenn Tags später hinzukommen, könnten sie als zusätzliche Match-Quelle dienen oder als Filter-Chips über dem Feld
- **Globale Suche** (über mehrere Tabs hinweg) — Suche ist scoped auf den Bibliotheks-Tab
- **Suche in Sammlungen** (Collections) — separate Story, sobald Sammlungen produktiv sind

## Implementations-Hinweise

1. **Persistente Historie:** FIFO, max 6 Einträge, in `UserDefaults` (iOS) bzw. `SharedPreferences`/Room (Android). Duplikate werden nach oben gehoben statt verdoppelt. Suchen mit 0 Treffern **nicht** in die Historie schreiben.
2. **Highlight-Implementation:** Bei nativen Strings empfiehlt sich `AttributedString` mit Range-basiertem Foreground/Background statt String-Splitting. Match-Range darf nicht auf Mehrfach-Matches im selben Text reduziert sein — alle Vorkommen hervorheben.
3. **Match-Priorisierung in Produktion:** (a) Wort-Anfangs-Match in Titel, (b) Wort-Anfangs-Match in Author, (c) Substring im Titel, (d) Substring im Author. Aktuelle Mock-Implementation macht das nicht — bitte ergänzen.
4. **Performance:** Bei großen Bibliotheken (>500 Einträge) Filterung in einem Background-Queue / async Task, sonst tippt das Feld ruckartig. Volltext-Index optional via SQLite FTS.
5. **Keyboard-Dismiss:** Wenn der Nutzer in der Trefferliste scrollt, Tastatur einklappen (`.scrollDismissesKeyboard(.immediately)` in SwiftUI).
6. **Cancel-Verhalten:** „Cancel"/„Abbrechen"-Button rechts neben dem Feld erscheint von SwiftUI automatisch sobald `.searchable` aktiv ist — nicht nachbauen.
