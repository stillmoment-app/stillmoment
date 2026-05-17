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

**Ticket-ID-Quellen (in dieser Reihenfolge pruefen):**
1. Explizites Argument (`/review-code ios-042`)
2. Branch-Name: `git rev-parse --abbrev-ref HEAD` — Muster `feature/<ticket-id>`, `fix/<ticket-id>`, `refactor/<ticket-id>` → Ticket-ID extrahieren. Bei Treffer: dem User mitteilen ("Branch deutet auf Ticket ios-042 hin — pruefe gegen dessen Akzeptanzkriterien.") und fortfahren.
3. Keine Ticket-ID gefunden → User nach Scope fragen (Dateien, Feature, Modul)

**Mit Ticket-Referenz:**
1. Ticket-Datei per Glob suchen (Dateiname kann von ID abweichen): `dev-docs/tickets/**/*{ticket-id}*.md`
2. Akzeptanzkriterien extrahieren
3. Diff bestimmen: `git -C <repo> diff main...HEAD --stat`

**Ohne Ticket-Referenz:**
1. Relevante Dateien mit Glob/Grep finden
2. Diff trotzdem gegen `main` ermitteln

**Permission-Pattern fuer Diffs:**
- Immer Drei-Punkt-Notation `main...HEAD` verwenden — zeigt Aenderungen seit dem Branch von `main`, ohne `$(git merge-base ...)`-Substitution.
- `$(...)`-Command-Substitution triggert die Sicherheitsabfrage und ist daher verboten.
- Beispiele: `git -C /path/to/repo diff main...HEAD`, `git -C /path/to/repo diff main...HEAD --stat`, `git -C /path/to/repo log main..HEAD --oneline` (Zwei-Punkt fuer Commits, Drei-Punkt fuer Diff).

Bei sehr grossem Diff: Code-Lesen kann an `Explore`-Subagent delegiert werden, um den Hauptkontext freizuhalten. Keine starre Schwelle - Fingerspitzengefuehl.

### Schritt 2: Diff + Checks parallel (Subagent-First)

**Regel:** Alles mit langem Output oder unabhaengiger Recherche → Subagent. Hauptkontext bleibt fuer Bewertung frei.

In einer Runde parallel starten:

1. **Diff lesen** (Hauptkontext): `git -C <repo> diff main...HEAD` → Review-Fokus (Drei-Punkt-Notation, keine `$(...)`-Substitution)
2. **Statische Pruefungen** (`Bash`-Subagent): `make -C ios check` ODER `make -C android lint`. Prompt: "Run X in Y, return only RESULT and any errors".
3. **Test-Lauf** (`Bash`-Subagent): `make -C {platform} test-unit-agent` mit `timeout: 300000`. **Kein Review ohne grüne Tests** - rote Tests sind Nacharbeit, bevor weitergereviewt wird.
4. **Memory-Mapping** (Hauptkontext): MEMORY.md gegen Diff-Themen mappen. Konkrete Trigger:

| Diff enthaelt | MEMORY-Eintraege pruefen |
|---|---|
| `AudioService`, `AudioSession`, Gong | [[project_lock_screen_gong_bug]], Lock-Screen-Keep-Alive |
| `Slider`, `Picker(.segmented)`, `DatePicker`, `Stepper` | UIKit-bridged Controls → `.id(theme)` noetig |
| Neue Dependency in Service-`init` | [[ios-architektur-fallstricke]] Convenience-init |
| `.navigationTitle()`, `.searchable()` in Sheet | UIKit-Bridge → Toolbar-Workaround |
| `.foregroundColor(.warmBlack)` etc. | Direkte Farben → semantische Rolle |
| Neue Compose-Composables | detekt LongMethod, MultipleEmitters |
| `preferencesDataStore(name=...)` | [[feedback_android_datastore_singleton]] |
| `remember { ... }` mit Lambda-Closure | [[feedback_compose_stale_lambda]] |
| Feature nach Meditations-Ende | [[feedback_lock_screen_lifecycle]] |

Bei UI-Code zusaetzlich:
5. **Localization** (Subagent): `/review-localization`
6. **Cross-Platform-Check** (Hauptkontext): Wenn Feature auf beiden Plattformen existiert — wurde die andere Plattform synchron gehalten? Siehe `checklists/cross-platform.md`.

### Schritt 3: Bewerten

**Diff-First lesen.** Ganze Dateien nur als Kontext wenn ein Hunk allein nicht verstaendlich ist.

Bewerten nach Checklisten - aber nur wenn es etwas zu sagen gibt:

1. **Wartbarkeit** - `checklists/wartbarkeit.md`
2. **Architektur** - `checklists/architektur.md`
3. **Lesbarkeit (DDD)** - `checklists/lesbarkeit.md`
4. **Testabdeckung** - `checklists/tests.md`
5. **Scope-Treue** - `checklists/scope.md`
6. **Cross-Platform-Konsistenz** - `checklists/cross-platform.md`
7. **Mechanische Findings** - `checklists/mechanische-findings.md`
8. **Dokumentation** - `checklists/doku.md`

**Review-Annahmen explizit machen** (Karpathy "Think Before Coding"): Bevor ein nicht-mechanisches Finding rausgeht, prüfen: "Welche Annahme treffe ich hier? Koennte es absichtlich so sein?" Beispiel: `strong self` in einem Task der die View-Lifetime ueberdauert ist kein Leak. **Wenn unklar: nicht raten - Verify-Subagent (`Explore`) starten** ("Wer ruft diese Methode auf? Wie ist der Lifecycle?") oder im Report als Frage formulieren statt als Bug.

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
- **Wenn `make check` nach Fix rot wird: STOP, kein Try-and-Error.** Diff zeigen, Fehler melden, User entscheidet — nicht selbstaendig weiterfrickeln.

**Substanzielle Findings** (fehlender Test, kleines Refactoring): einzeln nachfragen mit konkretem Vorschlag. Nicht autonom fixen.

**Diskutierte Findings** (Architektur, Naming, Design): kein Auto-Fix, nur Report. Das sind oft die wichtigsten Findings - sie verlangen Diskussion, nicht Mechanik.

Bei diskutierten Findings: **Optionen statt Empfehlung praesentieren** wenn mehrere Ansaetze sinnvoll sind. "Diese Naming-Wahl koennte als A, B oder C angegangen werden — welche passt zum Domaenen-Modell?" — User entscheidet. Nur wenn klar besser: eine konkrete Empfehlung.

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
- `checklists/cross-platform.md` - iOS/Android-Konsistenz
