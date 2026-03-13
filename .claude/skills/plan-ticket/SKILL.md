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
3. Plattform-CLAUDE.md lesen (`ios/CLAUDE.md` oder `android/CLAUDE.md`)

### Schritt 2: Relevante Codestellen finden

Ausgehend von den Akzeptanzkriterien die betroffenen Bereiche identifizieren. Nicht mechanisch alle Layer abarbeiten, sondern gezielt suchen:

1. **Begriffe/Klassen identifizieren:** Welche Domain-Begriffe, Klassen, Protocols tauchen in den Akzeptanzkriterien auf?
2. **Codebase durchsuchen:** Per Grep/Glob diese Begriffe finden. Explore-Agent fuer breite Suchen.
3. **Kontext verstehen:** Fuer jeden Treffer — welcher Layer, welche Abhaengigkeiten, welche Tests existieren?
4. **Andere Plattform pruefen:** Wie wurde das Feature auf der anderen Plattform geloest? (Shared-Tickets: beide Plattformen analysieren)

Zur Orientierung die Layer-Struktur: Domain → Application → Infrastructure → Presentation (siehe `dev-docs/architecture/overview.md`).

Ergebnis: Liste aller relevanten Dateien mit kurzer Beschreibung was dort passiert und warum es relevant ist.

### Schritt 3: Externe APIs und Dokumentation recherchieren

Wenn das Ticket Framework-APIs, externe Libraries, oder Plattform-Features beruehrt:

1. **APIs identifizieren:** Welche Framework-APIs werden benoetigt? (z.B. AVFoundation, MediaPlayer, HealthKit, Jetpack Compose APIs)
2. **Offizielle Docs lesen:** Via WebFetch/WebSearch aktuelle API-Signaturen und Availability pruefen. Training-Daten koennen veraltet sein.
3. **Availability pruefen:** Minimum Deployment Target beachten (steht in Plattform-CLAUDE.md)
4. **Bekannte Einschraenkungen:** Gibt es bekannte Bugs, Deprecations, oder Plattform-spezifische Eigenheiten?

Ergebnis: Liste der benoetigten APIs mit Verfuegbarkeit und relevanten Hinweisen.

### Schritt 4: Ansatz festlegen — Ergaenzen vs. Refactoring

Fuer jede betroffene Codestelle bewerten:

**Kann ergaenzt werden** wenn:
- Bestehende Abstraktion passt (neuer Case in Enum, neue Methode in Protocol)
- Bestehende Tests decken den Bereich ab und muessen nur erweitert werden
- Aenderung ist additiv und bricht nichts Bestehendes

**Refactoring noetig** wenn:
- Bestehende Abstraktion passt nicht (z.B. Protocol muss erweitert werden, was alle Conformances betrifft)
- Code ist zu komplex um sicher zu erweitern (zu viele Verantwortlichkeiten)
- Bestehende Tests fehlen und muessen erst geschrieben werden bevor geaendert wird
- Architecture-Layer-Verletzung wuerde entstehen

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

**Pfad:** `dev-docs/tickets/plans/<ticket-id>.md`

```bash
mkdir -p dev-docs/tickets/plans  # falls noch nicht vorhanden
```

**Format:**

```markdown
# Implementierungsplan: <ticket-id>

Ticket: [<ticket-id>](../platform/<ticket-dateiname>.md)
Erstellt: <datum>

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Models/Timer.swift` | Domain | Erweitern | Neues Property `x` hinzufuegen |
| `Application/ViewModels/TimerVM.swift` | Application | Refactoring | Methode `y` aufteilen |

## API-Recherche

- **AVAudioSession.setCategory(_:options:)** — Verfuegbar ab iOS 10. Option `.mixWithOthers` fuer Hintergrund-Audio.
- ...

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

## Vorbereitung (optional)

Manuelle Schritte die vor der Implementierung noetig sind (z.B. Xcode-Target erstellen, Provisioning Profiles, externe Accounts).

## Risiken (optional)

| Risiko | Mitigation |
|--------|-----------|
| Beschreibung des Risikos | Wie damit umgehen |

## Offene Fragen

- [ ] Frage an den User, falls Entscheidungen noetig sind
```

### Schritt 7: Ticket aktualisieren

1. Status im Ticket auf `[~] IN PROGRESS` setzen
2. Plan-Verweis im Ticket ergaenzen (nach der Status-Zeile):
   ```
   **Plan**: [Implementierungsplan](../plans/<ticket-id>.md)
   ```

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
