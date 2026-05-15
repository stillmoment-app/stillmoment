---
name: review-code
description: Reviewt Code-Implementierungen nach Wartbarkeit, Architektur, Lesbarkeit (DDD), sinnvoller Testabdeckung und Scope-Treue. Bietet Auto-Fix fuer mechanische Findings an. Aktiviere bei Ticket-Abschluss, Code-Review-Anfragen, oder wenn der User nach Qualitaetspruefung fragt. Gibt nur Feedback wenn es wirklich relevant ist - kein Review um des Reviews willen.
---

# Code Review

Systematisches Code-Review mit Fokus auf das Wesentliche. Bei mechanischen Findings: Auto-Fix-Angebot.

## Kernprinzip

**Nur relevante Anmerkungen.** Wenn der Code gut ist, sag das - und fertig. Keine kuenstlichen Findings erfinden.

- Kein Review um des Reviews willen
- Keine Stilkritik ohne Substanz
- Keine theoretischen Verbesserungen die praktisch nichts aendern
- Lob wo Lob angebracht ist

## Philosophie

**Keine Coverage-Jagd** - Relevante Tests statt Prozentzahlen.
**DDD wo sinnvoll** - Ubiquitous Language, aussagekraeftige Namen, klare Domaengrenzen.
**Pragmatische Architektur** - Clean Architecture als Leitfaden, nicht als Dogma.
**Surgical Changes** - Code soll nur das tun, was das Ticket verlangt. Drive-by-Refactorings sind Findings.

## Wann dieser Skill aktiviert wird

Automatisch bei:
- "Review den Code fuer Ticket ios-025"
- "Pruefe die Implementierung von shared-007"
- "Code Review fuer die neuen Timer-Features"
- "Ist die Architektur von AudioService gut?"

## Workflow

### Schritt 1: Scope ermitteln

**Mit Ticket-Referenz:**
1. Ticket lesen: `dev-docs/tickets/{platform}/{ticket-id}.md`
2. Akzeptanzkriterien extrahieren
3. Diff bestimmen: `git diff $(git merge-base main HEAD) HEAD --stat`

**Ohne Ticket-Referenz:**
1. User nach Scope fragen (Dateien, Feature, Modul)
2. Relevante Dateien mit Glob/Grep finden

Bei sehr grossem Diff: Code-Lesen kann an `Explore`-Subagent delegiert werden, um den Hauptkontext freizuhalten. Keine starre Schwelle - Fingerspitzengefuehl.

### Schritt 2: Diff + Checks parallel

In einer Bash-Runde parallel starten:

1. **Diff lesen:** `git diff $(git merge-base main HEAD) HEAD` → Review-Fokus
2. **Statische Pruefungen:** `make -C ios check` ODER `make -C android lint` (je nach Plattform im Diff)
3. **Memory-Check:** MEMORY.md auf themen-relevante Eintraege scannen (Audio → Lock-Screen-Gong-Bug, UIKit-bridged Controls → Theme-Probleme, Convenience init → Dependency vergessen, etc.)

Bei UI-Code zusaetzlich:
4. **Localization:** `/review-localization` als parallelen Subagent starten

### Schritt 3: Bewerten

**Diff-First lesen.** Ganze Dateien nur als Kontext wenn ein Hunk allein nicht verstaendlich ist.

Bewerten nach Checklisten - aber nur wenn es etwas zu sagen gibt:

1. **Wartbarkeit** - `checklists/wartbarkeit.md`
2. **Architektur** - `checklists/architektur.md`
3. **Lesbarkeit (DDD)** - `checklists/lesbarkeit.md`
4. **Testabdeckung** - `checklists/tests.md`
5. **Scope-Treue** - `checklists/scope.md`
6. **Mechanische Findings** - `checklists/mechanische-findings.md`
7. **Dokumentation** - `checklists/doku.md`

Bei Ticket-Reviews zusaetzlich: jedes Akzeptanzkriterium einzeln pruefen, Scope-Drift gezielt suchen.

**Wichtig:** Nicht jede Kategorie muss Findings haben. Guter Code ist gut.

### Schritt 4: Report inline ausgeben

Strukturvorlage: `templates/report.md` (keine Datei erzeugen, nur als Gliederung nutzen).

- Kurze Zusammenfassung
- Findings nach Klasse gruppiert (mechanisch / substanziell / diskutiert / scope-drift)
- Positives nur wenn wirklich bemerkenswert
- Fazit: Freigabe / Freigabe mit Anmerkungen / Nacharbeit

**Wenn alles gut ist:**

```
Der Code erfuellt die Anforderungen und ist gut strukturiert.
Keine Anmerkungen.
```

Das ist ein valides Review-Ergebnis. Kein Auto-Fix-Flow noetig, Review fertig.

### Schritt 5: Optional Auto-Fix

**Wenn mechanische Findings vorhanden:**

Liste praesentieren:

```
Folgende mechanische Findings koennen automatisch gefixt werden:

1. print() → Logger.audio in AudioService.swift:42
2. Fehlendes [weak self] in TimerViewModel.swift:88
3. Hardcoded String "Starten" in TimerView.swift:120
```

Mit AskUserQuestion fragen:
- **Alle fixen** (Default)
- **Auswahl fixen** - User waehlt einzelne aus
- **Nichts fixen** - Nur Report

Bei Zustimmung: Fixes direkt im Hauptkontext via `Edit`-Tool umsetzen (kein Subagent-Overhead fuer 5-Zeilen-Mechanik).

**Auto-Fix-Constraints (Surgical):**
- Nur die in der Liste genannten Zeilen aendern
- Kein Drive-by-Refactoring (keine Imports umsortieren, kein Style-Fixing in unveraenderten Bereichen)
- Existierenden Stil matchen
- Nach allen Fixes einmal `make -C {platform} check` (gruen sein)
- Bei Unklarheit (z.B. welcher Logger-Kanal passt) STOPPEN und zurueckmelden, nicht raten

**Substanzielle Findings** (fehlender Test, kleines Refactoring): einzeln nachfragen mit konkretem Vorschlag. Nicht autonom fixen.

**Diskutierte Findings** (Architektur, Naming, Design): kein Auto-Fix, nur Report. Das sind oft die wichtigsten Findings - sie verlangen Diskussion, nicht Mechanik.

## Was ECHTE Findings sind

| Echtes Finding | Kein Finding |
|----------------|--------------|
| Bug oder Fehler | "Koennte man auch anders machen" |
| Sicherheitsproblem | Stilpraeferenz |
| Architekturverletzung | Theoretische Verbesserung |
| Fehlender Test fuer kritischen Pfad | "Mehr Tests waeren besser" |
| Unverstaendlicher Code | "Ich haette es anders gemacht" |
| Wartbarkeitsproblem | Kosmetik |
| Scope-Drift / Drive-by-Refactoring | "Wuerde ich anders strukturieren" |
| Mechanisches Anti-Pattern (print, force unwrap, ...) | "Koennte man komprimieren" |

## Finding-Klassifikation

| Klasse | Beispiele | Action |
|--------|-----------|--------|
| **Mechanisch** | `print()`, `[weak self]` fehlt, hardcoded String, force unwrap, direkte Farbe | Liste → Auto-Fix im Hauptkontext |
| **Substanziell** | Fehlender Test fuer kritischen Pfad, kleines Refactoring | Einzeln nachfragen |
| **Diskutiert** | Architekturverletzung, Naming, Design-Entscheidung | Nur Report |

## Was NICHT wichtig ist

- 100% Coverage
- Kommentare ueberall
- Maximale Abstraktion
- Perfekte Patterns
- Jede Methode unter 10 Zeilen

## Anti-Patterns (nur wenn sie WIRKLICH problematisch sind)

### Nur melden wenn es schadet:
- Funktionen die wirklich unverstaendlich sind (nicht: "etwas lang")
- Tests die tatsaechlich nutzlos sind (nicht: "koennten besser sein")
- Architektur die das Projekt behindert (nicht: "nicht ganz lehrbuchmaessig")

## Referenzen

- `CLAUDE.md` - Projekt-Standards (inkl. Forbidden Patterns)
- `dev-docs/tickets/INDEX.md` - Ticket-System
- `checklists/mechanische-findings.md` - Auto-Fix-Patterns
- `checklists/scope.md` - Surgical Changes + Overengineering
