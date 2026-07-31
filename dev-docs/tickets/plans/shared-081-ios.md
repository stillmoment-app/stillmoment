# Implementierungsplan: shared-081 (iOS)

Ticket: [shared-081](../shared/shared-081-library-filter-nach-dauer.md)
Erstellt: 2026-07-31

## Annahmen

- **Gefiltert wird die effektive Dauer** (`GuidedMeditation.effectiveDuration`, also mit Trim), nicht die Dateilänge. Das ist die Zahl, die in der Liste steht und die der User tatsächlich meditiert. Eine 40-Minuten-Datei, auf 12 Minuten getrimmt, liegt in `5–15 Min`.
- **„Suchmodus" = Suchfeld fokussiert ODER Suchtext vorhanden.** Das Ticket sagt „sobald das Suchfeld den Fokus hat", aber `SearchResultsListView` setzt bereits `.scrollDismissesKeyboard(.immediately)` — beim Scrollen in der Trefferliste verliert das Feld den Fokus. Bei wörtlicher Umsetzung spränge dort die volle Filterzeile zurück, während Android (nur `keyboard?.hide()`, Fokus bleibt) den Chip behielte. Der Chip ist laut Ticket die Erklärung, *warum* eine Meditation fehlt — die bleibt nötig, solange ein Suchtext wirkt.
- **Reihenfolge der flachen Liste ohne Suchtext:** die heutige gruppierte Reihenfolge, nur ohne Überschriften (`meditationsByTeacher().flatMap(\.meditations)` — Lehrer:in alphabetisch, innerhalb der Gruppe nach Titel; das sortiert bereits `GuidedMeditationService.sortedMeditations()`). Keine neue Sortierung — die schliesst das Ticket aus. Mit Suchtext bleibt die Relevanz-Rangfolge der `LibrarySearchEngine`.
- **Der Reset-Button im „Kein Treffer"-Zustand erscheint nur bei gesetztem Filter.** Ohne Filter bleibt der heutige reine Such-Empty-State unverändert (kein neuer Button, wo bisher keiner war).
- **`Alle` ist nie blass.** Die Filterzeile erscheint ohnehin nur bei nicht-leerer Bibliothek, also gibt es immer mindestens eine Meditation.
- **Ein bereits gewählter Schritt bleibt gewählt, auch wenn er durch einen Suchtext leer wird.** Ergebnis ist dann der „Kein Treffer"-Zustand, der beide Ursachen nennt — genau der im Ticket beschriebene Fall.
- **Die Filterzeile gehört zum fixierten Header** (`.safeAreaInset(edge: .top)`), scrollt also nicht mit. Sie sitzt unmittelbar unter der Such-Pille, wie im Mockup.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Models/DurationFilter.swift` | Domain | **Neu** | Enum mit den fünf Stufen, `matches(_:)`, `apply(to:)`, `availableSteps(in:)`. Reines Swift, Grenzen in Sekunden. |
| `Domain/Services/LibrarySearchState.swift` | Domain | Erweitern | Neuer Case `filtered` (kein Suchtext, aber Filter gesetzt → flache Liste). Doc-Kommentar anpassen. |
| `Application/ViewModels/GuidedMeditationsListViewModel.swift` | Application | Erweitern | `@Published durationFilter`; abgeleitete `visibleMeditations`, `availableDurationSteps`, `isFilterActive`, `isSearchModeActive`; `searchState` um Filter erweitern; `selectDurationFilter(_:)`, `resetDurationFilter()`, `resetSearchAndFilter()`. `resetSearch()` bleibt filterfrei. |
| `Presentation/Views/GuidedMeditations/LibraryDurationFilterRow.swift` | Presentation | **Neu** | Horizontal scrollbare Stufenzeile + `private struct DurationFilterChip`. |
| `Presentation/Views/GuidedMeditations/LibraryActiveFilterChip.swift` | Presentation | **Neu** | Einzelner Chip mit ✕ für den Suchmodus. |
| `Presentation/Views/GuidedMeditations/DurationFilter+Title.swift` | Presentation | **Neu** | Lokalisierungs-Keys pro Stufe (hält das Domain-Modell frei von Text). |
| `Presentation/Views/GuidedMeditations/LibraryHeaderView.swift` | Presentation | Erweitern | Aus `HStack` wird `VStack { HStack{Suche+Aktion}; Filterzeile ODER Chip ODER nichts }`. |
| `Presentation/Views/GuidedMeditations/LibrarySearchContentView.swift` | Presentation | Erweitern | `case .filtered, .results:` → flache Liste aus `visibleMeditations`; `.empty` bekommt Filter + Reset-Callback. |
| `Presentation/Views/GuidedMeditations/SearchResultsListView.swift` | Presentation | Erweitern | Neuer Parameter `totalCount`; Zählzeile auf den neuen Plural-Key. |
| `Presentation/Views/GuidedMeditations/SearchEmptyStateView.swift` | Presentation | Erweitern | Neue Parameter `activeFilter: DurationFilter?`, `onReset: (() -> Void)?`; drei Textvarianten + Reset-Button. |
| `StillMomentApp.swift` | App | Erweitern | Im bestehenden `.onChange(of: selectedTab)` zusätzlich `resetDurationFilter()`. Einziger Reset-Punkt für den Filter. |
| `Resources/{de,en}.lproj/Localizable.strings` | Resources | Erweitern | Stufen-Labels, Empty-Texte, Reset-Button, Accessibility. Alten Key `library.search.results.count` entfernen. |
| `Resources/{de,en}.lproj/Localizable.stringsdict` | Resources | Erweitern | Neuer Plural-Eintrag für die Zählzeile (zwei Argumente). |
| `StillMomentTests/Domain/DurationFilterTests.swift` | Test | **Neu** | Grenzwerte + Stufen-Belegung. |
| `StillMomentTests/LibraryDurationFilterViewModelTests.swift` | Test | **Neu** | Zusammenspiel Suche/Filter, Zustände, Reset-Semantik. |
| `CHANGELOG.md` | Docs | Erweitern | Eintrag unter Unreleased. |

## API-Recherche

Keine neuen Framework-APIs. Alles SwiftUI-Bordmittel, die im Projekt bereits im Einsatz sind:

| API | Min. Version | Bereits genutzt in | Hinweis |
|-----|--------------|--------------------|---------|
| `ScrollView(.horizontal, showsIndicators: false)` | iOS 13+ | — | Fünf feste Chips, kein `LazyHStack` nötig. |
| `.accessibilityAddTraits(.isSelected)` | iOS 14+ | — | Screenreader sagt „ausgewählt". |
| `.disabled(true)` | iOS 13+ | projektweit | VoiceOver sagt zusätzlich „abgeblendet"; wir ergänzen einen expliziten `accessibilityValue`. |
| `.stringsdict`-Plural mit zwei Argumenten | iOS 7+ | `praxis.intervalGongs.*` | Plural richtet sich nach dem **zweiten** Wert (Gesamtbestand). |

## Design-Entscheidungen

### 1. `DurationFilter` als Enum mit eigener Logik statt neuem Domain-Service

**Trade-off:** Ein `LibraryDurationFilterEngine` analog zur `LibrarySearchEngine` wäre symmetrisch. Aber die Suche braucht Tokenisierung, Ranking und Highlight-Ranges — der Dauerfilter ist ein Bereichsvergleich.
**Entscheidung:** `matches(_:)`, `apply(to:)` und `availableSteps(in:)` leben am Enum. Keine neue Datei im Service-Ordner, kein Protokoll, keine Injektion. Wenn der Filter je um weitere Dimensionen wächst, ist die Extraktion trivial.

### 2. Fünfter Case `filtered` statt Umbenennung des Zustandsmodells

**Trade-off:** Sauberer wäre `LibraryBodyState { grouped, flat, history, empty }` — vier Zustände, kein doppelter Render-Pfad. Das kostet aber eine Umbenennung über beide Plattformen inklusive Tests, ohne dass ein Akzeptanzkriterium sie verlangt.
**Entscheidung:** Additiver Case `filtered`. `LibrarySearchContentView` fasst `case .filtered, .results:` in einem Zweig zusammen — eine Zeile. Der Doc-Kommentar des Enums beschreibt bereits „welche Ansicht die Library aktuell rendert", passt also weiter. Umbenennung als möglicher Aufräum-Follow-up notiert, nicht Teil dieses Tickets.

### 3. Filter-Reset ausschliesslich am Tab-Wechsel, nicht in `onDisappear`

**Trade-off:** Die Suche wird heute in `GuidedMeditationsListView.onDisappear` zurückgesetzt — das feuert auch beim Push in den Player. Für den Filter wäre genau das der im Ticket beschriebene Ärger.
**Entscheidung:** Der Filter wird **nur** in `StillMomentApp.onChange(of: selectedTab)` zurückgesetzt, wo bereits `resetSearch()` steht. `onDisappear` bleibt unverändert. Damit überlebt der Filter den Player-Ausflug automatisch, ohne dass irgendwo zwischen Player-Navigation und Tab-Wechsel unterschieden werden muss.

### 4. Stufen-Belegung gegen die *such*-gefilterte Menge, nicht gegen die gefilterte

**Entscheidung:** `availableDurationSteps` wird aus der Menge berechnet, auf die nur der Suchtext wirkt — nicht aus `visibleMeditations`. Sonst würde das Setzen einer Stufe alle anderen blass schalten und der Filter wäre eine Einbahnstrasse.

## Fachliche Szenarien

### AK-1: Dauer-Stufen und Grenzwerte

- Gegeben: Meditationen mit 4:59, 5:00, 14:59, 15:00, 29:59, 30:00
  Wenn: `bis 5 Min` gewählt
  Dann: nur die 4:59-Meditation erscheint
- Gegeben: dieselbe Bibliothek
  Wenn: `5–15 Min` gewählt
  Dann: 5:00 und 14:59 erscheinen, 15:00 nicht
- Gegeben: dieselbe Bibliothek
  Wenn: `15–30 Min` gewählt
  Dann: 15:00 und 29:59 erscheinen
- Gegeben: dieselbe Bibliothek
  Wenn: `über 30 Min` gewählt
  Dann: 30:00 erscheint
- Gegeben: Eine Meditation von 42:00, per Trim auf 12:00 gekürzt
  Wenn: `5–15 Min` gewählt
  Dann: sie erscheint (die Liste zeigt 12:00, der Filter folgt der Anzeige)

### AK-2: Einzelauswahl und Rücksprung auf `Alle`

- Gegeben: `Alle` ist aktiv
  Wenn: `5–15 Min` antippen
  Dann: `5–15 Min` ist aktiv, `Alle` nicht mehr, die Liste ist flach
- Gegeben: `5–15 Min` ist aktiv
  Wenn: `5–15 Min` erneut antippen
  Dann: `Alle` ist aktiv, die Liste ist wieder nach Lehrer:in gruppiert
- Gegeben: `5–15 Min` ist aktiv
  Wenn: `über 30 Min` antippen
  Dann: nur `über 30 Min` ist aktiv

### AK-3: Blasse Stufen

- Gegeben: Bibliothek ohne Meditation unter 5 Minuten
  Wenn: nichts
  Dann: `bis 5 Min` ist blass und reagiert nicht auf Antippen; der aktive Filter bleibt unverändert
- Gegeben: Bibliothek mit Meditationen in allen Stufen, Suchtext trifft nur eine 7-Minuten-Meditation
  Wenn: nichts
  Dann: nur `5–15 Min` ist verfügbar, die übrigen Stufen sind blass — aber alle fünf bleiben sichtbar
- Gegeben: leere Bibliothek
  Wenn: nichts
  Dann: es erscheint weder Header noch Filterzeile, der bestehende Empty State steht unverändert

### AK-4: Zählzeile

- Gegeben: 7 Meditationen, davon 2 zwischen 5 und 15 Minuten
  Wenn: `5–15 Min` gewählt
  Dann: über der flachen Liste steht „2 von 7 Meditationen"
- Gegeben: 7 Meditationen, Suchtext trifft 1 davon, kein Filter
  Wenn: nichts
  Dann: dieselbe Zeile im Format „1 von 7 Meditationen" — die alte Zeile „1 Treffer" existiert nicht mehr
- Gegeben: Bibliothek mit genau 1 Meditation, die zum Filter passt
  Wenn: nichts
  Dann: „1 von 1 Meditation" — grammatisch korrekt, Einzahl
- Gegeben: kein Filter und kein Suchtext
  Wenn: nichts
  Dann: keine Zählzeile, die Liste bleibt nach Lehrer:in gruppiert

### AK-5: Zusammenspiel mit der Suche

- Gegeben: `5–15 Min` gesetzt, Suchfeld nicht fokussiert
  Wenn: ins Suchfeld tippen
  Dann: die vollständige Filterzeile weicht, ein Chip „5–15 Min ✕" bleibt stehen
- Gegeben: `Alle` aktiv
  Wenn: ins Suchfeld tippen
  Dann: kein Chip; die Liste beginnt direkt unter der Such-Pille
- Gegeben: `5–15 Min` gesetzt, Suchfeld fokussiert und leer
  Wenn: nichts
  Dann: Suchhistorie sichtbar, Chip steht darüber
- Gegeben: `5–15 Min` gesetzt, Suchtext „b", der auch auf eine 25-Minuten-Meditation passt
  Wenn: nichts
  Dann: die 25-Minuten-Meditation fehlt in der Liste
- Gegeben: derselbe Zustand
  Wenn: den Chip antippen
  Dann: der Filter ist weg, die 25-Minuten-Meditation erscheint, die Suche bleibt bestehen
- Gegeben: `5–15 Min` gesetzt, Suchtext „b"
  Wenn: „Abbrechen" antippen
  Dann: Suchtext leer, Filter weiterhin `5–15 Min`, die vollständige Filterzeile ist zurück

### AK-6: Lebensdauer des Filters

- Gegeben: `bis 5 Min` gesetzt
  Wenn: eine Meditation im Player öffnen und zurückgehen
  Dann: `bis 5 Min` ist weiterhin gesetzt (die Suche wird dabei wie bisher zurückgesetzt)
- Gegeben: `bis 5 Min` gesetzt
  Wenn: zum Timer-Tab wechseln und zurückkommen
  Dann: `Alle` ist aktiv, die Liste ist gruppiert

### AK-7: Kein Treffer

- Gegeben: `über 30 Min` gesetzt, Suchtext „b" trifft nur kurze Meditationen
  Wenn: nichts
  Dann: „Nichts gefunden" mit einem Text, der sowohl „b" als auch „über 30 Min" nennt
- Gegeben: `über 30 Min` gesetzt, kein Suchtext, keine Meditation dieser Länge
  Wenn: nichts
  Dann: „Nichts gefunden" mit einem Text, der „über 30 Min" nennt
- Gegeben: einer der beiden Fälle
  Wenn: „Filter zurücksetzen" antippen
  Dann: Suchtext und Filter sind gemeinsam weg, die gruppierte Liste steht wieder
- Gegeben: Suchtext ohne Treffer, **kein** Filter
  Wenn: nichts
  Dann: der heutige Empty State unverändert — kein Reset-Button

### AK-8: Accessibility

- Gegeben: VoiceOver aktiv, `5–15 Min` gewählt
  Wenn: über die Stufe wischen
  Dann: Name und „ausgewählt" werden angesagt
- Gegeben: VoiceOver aktiv, `bis 5 Min` blass
  Wenn: über die Stufe wischen
  Dann: sie wird als nicht verfügbar angesagt
- Gegeben: VoiceOver aktiv, Chip im Suchmodus
  Wenn: über den Chip wischen
  Dann: angesagt wird, dass Antippen den Filter entfernt
- Gegeben: beliebiger Zustand
  Wenn: nichts
  Dann: jede Stufe und der Chip messen mindestens 44×44 pt

## Reihenfolge der Akzeptanzkriterien

Von innen nach aussen — jede Stufe ist testbar, bevor die nächste sie braucht:

1. **AK-1 (Grenzwerte)** — `DurationFilter` im Domain. Reine Funktion, schnellster Red-Green-Zyklus, Grundlage für alles Weitere.
2. **AK-3 (Stufen-Belegung)** — `availableSteps(in:)`, ebenfalls Domain.
3. **AK-2 + AK-5 + AK-6 (Zustandslogik)** — ViewModel: `durationFilter`, `visibleMeditations`, `searchState` mit `filtered`, Toggle- und Reset-Semantik. Hier liegt der eigentliche Kern des Tickets; alle Unit-Tests der Ticket-Liste hängen an diesem Schritt.
4. **AK-4 (Zählzeile)** — `stringsdict` + `SearchResultsListView`. Braucht `visibleMeditations` aus Schritt 3.
5. **AK-7 (Kein Treffer)** — `SearchEmptyStateView` mit den drei Textvarianten und dem Reset-Button.
6. **AK-2/AK-3 visuell + AK-8** — `LibraryDurationFilterRow`, `LibraryActiveFilterChip`, Einbau in `LibraryHeaderView`, Accessibility-Attribute.
7. **Tab-Reset** — eine Zeile in `StillMomentApp`, zuletzt, weil sie nur den in Schritt 3 gebauten Reset aufruft.
8. **CHANGELOG**

## Lokalisierung

| Key | DE | EN | Ort |
|-----|----|----|-----|
| `library.filter.all` | Alle | All | strings |
| `library.filter.upTo5` | bis 5 Min | Up to 5 min | strings |
| `library.filter.5to15` | 5–15 Min | 5–15 min | strings |
| `library.filter.15to30` | 15–30 Min | 15–30 min | strings |
| `library.filter.over30` | über 30 Min | Over 30 min | strings |
| `library.list.countOfTotal` | %1$d von %2$d Meditation(en) | %1$d of %2$d meditation(s) | **stringsdict**, Plural am 2. Wert |
| `library.filter.empty.message` | Keine Meditation mit der Dauer „%@". | No meditation with duration “%@”. | strings |
| `library.searchFilter.empty.message` | Keine Treffer für „%1$@" mit der Dauer „%2$@". | No matches for “%1$@” with duration “%2$@”. | strings |
| `library.filter.reset` | Filter zurücksetzen | Reset filter | strings |
| `accessibility.library.filter.unavailable` | Nicht verfügbar | Unavailable | strings |
| `accessibility.library.filter.chip.hint` | Antippen entfernt den Filter | Tap to remove the filter | strings |

**Entfällt:** `library.search.results.count` („%d Treffer") in beiden `.strings` — ersetzt durch `library.list.countOfTotal`. Ein zweiter Key daneben würde Suche und Filter auseinanderdriften lassen (Ticket-Hinweis).

Der neue Plural-Eintrag geht in eine **bestehende** `.stringsdict` — der Clean-Build-Fallstrick bei neuen Dateitypen in synchronized Groups greift hier nicht.

## Design-Tokens

| Zustand | Füllung | Text | Rand |
|---------|---------|------|------|
| Stufe aktiv | `theme.accentBubbleBackground` | `theme.interactive` | `theme.interactive` @ 0.28 |
| Stufe inaktiv | `theme.cardBackground` | `theme.textSecondary` | `theme.cardBorder` |
| Stufe blass | wie inaktiv, Gesamt-Opacity ~0.4 | — | — |
| Chip (Suchmodus) | wie „aktiv", zusätzlich ✕-Glyph in `theme.interactive` | | |

Form: `Capsule()`, Höhe 32 pt mit `.frame(minHeight: 44)` als Trefferfläche — analog zur bestehenden Such-Pille (40 pt sichtbar, 44 pt tappbar). Keine direkten Farbwerte.

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `LibraryHeaderView` wächst über die 400-Zeilen-Warnung | Chips und Zeile liegen in eigenen Dateien; der Header bekommt nur den `VStack`-Wrapper (~30 Zeilen). Aktuell 147 Zeilen. |
| Umbenennung von `library.search.results.count` bricht `validate-localization` | Das Skript prüft nur Key-Parität und Platzhalter zwischen DE und EN in den `.strings`. Key in **beiden** Sprachen entfernen und in **beiden** `.stringsdict` anlegen. |
| `searchState` wird komplexer und schwer zu lesen | Als kleine, benannte Hilfsproperties (`isFilterActive`, `isSearchModeActive`, `hasQuery`) formulieren statt als verschachtelte Bedingung — sonst reisst `cyclomatic_complexity` (Warnung bei 10). |
| Layout-Sprung beim Wechsel Filterzeile ↔ Chip | Beide Varianten auf dieselbe Höhe legen, damit die Liste nicht springt. Ohne Filter im Suchmodus ist das Verschwinden gewollt („Trefferliste erhält die volle Höhe"). |

## Offene Fragen

- Keine. Die beiden Mehrdeutigkeiten (Suchmodus-Definition, Sortierung der flachen Liste) sind oben unter **Annahmen** entschieden und im Review kippbar.
