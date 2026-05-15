---
name: plan-ticket
description: Erstellt einen Implementierungsplan fuer ein Ticket. Analysiert relevante Codestellen, recherchiert externe APIs/Docs, und waegt Ergaenzung vs. Refactoring ab. Aktiviere bei "Plan Ticket...", "Plane Implementierung...", oder /plan-ticket.
---

# Plan Ticket

Tiefenanalyse vor der Implementierung: Code verstehen, APIs recherchieren, Ansatz festlegen.

## Kernprinzip

**Verstehen vor Umsetzen.** Wer blind implementiert, baut technische Schulden. Dieser Skill produziert einen Plan, den der User reviewt bevor `/implement-ticket` startet.

## Wann dieser Skill aktiviert wird

- "Plan Ticket ios-032"
- "Plane Implementierung fuer shared-040"
- `/plan-ticket ios-032`

## Workflow

### Schritt 1: Ticket finden und verstehen

1. Ticket-Datei per Glob suchen — nie den Dateinamen raten:
   ```
   Glob('dev-docs/tickets/**/*<ticket-id>*')
   ```
2. Ticket lesen, Akzeptanzkriterien extrahieren
3. **Bei `shared-<id>`-Tickets:** User fragen, fuer welche Plattform der Plan geschrieben werden soll (iOS, Android, oder beide nacheinander). Code-Analyse und API-Recherche unterscheiden sich pro Plattform — jede Plattform bekommt einen eigenen Plan.
4. Plattform-CLAUDE.md lesen (`ios/CLAUDE.md` oder `android/CLAUDE.md`)

### Schritt 1b: Mehrdeutigkeiten identifizieren

Bevor du Code suchst: Welche Begriffe oder Anforderungen im Ticket erlauben mehr als eine Interpretation? Welche Annahmen triffst du implizit (Default-Werte, Edge-Case-Handling, Plattform-Verhalten, UX-Entscheidungen)?

- **Mindestens eine Mehrdeutigkeit:** User per `AskUserQuestion` klaeren, bevor du planst. Annahmen, die unsichtbar in den Plan rutschen, sind die haeufigste Plan-Fehlerquelle.
- **Bewusst getroffene Annahmen** (z.B. „ich nehme an, Default-Lautstaerke ist 50%, weil das im Rest der App so ist") landen spaeter im Plan unter „Annahmen" — nicht unter „Offene Fragen".

### Schritt 2: Relevante Codestellen finden

Ausgehend von den Akzeptanzkriterien die betroffenen Bereiche identifizieren. Nicht mechanisch alle Layer abarbeiten, sondern gezielt suchen:

1. **Begriffe/Klassen identifizieren:** Welche Domain-Begriffe, Klassen, Protocols tauchen in den Akzeptanzkriterien auf?
2. **Codebase durchsuchen:** Per Grep/Glob diese Begriffe finden.
3. **Kontext verstehen:** Fuer jeden Treffer — welcher Layer, welche Abhaengigkeiten, welche Tests existieren?
4. **Andere Plattform pruefen:** Wie wurde das Feature auf der anderen Plattform geloest? (Shared-Tickets: beide Plattformen analysieren)

Zur Orientierung die Layer-Struktur: Domain → Application → Infrastructure → Presentation (siehe `dev-docs/architecture/overview.md`).

**Subagent-Empfehlung:** Bei ≥ 3 Akzeptanzkriterien oder unbekanntem Code-Bereich → `Explore`-Subagent. Briefing: relevante Dateien finden, **strukturierte Tabelle** zurueckgeben (Datei | Layer | warum relevant), keine Roh-Excerpts. Spart Hauptkontext, da die meisten Read-Excerpts hier Wegwerf-Material sind. Schritt 2 und Schritt 3 koennen parallel laufen (siehe Schritt 3).

Ergebnis: Tabelle relevanter Dateien mit Layer und Begruendung.

### Schritt 3: Externe APIs und Dokumentation recherchieren

Wenn das Ticket Framework-APIs, externe Libraries, oder Plattform-Features beruehrt:

1. **APIs identifizieren:** Welche Framework-APIs werden benoetigt? (z.B. AVFoundation, MediaPlayer, HealthKit, Jetpack Compose APIs)
2. **Offizielle Docs lesen:** Via WebFetch/WebSearch aktuelle API-Signaturen und Availability pruefen. Training-Daten koennen veraltet sein.
3. **Availability pruefen:** Minimum Deployment Target beachten (steht in Plattform-CLAUDE.md)
4. **Bekannte Einschraenkungen:** Gibt es bekannte Bugs, Deprecations, oder Plattform-spezifische Eigenheiten?

**Subagent-Empfehlung:** Bei mehreren APIs oder unsicherer Verfuegbarkeit → `general-purpose`-Subagent mit WebFetch/WebSearch. Briefing: strukturierte Tabelle zurueckgeben (API | Min. Version | Quelle | Hinweis). Parallel mit Schritt 2 starten — die beiden sind unabhaengig.

Ergebnis: Tabelle der benoetigten APIs mit Verfuegbarkeit und relevanten Hinweisen.

### Schritt 4: Ansatz festlegen — Ergaenzen vs. Refactoring

Fuer jede betroffene Codestelle bewerten:

**Kann ergaenzt werden** wenn:
- Bestehende Abstraktion passt (neuer Case in Enum, neue Methode in Protocol)
- Bestehende Tests decken den Bereich ab und muessen nur erweitert werden
- Aenderung ist additiv und bricht nichts Bestehendes

**Refactoring noetig** wenn:
- Bestehende Abstraktion passt nicht (z.B. Protocol muss erweitert werden, was alle Conformances betrifft)
- Architecture-Layer-Verletzung wuerde entstehen
- Bestehende Tests fehlen und der zu aendernde Code ist nicht abgedeckt — dann erst Charakterisierungs-Tests, dann aendern

**Harte Regel:** Refactoring nur wenn das Akzeptanzkriterium ohne nicht sauber umsetzbar ist. **Nicht** weil der Code „besser sein koennte", „zu komplex wirkt" oder „eigentlich aufgeteilt gehoert". Im Zweifel: ergaenzen, Refactoring-Idee als Follow-up-Ticket vorschlagen. Plan-Ticket ist kein Aufraum-Ticket.

Fuer jedes identifizierte Refactoring: Scope und Risiko benennen.

### Schritt 5: Fachliche Szenarien definieren

Jedes Akzeptanzkriterium in konkrete, testbare Szenarien uebersetzen. Die Szenarien beschreiben Verhalten aus Nutzersicht — kein Code, keine technischen Details.

Format: **Gegeben / Wenn / Dann**

Gute Szenarien:
- Beschreiben beobachtbares Verhalten (was der User sieht/hoert)
- Decken den Normalfall UND relevante Edge Cases ab
- Sind so konkret, dass `/implement-ticket` sie direkt in Tests uebersetzen kann

Edge Cases ergeben sich oft erst aus Schritt 2-4 (Code-Analyse, API-Recherche). Beispiele:
- API hat Einschraenkungen → Szenario fuer den Fehlerfall
- Bestehender Code hat Race Conditions → Szenario fuer Timing
- Andere Plattform behandelt Edge Case → gleiches Szenario uebernehmen

**Nicht ueberdrehen:** Nur Szenarien die aus den Akzeptanzkriterien und der Code-Analyse folgen. Keine hypothetischen Szenarien erfinden.

### Schritt 6: Plan schreiben

Den Plan als eigene Datei speichern — getrennt vom Ticket.

**Pfad-Konvention:**
- `ios-<id>`, `android-<id>`: `dev-docs/tickets/plans/<ticket-id>.md`
- `shared-<id>`: **Plan pro Plattform** — `dev-docs/tickets/plans/<ticket-id>-ios.md` und/oder `<ticket-id>-android.md`. Bei shared-Tickets vorher beim User klaeren, fuer welche Plattform der Plan geschrieben werden soll (oder beide nacheinander). Code-Analyse und API-Recherche unterscheiden sich pro Plattform — ein gemeinsamer Plan vermischt nur.

Verzeichnis existiert seit dem ersten Plan-Ticket; nicht vorhanden? Mit `mkdir -p` anlegen.

**Format:**

```markdown
# Implementierungsplan: <ticket-id>

Ticket: [<ticket-id>](../platform/<ticket-dateiname>.md)
Erstellt: <datum>

## Annahmen

Bewusst getroffene Annahmen, die in den Plan eingeflossen sind. (Unterschied zu „Offene Fragen": hier ist die Entscheidung gefallen, dort ist sie offen.)

- Default-Lautstaerke fuer Soundscape: 50% — analog zu bestehender Logik in `AudioService.defaultVolume`.
- ...

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Models/Timer.swift` | Domain | Erweitern | Neues Property `x` hinzufuegen |
| `Application/ViewModels/TimerVM.swift` | Application | Refactoring | Methode `y` aufteilen |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `AVAudioSession.setCategory(_:options:)` | iOS 10+ | Apple Docs | `.mixWithOthers` fuer Hintergrund-Audio |

## Design-Entscheidungen (optional)

Bei Tickets mit Trade-offs: Entscheidung, Alternativen, Begruendung.

### 1. Entscheidungstitel

**Trade-off:** Was spricht dafuer, was dagegen?
**Entscheidung:** Was wurde gewaehlt und warum.

## Refactorings

1. **TimerViewModel aufteilen** — `startTimer()` hat 3 Verantwortlichkeiten. Erst aufteilen, dann Feature ergaenzen.
   - Risiko: Mittel. 12 bestehende Tests decken den Bereich ab.

## Fachliche Szenarien

### AK-1: Timer laeuft im Hintergrund weiter

- Gegeben: Timer laeuft bei 3:00
  Wenn: User wechselt zur Home-App
  Dann: Timer zaehlt weiter, bei Rueckkehr korrekte Zeit

- Gegeben: Timer laeuft bei 0:05
  Wenn: User wechselt weg, Timer laeuft im Hintergrund ab
  Dann: Gong ertoent, Timer zeigt 0:00 bei Rueckkehr

### AK-2: ...

## Reihenfolge der Akzeptanzkriterien

Optimale Reihenfolge fuer TDD (Abhaengigkeiten beruecksichtigen):

1. **AK-1: ...** — Zuerst Domain-Model erweitern (Grundlage fuer alles)
2. **AK-3: ...** — Dann ViewModel (baut auf Domain auf)
3. **AK-2: ...** — Zuletzt View (baut auf ViewModel auf)

## Offene Fragen

- [ ] Frage an den User, falls Entscheidungen noetig sind
```

Optionale Sektionen (nur ergaenzen, wenn fuer dieses Ticket relevant): **Vorbereitung** (manuelle Schritte wie Xcode-Target, Provisioning, externe Accounts), **Risiken** (Tabelle Risiko | Mitigation).

### Schritt 7: Ticket aktualisieren

Plan-Verweis im Ticket ergaenzen (unter der Status-Zeile, Status nicht aendern):

```
**Plan**: [Implementierungsplan](../plans/<ticket-id>.md)
```

Den Status-Uebergang zu `[~] IN PROGRESS` macht `/implement-ticket` beim Branch-Erstellen. Plan-Ticket aendert ihn nicht — der User koennte den Plan tagelang reviewen oder verwerfen.

### Schritt 8: User-Review

Zeige dem Plan im Chat und frage:

> Plan steht in `dev-docs/tickets/plans/<ticket-id>.md`. Bitte reviewen:
> - Stimmt der Ansatz?
> - Offene Fragen klaeren?
> - Naechster Schritt: `/implement-ticket <ticket-id>`

## Wann diesen Skill NICHT nutzen

Ueberspringe diesen Skill wenn:
- Ticket hat 1-2 Akzeptanzkriterien und der betroffene Code ist offensichtlich
- Reiner Bugfix in einer bekannten Codestelle
- Refactoring ohne neue APIs oder Architektur-Aenderungen

Im Zweifel: Wenn du den Ansatz in einem Satz beschreiben kannst, brauchst du keinen Plan.

## Was dieser Skill NICHT macht

- **Keinen Code schreiben** — nur analysieren und planen
- **Keine Tests ausfuehren** — das macht `/implement-ticket`
- **Keine Commits** — der Plan wird als separate Datei gespeichert
- **Keine Architektur-Entscheidungen treffen** — bei Unklarheiten den User fragen

## Referenzen

- `dev-docs/architecture/overview.md` — Architektur-Ueberblick
- `dev-docs/architecture/ddd.md` — DDD-Regeln
- `dev-docs/reference/glossary.md` — Begriffe
- `ios/CLAUDE.md` / `android/CLAUDE.md` — Plattform-spezifische Patterns
