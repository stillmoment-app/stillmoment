# Research Agents - Konzeptdokument

## Zusammenfassung

Zwei spezialisierte Agents für Claude Code, die bei Entwicklungsaufgaben automatisch relevantes Wissen recherchieren und komprimiert bereitstellen:

1. **Documentation Research Agent** - Durchsucht Dokumentation + Web
2. **Code Research Agent** - Durchsucht bestehenden Code nach Patterns

Beide Agents lösen das gleiche Kernproblem: **Relevantes Wissen finden und komprimiert in den Kontext bringen**, ohne Token-Explosion.

### Warum Agent statt Skill?

| Aspekt | Skill | Agent |
|--------|-------|-------|
| Kontext | Alles landet im Hauptkontext | Eigener Kontext, nur Output zurück |
| Token-Effizienz | Niedrig (alles geladen) | Hoch (komprimiert) |
| Suchtiefe | Begrenzt durch Kontext | Kann umfangreich suchen |

### Halluzinations-Reduktion

Beide Agents reduzieren Halluzinationen erheblich:
- **Code Agent:** Code ist Ground Truth - keine erfundenen APIs
- **Doc Agent:** Web-Recherche validiert API-Signaturen und Konfigurationen

---

# Teil 1: Documentation Research Agent

## Problem

- Entwickler muss manuell entscheiden, welche Doku relevant ist
- Web-Recherche unterbricht den Entwicklungsflow
- Wissen aus verschiedenen Quellen muss mental zusammengeführt werden
- Kontext-Limits machen es unpraktisch, "alles" zu laden

## Lösung

Ein Agent mit **eigenem Kontext**, der:
1. Lokale Dokumentation durchsucht (dev-docs/, ADRs, CLAUDE.md)
2. Web-Recherche durchführt (Docs, Blogs, Best Practices)
3. Ergebnisse **komprimiert und priorisiert**
4. Nur relevantes Wissen in den Hauptkontext zurückgibt

## Architektur

```
┌─────────────────────────────────────────────────────────┐
│                    Hauptkontext                         │
│  ┌───────────────┐                                      │
│  │ User Request  │                                      │
│  └───────┬───────┘                                      │
│          │                                              │
│          ▼                                              │
│  ┌───────────────┐    ┌────────────────────────────┐   │
│  │ Research      │───▶│ Agent Kontext (isoliert)   │   │
│  │ Agent Call    │    │                            │   │
│  └───────────────┘    │  Phase 1: Lokal            │   │
│          ▲            │  ├─ Glob: dev-docs/**/*.md │   │
│          │            │  ├─ Read: relevante Docs   │   │
│          │            │  └─ Read: ADRs             │   │
│          │            │                            │   │
│          │            │  Phase 2: Web              │   │
│          │            │  ├─ WebSearch              │   │
│          │            │  ├─ WebFetch: Offiz. Docs  │   │
│          │            │  └─ WebFetch: Best Practice│   │
│          │            │                            │   │
│          │            │  Phase 3: Synthese         │   │
│          │            │  └─ Komprimierung          │   │
│          │            └────────────┬───────────────┘   │
│          │                         │                    │
│          │            ┌────────────▼───────────────┐   │
│          └────────────│ Komprimiertes Ergebnis    │   │
│                       │ (~50-100 Zeilen)          │   │
│                       └────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Recherche-Strategie

### Phase 1: Lokale Dokumentation (immer)

**Priorität 1 - Projekt-spezifisch:**
- `CLAUDE.md` - Kern-Regeln
- `dev-docs/architecture/` - Architektur-Entscheidungen
- `dev-docs/architecture/decisions/` - ADRs
- `dev-docs/reference/glossary.md` - Ubiquitous Language

**Priorität 2 - Guides:**
- `dev-docs/guides/` - Implementierungs-Anleitungen

### Phase 2: Web-Recherche (bei Bedarf)

**Wann aktiviert:**
- Externe APIs/Frameworks involviert
- Best Practices gefragt
- Problemlösung (Errors, Edge Cases)
- Explizit angefordert

**Quellen-Hierarchie:**
1. Offizielle Dokumentation (Apple, Google, Framework-Docs)
2. GitHub Repositories (Issues, Discussions)
3. Etablierte Blogs (NSHipster, SwiftLee, etc.)
4. Stack Overflow (mit Vorsicht, Datum prüfen)

**Suchstrategie:**
- Jahr immer inkludieren: "SwiftUI NavigationStack 2026"
- Mehrere Quellen für Validierung
- Aktualität prüfen (Deprecation-Warnungen)

### Phase 3: Synthese

**Priorisierung:**
1. Interne Entscheidungen > Externe Best Practices
2. Offizielle Docs > Community-Wissen
3. Aktuell > Veraltet

**Output-Format:**
```markdown
## Research: [Thema]

### Interne Standards
- [Komprimierte Erkenntnisse aus lokaler Doku]
- Referenz: `datei.md:zeile`

### Externe Best Practices
- [Relevante Erkenntnisse aus Web]
- Quelle: [URL]

### Empfehlung
- [Synthesierte Handlungsempfehlung]

### Potenzielle Pitfalls
- [Bekannte Probleme/Risiken]
```

## Anwendungsfälle

| Use Case | Input | Output |
|----------|-------|--------|
| Feature-Impl. | "Interval-Gongs im Timer" | Interne Audio-Architektur + AVAudioSession Best Practices |
| Problemlösung | "Audio stoppt bei Screen Lock" | AudioSessionCoordinator Doku + Apple Docs + Community-Lösungen |
| Architektur | "Combine vs AsyncStream" | Bestehende Patterns + Vergleichsartikel |
| Neue Tech | "WidgetKit Integration" | Apple Guide + Design Guidelines + Community-Erfahrungen |

---

# Teil 2: Code Research Agent

## Problem

- Bei großen Projekten ist unklar, wo relevanter Code liegt
- Ähnliche Implementierungen existieren, werden aber nicht gefunden
- Interfaces und Protokolle müssen manuell gesucht werden
- Bestehende Patterns werden ignoriert → Inkonsistenzen

### Besonders relevant bei
- **Fremden Codebases** - Onboarding, Open Source Contributions
- **Gewachsenen Projekten** - Viele Module, historische Entscheidungen
- **Team-Arbeit** - Code von anderen Entwicklern verstehen
- **Refactoring** - Alle betroffenen Stellen finden

## Lösung

Ein Agent mit **eigenem Kontext**, der:
1. Bestehenden Code nach relevanten Patterns durchsucht
2. Ähnliche Implementierungen identifiziert
3. Interfaces/Protokolle findet die genutzt werden müssen
4. **Komprimierte Code-Referenzen** zurückgibt

### Unterschied zu Explore Agent

| Aspekt | Explore Agent | Code Research Agent |
|--------|---------------|---------------------|
| Fokus | Codebase verstehen | Relevanten Code für Aufgabe finden |
| Output | Beschreibung der Struktur | Konkrete Code-Referenzen |
| Tiefe | Überblick | Spezifische Patterns |
| Komprimierung | Moderat | Hoch (nur relevante Snippets) |

## Architektur

```
┌─────────────────────────────────────────────────────────┐
│                    Hauptkontext                         │
│  ┌───────────────┐                                      │
│  │ User Request  │                                      │
│  └───────┬───────┘                                      │
│          │                                              │
│          ▼                                              │
│  ┌───────────────┐    ┌────────────────────────────┐   │
│  │ Code Research │───▶│ Agent Kontext (isoliert)   │   │
│  │ Agent Call    │    │                            │   │
│  └───────────────┘    │  Phase 1: Pattern-Suche    │   │
│          ▲            │  ├─ Grep: Keywords         │   │
│          │            │  ├─ Glob: Naming Patterns  │   │
│          │            │  └─ Read: Beispiel-Code    │   │
│          │            │                            │   │
│          │            │  Phase 2: Interface-Suche  │   │
│          │            │  ├─ Grep: protocol/interface│  │
│          │            │  └─ Read: Relevante Protos │   │
│          │            │                            │   │
│          │            │  Phase 3: Dependency-Scan  │   │
│          │            │  ├─ Import-Analyse         │   │
│          │            │  └─ Injection-Patterns     │   │
│          │            │                            │   │
│          │            │  Phase 4: Komprimierung    │   │
│          │            │  └─ Nur relevante Snippets │   │
│          │            └────────────┬───────────────┘   │
│          │                         │                    │
│          │            ┌────────────▼───────────────┐   │
│          └────────────│ Komprimiertes Ergebnis    │   │
│                       │ - Pattern-Beispiele       │   │
│                       │ - Interface-Signaturen    │   │
│                       │ - Dependency-Hinweise     │   │
│                       └────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Recherche-Strategie

### Phase 1: Pattern-Suche

**Ziel:** Ähnliche Implementierungen finden

```
Aufgabe: "Neuen ViewModel für Settings"
→ Suche: *ViewModel.swift, *ViewModel.kt
→ Finde: TimerViewModel, LibraryViewModel
→ Analysiere: Gemeinsame Patterns, Base-Classes
```

**Suchstrategien:**
- Naming Conventions (`*ViewModel`, `*Service`, `*Repository`)
- Strukturelle Suche (Klassen die Protocol X implementieren)
- Ähnliche Imports

### Phase 2: Interface-Suche

**Ziel:** Relevante Protokolle/Interfaces identifizieren

```
Aufgabe: "Audio-Feature implementieren"
→ Suche: protocol.*Audio, interface.*Audio
→ Finde: AudioPlayable, AudioSessionDelegate
→ Extrahiere: Signaturen, Required Methods
```

### Phase 3: Dependency-Scan

**Ziel:** Verstehen was injiziert/genutzt werden muss

```
Aufgabe: "Neuen Service erstellen"
→ Analysiere: Bestehende Services
→ Finde: Injection-Pattern (Constructor, @Inject)
→ Identifiziere: Gemeinsame Dependencies
```

### Phase 4: Komprimierung

**Output-Format:**
```markdown
## Code Research: [Aufgabe]

### Relevante Patterns
// Aus: TimerViewModel.swift:15-45
// Pattern: ViewModel mit Combine Publisher
class TimerViewModel: ObservableObject {
    @Published var state: TimerState
    private var cancellables = Set<AnyCancellable>()
    init(timerService: TimerServiceProtocol) { ... }
}

### Zu implementierende Interfaces
// Aus: Protocols/ViewModelProtocol.swift:8-12
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    var state: State { get }
}

### Benötigte Dependencies
- `TimerServiceProtocol` - via Constructor Injection
- `Logger` - via `Logger.viewModel`

### Projektkonventionen
- ViewModels sind `@MainActor`
- State ist immutable struct
- Effects via `[weak self]` Closures
```

## Anwendungsfälle

| Use Case | Input | Output |
|----------|-------|--------|
| Neues Feature | "Wie implementiere ich einen ViewModel?" | Beispiel-VM + Protocols + Injection-Muster |
| Interface verstehen | "AudioPlayer Methoden?" | Protocol-Definition + bestehende Impl. |
| Refactoring | "Wo wird TimerService genutzt?" | Import-Stellen + Methodenaufrufe + Abhängigkeitsgraph |
| Bug-Kontext | "Timer Datenfluss?" | Entry Points + Service-Aufrufe + State-Mutationen |
| Konsistenz | "Error-Handling Patterns?" | try/catch Patterns + Error-Types + Logging |

---

# Teil 3: Synergie beider Agents

## Kombinierte Nutzung

```
User: "Implementiere Background Audio"

1. /research → Doku + Best Practices (wie SOLLTE es sein)
2. /research-code → Bestehende Patterns (wie IST es im Projekt)
3. Synthese → Implementierung die beides berücksichtigt
```

## Optionaler kombinierter Agent

```
/research-all "Background Audio"
→ Phase 1: Interne Doku
→ Phase 2: Bestehender Code
→ Phase 3: Web Best Practices
→ Output: Vollständiges Briefing
```

## Vergleich

| Aspekt | Doc Research | Code Research |
|--------|--------------|---------------|
| Primärquelle | dev-docs/, Web | Source Code |
| Output-Typ | Prosa, Guidelines | Code-Snippets |
| Halluzinations-Risiko | Mittel (Web) | Niedrig (Ground Truth) |
| Aktualität | Kann veraltet sein | Immer aktuell |
| Use Case | "Wie sollte ich?" | "Wie wurde es gemacht?" |

---

# Teil 4: Implementierung

## Empfohlener Ansatz: Custom Skills

### `/research` - Documentation Research Agent

```
Datei: .claude/commands/research.md
Aufruf: /research <thema oder frage>

Beispiele:
- /research Background Audio iOS
- /research Combine vs AsyncStream
- /research Timer State Management
```

### `/research-code` - Code Research Agent

```
Datei: .claude/commands/research-code.md
Aufruf: /research-code <was du implementieren/verstehen willst>

Beispiele:
- /research-code neuen ViewModel erstellen
- /research-code AudioPlayer Interface
- /research-code Error Handling Patterns
```

## Technische Umsetzung

Skills starten via Task Tool einen Agent mit eigenem Kontext:
- `subagent_type: "general-purpose"` (hat Zugriff auf alle Tools inkl. WebSearch)
- Detaillierter Prompt mit Recherche-Anweisungen
- Agent komprimiert Ergebnisse bevor er sie zurückgibt

---

# Teil 5: Risiken und Erfolgskriterien

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Veraltete Web-Infos | Jahr in Suche, mehrere Quellen |
| Irrelevante Ergebnisse | Klare Priorisierung, User kann nachfragen |
| Zu viel Code gefunden | Strikte Relevanz-Filter |
| Veraltete Patterns im Code | Mit Doku-Agent kombinieren |
| Token-Kosten | Agent komprimiert, On-Demand |

## Erfolgskriterien

**Documentation Agent:**
- Relevanz: >80% der Ergebnisse sind nützlich
- Komprimierung: <100 Zeilen Output
- Konsistenz: Interne Standards nie überschrieben

**Code Agent:**
- Relevanz: Gefundene Patterns direkt anwendbar
- Vollständigkeit: Alle relevanten Interfaces gefunden
- Korrektheit: Code-Referenzen stimmen (Datei:Zeile)

---

## Offene Fragen

- [ ] Sollen beide Agents immer zusammen laufen?
- [ ] Maximale Code-Snippet-Länge?
- [ ] Soll Code-Agent auch Tests durchsuchen?
- [ ] Priorisierung: Doku vs. Code bei Widersprüchen?
- [ ] Caching sinnvoll für häufige Patterns?
- [ ] Integration mit bestehenden Skills (z.B. /review-code)?
