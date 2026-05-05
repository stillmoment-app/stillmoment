# Analyse: Ticket-Workflow-Skills

**Datum:** 2026-05-05
**Scope:** Skills `/create-ticket`, `/plan-ticket`, `/implement-ticket`, `/review-code`, `/close-ticket` plus zugehoerige Agents (`ticket-implementer`, `ticket-reviewer`).
**Methodik:** Skill-Definitionen gelesen, ~13 Konversations-Sessions ausgewertet (Skill-Aufrufe, Test-/Git-Befehle, Modell-Nutzung), offizielle Anthropic-Plugins inspiziert, Phase-Skills aus Schwester-Projekt `search-backend` als Inspiration analysiert.

---

## TL;DR

Der 5-Phasen-Workflow ist konzeptionell sauber und liefert in der Praxis Mehrwert. Drei Schwachstellen sind aktuell teuer:

1. **Branch-Handling unvollstaendig** — kein `git pull main` vor Branch-Anlage, kein Cleanup nach Merge, Plan-Commit-Konvention unausgesprochen. Konkretes Risiko: Feature-Branches auf veraltetem main, lokale `[gone]`-Branches sammeln sich.
2. **Tests laufen 2x ohne Aenderung** — `make check` + `make test-unit-agent` einmal in `/implement-ticket` Schritt 4, direkt danach in `/review-code` bzw. `ticket-reviewer`-Agent. Bei iOS ~30–60 s pro Lauf.
3. **Opus dominiert** — Sessions zeigen 5430 Opus-4.7-Calls vs. 578 Sonnet-4.6-Calls. Skills haben keine Modell-Frontmatter und erben Opus, obwohl `create-ticket`/`close-ticket` Pattern-Matching-Aufgaben sind.

Schaetzung Token-Einsparung durch Modell-Differenzierung: **30–50 % bei den vier Nicht-Implement-Skills**, ohne Qualitaetsverlust.

---

## Inventar: Was ist wo?

### Projekt-lokal (`stillmoment/.claude/`)

| Typ | Name | Zweck |
|---|---|---|
| Skill | `create-ticket` | Ticket anlegen, Philosophie- und AK-Validierung |
| Skill | `plan-ticket` | Implementierungsplan in `dev-docs/tickets/plans/` |
| Skill | `implement-ticket` | TDD-Loop, Quality Gate, Commit |
| Skill | `review-code` | 5-Kategorien-Review (Wartbarkeit/Architektur/Lesbarkeit/Tests/Doku) |
| Skill | `close-ticket` | Status-Update, Doku-Check |
| Skill | `create-ui-test`, `release-notes`, `review-localization`, `review-view`, `review-website` | Spezial-Workflows |
| Agent | `ticket-implementer` (model: opus) | Ruft `/implement-ticket`, lokale Commits, kein Push |
| Agent | `ticket-reviewer` (model: sonnet) | Read-only, ruft `/review-code` + `/review-localization` |
| Agent | `apple-app-review-validator`, `ios-ux-consistency-checker` | Spezial |

### Global (`~/.claude/`)

- Skills: `dbt-rebuild`, `dbt-review`, `explore` (alle eigene Creationen)
- Agents: keine
- Memory: `MEMORY.md` + spezifische Notes unter `~/.claude/projects/-Users-helmut-devel-stillmoment/memory/`

### Installierte Plugins (`~/.claude/plugins/`, user-scope)

Aus Marketplace `claude-plugins-official` (Anthropic):
- `swift-lsp`, `clangd-lsp`, `kotlin-lsp` — LSP-Integration
- `frontend-design` — UI-Design-Skill
- `code-review` — `/code-review` Slash-Command (PR-Review fuer Github)
- `pyright-lsp` (project-scope, anderes Projekt)

Bekannte Marketplaces:
- `claude-plugins-official` (Anthropic, [github.com/anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official))
- `neuland-claude-marketplace` (firmenintern)
- `hoeffner-search-claude-marketplace` (anderes Projekt)

### Eingebaute Claude-Code-Slash-Commands (sichtbar in Skill-Liste)

- `/init` — CLAUDE.md initialisieren
- `/review` — PR-Review (built-in)
- `/security-review` — Security-Scan der pending changes

---

## Skill vs. Agent — Begriffsklaerung

| | Skill | Agent |
|---|---|---|
| **Wo?** | `.claude/skills/<name>/SKILL.md` | `.claude/agents/<name>.md` |
| **Trigger** | Im Hauptkontext invoziert (`/skill-name` oder via Beschreibung) | Explizit per `Task`-Tool aufgerufen |
| **Kontext** | Lebt im Hauptkontext der Session | **Eigener Sub-Kontext**, isoliert |
| **Output** | Direkte Tool-Calls und Text | Liefert Text-Report zurueck |
| **Modell** | Erbt aktives Modell (kein Frontmatter heute) | Eigenes `model:`-Frontmatter moeglich |
| **Token** | Verbraucht Hauptkontext-Token | Verbraucht eigene Token, schont Hauptkontext |

**Faustregel im Stillmoment-Projekt:**
- Skill = Workflow-Anleitung, die Claude sequenziell abarbeitet
- Agent = Sub-Task mit eigenem Kontext (z. B. langer Code-Review, parallele Recherche)

Heute werden Skills im Hauptkontext aufgerufen. Die Agents `ticket-implementer` und `ticket-reviewer` existieren — werden aber nicht automatisch von den Skills getriggert. Das ist eine offene Designentscheidung (siehe Finding 11).

---

## Findings, priorisiert nach Impact

### Hoch (Korrektheit)

#### F1: Branch-Anlage ohne `pull main`
**Skill:** `implement-ticket` Schritt 1
**Symptom:** Skill verlangt sauberen WD und macht `git checkout -b feature/<id>`. Ein `git checkout main && git pull --rebase origin main` davor fehlt.
**Risiko:** Branch wird vom aktuellen HEAD gezogen — oft ein abgeschlossener Feature-Branch. Rebase-Konflikte beim spaeteren Merge, fehlende Bugfixes aus main.
**Beleg:** Aktueller Branch `feature/shared-090` wurde laut Git-Log direkt nach shared-088/089-Arbeit erstellt, ohne sichtbares main-Update.

**Fix:**
```diff
 ### Schritt 1: Feature-Branch erstellen

-1. Git-Status pruefen — Working Directory muss sauber sein (keine uncommitteten Aenderungen)
-2. Branch erstellen: `git checkout -b feature/<ticket-id>`
+1. Git-Status pruefen — Working Directory muss sauber sein (keine uncommitteten Aenderungen)
+2. Auf main wechseln und aktuellen Stand holen:
+   - `git checkout main`
+   - `git pull --rebase origin main`
+3. Branch erstellen: `git checkout -b feature/<ticket-id>`
```

#### F2: Plan-Commit-Konvention unausgesprochen
**Skill:** `plan-ticket`
**Symptom:** Skill schreibt `dev-docs/tickets/plans/<id>.md`, sagt nichts ueber Commit/Branch. In der Praxis (Git-Log) wird der Plan oft als eigener `docs:`-Commit auf main committet, **bevor** der Feature-Branch entsteht. Das ist nirgends dokumentiert.
**Risiko:** Inkonsistenz — Plan landet mal auf main, mal auf dem Feature-Branch.

**Fix:** Schritt 6 ergaenzen:
```
### Schritt 6b: Plan committen

Auf main committen (vor Feature-Branch-Anlage):
  git add dev-docs/tickets/plans/<ticket-id>.md dev-docs/tickets/<...>.md
  git commit -m "docs: #<ticket-id> Plan"
```

#### F3: Status-Inkonsistenz zwischen Ticket-Datei und INDEX.md
**Skill:** `plan-ticket` Schritt 7
**Symptom:** Setzt Ticket-Status auf `[~] IN PROGRESS`, aktualisiert aber INDEX.md nicht. INDEX.md kennt nur `[ ]` und `[x]`. Zwischenstufe ist unsichtbar.
**Risiko:** INDEX.md wird zur unzuverlaessigen Quelle.

**Fix:** Entweder INDEX.md auch auf `[~]` mitziehen — oder Status-Update aus `plan-ticket` herausnehmen und nur `implement-ticket` setzt den Status (Schritt 1, beim Branch-Anlegen).

#### F4: `review-code` mischt Read-only und Fix
**Skill:** `review-code` Schritt 8
**Symptom:** Skill bietet via AskUserQuestion an, Findings direkt zu beheben. Bricht das Read-only-Versprechen, das `ticket-reviewer` explizit macht.
**Risiko:** Fix-Commits ohne klaren Branch-/TDD-Kontrakt; bei Wahl "Auswahl fixen" vermischt sich Review und Implementierung in einer Session.

**Fix:** Schritt 8 entfernen oder in eigenen Skill `/fix-review-findings` auslagern. Review endet beim Report.

#### F5: Subagent-Pflicht fuer Tests nicht im Skill
**Skill:** `implement-ticket` Schritt 3
**Symptom:** Skill schreibt `make test-single-agent TEST=...` direkt im Hauptkontext. Memory-Regel sagt: *"Tests nie direkt via Bash im Hauptkontext ausfuehren. Task(subagent_type='Bash')"*.
**Risiko:** Memory wird ignoriert, Hauptkontext laeuft mit Test-Output voll.

**Fix:** Schritt 3 ergaenzen:
```
2. **Run:** Tests via Subagent ausfuehren — `Task(subagent_type="general-purpose", prompt="Run `make test-single-agent TEST=…` in `ios/` (or `android/`), return only the result")` mit `timeout: 300000`.
```

### Mittel (Workflow-Konsistenz)

#### F6: Akzeptanzkriterien doppelt geprueft
**Skills:** `review-code` Schritt 4 + `close-ticket` Schritt 4
**Symptom:** Beide Skills pruefen die AKs einzeln gegen den Code. `close-ticket` vermerkt zwar "in der Regel wurde vor Close bereits ein Review gemacht", prueft aber trotzdem voll.
**Aufwand:** Zweite Pruefung kostet Token, oft auf Opus.

**Fix:** `close-ticket` Schritt 4 zu Quick-Check umbauen. Wenn ein Review-Report vorhanden ist (Konvention: `dev-docs/reviews/<id>.md` oder im PR-Kommentar), nur dessen Befund uebernehmen. Sonst voller Check.

#### F7: Tests laufen 2x ohne Aenderung
**Skills:** `implement-ticket` Schritt 4 + `review-code` Schritt 5 + `ticket-reviewer` Schritt 5
**Symptom:** `make check` + `make test-unit-agent` werden direkt nacheinander erneut ausgefuehrt, obwohl seit dem letzten Implementations-Commit kein Code geaendert wurde.
**Aufwand:** iOS-Suite ~30–60 s pro Lauf.

**Fix:** `review-code` Schritt 5 nur ausfuehren, wenn seit dem letzten Implementations-Commit Aenderungen vorliegen (`git diff <last-impl-commit>..HEAD`). Sonst nur Verweis: "Tests im Quality Gate gelaufen, kein Code geaendert".

#### F8: Branch-Cleanup fehlt komplett
**Skill:** `close-ticket`
**Symptom:** Skill schliesst Ticket-Status. Sagt nichts ueber lokalen Feature-Branch, Push, Merge oder Cleanup. Statistik aus den Sessions: 99 Pushes vs. 8 Merges — typischer Flow ist "Merge auf Github → push main → close" oder "lokaler Merge → push main", aber nirgends dokumentiert.
**Risiko:** Lokale `[gone]`-Branches sammeln sich.

**Fix:** `close-ticket` Schritt 6b ergaenzen:
```
### Schritt 6b: Branch-Cleanup empfehlen

Pruefe `git branch -v | grep '\[gone\]'`. Falls Eintraege:
> Folgende Branches sind remote-weg: …
> Soll ich /commit-commands:clean_gone aufrufen?
```

(Setzt Adoption von `commit-commands`-Plugin voraus, siehe Plugin-Empfehlungen.)

#### F9: `close-ticket` prueft nicht ob Code committet/gemerged ist
**Skill:** `close-ticket`
**Symptom:** Schliesst Ticket auch bei uncommitteten Aenderungen oder ungemergedem Feature-Branch.
**Fix:** Schritt 3a einfuegen: `git status` muss sauber sein, Branch muss in main gemerged sein (Pruefung via `git branch --merged main`).

### Niedrig (Kosten/Stil)

#### F10: Modell-Frontmatter fehlt — Opus laeuft ueberall
**Skills:** alle fuenf
**Symptom:** Sessions zeigen Opus 4.7 dominant (5430 Calls vs. 578 Sonnet vs. 788 Opus-4.6-fast). Skills erben das aktive Modell.
**Aufwand:** Token-Kosten. Opus ist ~5x teurer als Sonnet, ~25x teurer als Haiku.

**Vorschlag:**

| Skill | Heute | Vorschlag | Warum |
|---|---|---|---|
| `create-ticket` | erbt | **`haiku`** | Pattern-Matching, Templates fuellen, INDEX-Tabelle einfuegen |
| `close-ticket` | erbt | **`haiku`** | Status flippen, Tabelle aktualisieren, AK-Quick-Check |
| `plan-ticket` | erbt | **`sonnet`** | Architektur-Verstaendnis, aber ueberschaubares Reasoning |
| `implement-ticket` | erbt (Opus) | **`opus`** explizit | TDD, Refactoring, Edge Cases — rechtfertigt Opus |
| `review-code` | erbt | **`sonnet`** | `ticket-reviewer`-Agent ist schon Sonnet, Konsistenz |

Format (im SKILL.md-Frontmatter):
```yaml
---
name: create-ticket
description: …
model: haiku
---
```

#### F11: `plan-ticket` zeigt vollen Plan im Chat
**Skill:** `plan-ticket` Schritt 8
**Symptom:** Plan-Inhalt wird zusaetzlich zur Datei im Chat ausgegeben. Bei laengeren Plaenen (siehe shared-090, ~80 Zeilen) blaeht das den Hauptkontext auf.
**Fix:** Nur Pfad + 3-Saetze-Zusammenfassung + 2 wichtigste offene Fragen ausgeben. Volltext steht in der Datei.

#### F12: Skills triggern existierende Sub-Agents nicht
**Skills:** `implement-ticket`, `review-code`
**Symptom:** Es gibt `ticket-implementer` (model: opus) und `ticket-reviewer` (model: sonnet) — die Skills rufen sie aber nicht. Heute laeuft alles im Hauptkontext.
**Designfrage:** Soll der User explizit den Agent starten (`Task(subagent_type='ticket-reviewer')`) oder soll das Skill das transparent machen?

**Empfehlung:** Skills bleiben im Hauptkontext fuer kurze Tickets (1–2 AK). Fuer grosse Tickets explizit Agents per `Task` starten. Beides dokumentieren statt undokumentierten Doppelweg.

---

## Inspiration: Phase-Skills aus `search-backend`

Im Schwester-Projekt `~/devel/hoeffner/search-backend/.claude/skills/` liegen drei eigene Skills (`phase1-domain`, `phase2-plan`, `phase3-implement`), die einen deutlich schlankeren, disziplinierteren Ansatz fahren. Ein paar Ideen sind direkt auf Stillmoment uebertragbar.

### Was die Phase-Skills besser machen

#### I1: Status-Frontmatter mit klarer Phasen-Hierarchie
Statt `[ ]/[~]/[x]` haben die Phase-Artefakte ein YAML-Frontmatter mit explizitem Status:
```yaml
---
feature: query-understanding
phase: 2-plan
status: ready-for-phase-3
based-on: 01-spec.md
---
```
Jeder nachfolgende Skill prueft das Frontmatter und bricht ab oder fragt zurueck, wenn die Vorphase noch `draft` ist. **Behebt F3** elegant — Status ist im Artefakt selbst, kein Drift mit INDEX.md moeglich.

**Uebertragung:** Stillmoment-Plaene koennten ein `status: ready-for-implement`/`done` Frontmatter bekommen. `implement-ticket` prueft das, statt nur die Datei zu suchen.

#### I2: Goldene Regeln am Anfang jedes Skills
Jeder Phase-Skill hat 5–7 nummerierte **Goldene Regeln** ganz oben — kompakte Selbst-Disziplin (z. B. *„Eine Frage auf einmal"*, *„Konsistenz ≠ Korrektheit"*, *„Sparringspartner, nicht Fachautoritaet"*, *„Kein Code schreiben"* in Phase 2).

**Uebertragung:** `plan-ticket` und `review-code` koennten so eine Header-Section haben. Spart spaeter das implizite Hin-und-Her bei Edge-Cases.

#### I3: „Verworfene Alternativen" als Pflichtsektion im Plan
Phase 2 hat einen eigenen Abschnitt `## Verworfene Alternativen` — pro Verwerfung *ein Satz Variante + ein Satz Grund*. Macht Modellierungsentscheidungen explizit, statt sie implizit zu treffen.

**Uebertragung:** `plan-ticket` Vorlage hat heute `## Design-Entscheidungen (optional)` — ohne Zwang, Alternativen zu nennen. Sektion umbenennen und verpflichten: bei jeder Trade-off-Entscheidung mindestens eine verworfene Alternative dokumentieren.

#### I4: Phase-Trennung als harte Regel — kein Code-Lesen in „WAS"-Phase
Phase 1 (Domaene) verbietet explizit `grep`/`Read` auf Source-Files. Phase 2 erlaubt Code-Lesen, aber kein Schreiben. Phase 3 schreibt, aber **revidiert keine Plan-Entscheidungen** — bei Problemen wird zurueckgespiegelt, nicht eigenmaechtig korrigiert.

**Uebertragung:** Stillmoment macht das implizit (`create-ticket` schaut nicht in Code, `implement-ticket` aendert den Plan nicht). Aber explizit hinschreiben schafft Klarheit. Vor allem: **„Plan ist Gesetz"-Regel** in `implement-ticket` — wenn der Plan beim Bauen broeckelt, stoppen und zurueckspiegeln, statt schweigend abzuweichen. Heute fehlt diese Regel komplett.

#### I5: Mermaid-Ist/Soll-Diagramme im Plan
Phase 2 verlangt zwei Mermaid-Diagramme: Ist-Zustand und Soll-Zustand. Macht Architektur-Aenderungen visuell sofort lesbar.

**Uebertragung:** Sinnvoll fuer Stillmoment-Plaene mit Architektur-Anteil (z. B. Audio-Pipeline-Aenderungen, neue Layer-Verbindungen). Nicht zwingend — viele Stillmoment-Tickets sind reine Polish/UI-Tickets, da waere ein Mermaid-Zwang Overkill. Vorschlag: optional, aber Vorlage sollte Mermaid-Block-Skelette anbieten.

#### I6: Eine-Frage-auf-einmal-Disziplin
Mehrere Phase-Skills haben *„Pflege intern eine Liste offener Fragen, stelle aber dem Mob immer nur die naechste, wichtigste"* als explizite Regel. Verhindert Fragenketten, die User ueberfordern.

**Uebertragung:** Speziell `plan-ticket` Schritt 3 (API-Recherche) und Schritt 6 (Plan schreiben) profitieren — heute werden Annahmen oft im Plan einfach gesetzt, statt eine Klaerung anzustossen.

#### I7: „Konsistenz ≠ Korrektheit"-Hinweis
Phase 1 sagt explizit: *„Du kannst eine in sich konsistente, gut strukturierte Spec erzeugen, die fachlich falsch ist — gerade weil sie sauber aussieht, ist sie schwerer zu hinterfragen."* Skill schreibt explizit, eigene Vorschlaege als Annahme zu markieren.

**Uebertragung:** Wertvoll fuer `plan-ticket`. Heute liest der Plan oft wie eine fertige Architektur-Entscheidung, obwohl manche Annahmen ungeprueft sind. Markierung als *„Annahme — bitte bestaetigen"* macht Reviewability besser.

### Was nicht passt

- **Mob-Programming-Sprache** (*„Das Mob liest gemeinsam, oft im Stehen"*) — Stillmoment ist Solo-Entwicklung. Sprachlich anpassen.
- **Jupyter-Notebook als Code-Doku** (Phase 3) — geniale Idee fuer Python, aber iOS/Android haben kein direktes Aequivalent. Swift Playgrounds koennten theoretisch, aber der Aufwand rechtfertigt sich nicht. Tests sind die Code-Doku.
- **3-Phasen-Modell** als Ersatz — Stillmoment braucht zusaetzlich `review-code` und `close-ticket` (Doku-/Status-Disziplin), die in den Phase-Skills fehlen. **Nicht ersetzen, sondern Ideen eingemeinden.**

---

## Offizielle Anthropic-Plugins: Was passt, was nicht?

Marketplace `claude-plugins-official` ([github.com/anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official), 35+ Plugins).

### Direkt einsetzbar als Lueckenschluss

#### `commit-commands`
Drei Slash-Commands:
- `/commit` — Standard-Commit (waere fuer Stillmoment-Konvention `<type>(<platform>): #<id>` anzupassen)
- `/commit-push-pr` — Commit + Push + PR
- **`/clean_gone`** — Loescht lokale Branches deren Remote weg ist, inkl. Worktrees

**Empfehlung:** Installieren. `/clean_gone` schliesst Finding F8 direkt (`/plugin install commit-commands@claude-plugins-official`). `/commit` ggf. via lokaler Override anpassen.

### Komplementaer (kein Ersatz, aber Mehrwert)

#### `code-review` (bereits installiert)
Slash-Command `/code-review` mit Multi-Agent-Pipeline: Haiku-Eligibility-Check → 5 parallele Sonnet-Agents (CLAUDE.md-Adhaerenz, Bugs, git-blame-Kontext, frueheres-PR-Feedback, Code-Comments) → Haiku-Confidence-Score → Filter <80 → `gh pr comment`.

**Bewertung:** Stark fuer **Github-PRs**. Stillmoment merged ueblicherweise lokal nach main (8 Merges, 99 Pushes — also kaum PRs in der Praxis). Daher: Nicht als Ersatz fuer `/review-code`, aber **wenn man auf PR-basierten Flow umsteigt**, sehr stark.

#### `pr-review-toolkit`
6 Spezialist-Agents: `comment-analyzer`, `pr-test-analyzer`, `silent-failure-hunter`, `type-design-analyzer`, `code-reviewer`, `code-simplifier`. Slash-Command `/pr-review-toolkit:review-pr` bundelt sie.

**Bewertung:** **Inspiration fuer `/review-code`**. Besonders `silent-failure-hunter` (passt zu CLAUDE-Regel "Ignoring errors with `try!` or empty catch blocks") und `pr-test-analyzer` (passt zur "Sinnvolle Tests"-Philosophie). Die heutigen `review-code/checklists/`-Dateien decken aber das gleiche Spektrum ab. Kein Auto-Ersatz, aber: wenn man die Eigen-Skills modularisiert, koennten die Agents als Sub-Agents pro Aspekt eingebaut werden.

#### `code-simplifier` (Standalone-Plugin)
Single-Agent fuer Code-Simplifikation. **Bereits ueber `simplify`-Skill in der Liste verfuegbar.** Komplementaer zu `review-code`.

### Nicht passend

#### `feature-dev`
7-Phasen-Workflow Discovery → Codebase-Exploration → Clarifying Questions → Architecture → Implementation → Quality Review → Summary. Drei Agents (`code-architect`, `code-explorer`, `code-reviewer`).

**Bewertung:** Zielt auf **ungeplantes Feature-Engineering**, nicht auf Ticket-Disziplin. Kein Akzeptanzkriterien-Konzept, keine TDD-Loop, keine INDEX-Verwaltung. Wuerde den Stillmoment-Workflow ersetzen, aber **schlechter** — Ticket-/Doku-Disziplin geht verloren. **Nicht uebernehmen.** Aber: die Idee, parallele `code-explorer`-Agents fuer Codebase-Analyse zu starten, koennte `/plan-ticket` Schritt 2 beschleunigen.

#### `code-modernization`, `code-review` (PR-only), `claude-md-management`, `session-report`, `skill-creator`
- `code-modernization`: Legacy-Migration, off-topic.
- `claude-md-management`: nett, aber fuer aktuellen Workflow nicht zentral.
- `session-report`: koennte Handoffs zwischen Sessions verbessern, aber das Memory-System loest das schon.
- `skill-creator`: relevant **wenn Skills weiterentwickelt werden**, also fuer die Umsetzung dieser Analyse.

### Eingebaute Claude-Code-Befehle (nicht Plugin)

- `/init` — initialisiert CLAUDE.md (in Stillmoment bereits gepflegt).
- `/review` — generischer PR-Review.
- `/security-review` — Security-Scan der pending changes. **Keine Entsprechung im Custom-Setup**, koennte vor jedem Push laufen.

---

## Inspiration: Community Best Practices

Aus [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) (kuratierte Sammlung von Patterns von Boris Cherny, Thariq, Lydia Hallie, Cat Wu, Matt Pocock u. a.). Hier nur Punkte, die ueber die bisher genannten Findings hinaus konkret auf Stillmoment anwendbar sind.

### Direkt einsetzbar (klein, hoher Hebel)

#### B1: Dynamic Injection — `!command` in SKILL.md (Lydia Hallie)
SKILL.md kann Shell-Output **zur Prompt-Zeit injizieren**. Beispiel:
```markdown
## Kontext
- Aktueller Branch: !`git branch --show-current`
- Status: !`git status --short`
- Aktuelle Tickets in Arbeit: !`grep '\\[~\\]' dev-docs/tickets/INDEX.md`
```
Spart manuelle Bash-Calls am Skill-Anfang und macht Output deterministisch.

**Uebertragung:**
- `close-ticket`: `!git status` und `!git branch --merged main | grep <id>` direkt am Anfang einbetten — automatischer Branch-/Sauberkeits-Check ohne extra Tool-Calls.
- `implement-ticket`: `!git branch --show-current` und `!git log -1 --oneline` injizieren, um Plan-Verweis und Branch-Status sofort zu sehen.

Das offizielle `commit-commands` Plugin nutzt das schon (`/commit` injiziert `!git status`, `!git diff HEAD`, `!git branch --show-current`, `!git log --oneline -10`).

#### B2: „Gotchas"-Sektion in jeden Skill (Thariq, Anthropic)
Skills sollen eine **Gotchas-Sektion** haben, die ueber Zeit Fehlerpunkte sammelt — *„hoechster Signal-Gehalt"*. Statt Fehler nur in Memory zu schreiben, wandern wiederkehrende Stolpersteine in den Skill, der sie produziert.

**Uebertragung:** Stillmoment hat solches Wissen heute in `MEMORY.md` (z. B. „Convenience init() beim Hinzufuegen neuer Dependencies pruefen", „Mock-Verfuegbarkeit vor ViewModel-Tests pruefen"). Diese gehoeren naeher an den Ort, wo sie greifen — `implement-ticket` sollte eine `## Gotchas`-Sektion bekommen mit genau diesen Punkten. Memory bleibt als Backup, aber der Skill wird selbsterklaerend.

#### B3: Skill-Description als Trigger, nicht als Beschreibung (Thariq)
Description soll *„wann sollte ich feuern?"* beantworten, nicht *„was macht das?"*. Stillmoment-Skills sind heute Mischung — `create-ticket` hat es richtig (*„Aktiviere bei …"*), `review-code` schwammiger (*„Aktiviere bei Ticket-Abschluss, Code-Review-Anfragen, oder wenn der User nach Qualitaetspruefung fragt"* — viele Trigger ohne Kontur).

**Uebertragung:** Descriptions sharpening, besonders bei `review-code` und `plan-ticket`. Klarer machen *wann nicht* (siehe `plan-ticket` Schritt „Wann diesen Skill NICHT nutzen" — gehoert nach oben in die Description, damit Auto-Trigger nicht zu eifrig feuert).

#### B4: Stop Hook fuer Verify-Step (Boris Cherny)
PostToolUse-Hooks gibts schon (`swift-format`). **Stop Hook** stuppt Claude an, beim Session-Ende einen Verify-Step zu machen. Beispiel: nach jedem Ticket-Close ein automatischer `make test-unit-agent` als Sicherheits-Check.

**Uebertragung:** Niedrigere Prio, aber praktisch: vor `git push` automatisch `make check`. Heute laeuft das nur in `implement-ticket` Schritt 4 — wenn man manuell pusht (was die Statistik zeigt: 99 Pushes), kein Schutz.

### Workflow-Patterns (Inspiration, nicht Pflicht)

#### B5: Vertical Slices statt Horizontal Phasing (Matt Pocock, Pragmatic Programmer)
Bei Multi-Akzeptanzkriterien-Tickets: Pro Iteration **DB+Service+UI** (vertical), nicht **erst alle DB-Sachen, dann alle Services, dann alle UIs** (horizontal). Tracer-Bullets statt Big-Bang-Integration.

**Uebertragung:** `plan-ticket` Schritt „Reihenfolge der Akzeptanzkriterien" sagt heute *„Domain → ViewModel → View"* (horizontal). Bei Tickets mit mehreren AKs waere besser: AK1 komplett (Domain+VM+View+Test), dann AK2 komplett. Funktioniert nur bei sauber geschnittenen AKs — ist im Stillmoment-Setup oft schon der Fall.

#### B6: Challenge-Prompts in `review-code` (Boris Cherny)
*„grill me on changes & don't PR until I pass your test"* — Reviewer hinterfragt aktiv statt nur Findings sammelt. Weniger pflichtbewusste Checklist-Abarbeitung, mehr provokante Frage-Stellung.

**Uebertragung:** `review-code` ist heute Checklisten-orientiert (5 Kategorien). Erweiterung: Bei Architektur-Tickets eine Challenge-Phase einfuegen — *„Was ist das einfachste Szenario, in dem dieser Code falsch ist?"* — und 1 Beispiel konkret durchspielen.

#### B7: Squash Merge als Konvention (Boris Cherny)
*„Always squash merge"* — saubere lineare History, einfacher `git revert`, sauberer `git bisect`. Stillmoment-History ist Mix aus Squash-Style und echten Merge-Commits (`Merge feature/shared-087-ios: …`).

**Uebertragung:** Falls bewusst gewaehlt — okay. Falls nicht: in `close-ticket` als Konvention dokumentieren (oder `commit-commands`-Plugin entsprechend konfigurieren).

#### B8: Subagent als Context-Cleaner (Thariq)
*„20 file reads + 12 greps bleiben in Child, nur Report zurueck"* — passt zu F12. Konkrete Faustregel: Wenn ein Skill-Schritt mehr als ~5 Datei-Reads oder Greps macht, im Sub-Agent ausfuehren.

**Uebertragung:** `review-code` Schritt 2 („Code lesen — Implementierung, Tests, Abhaengigkeiten") ist genau so ein Fall. Heute laeuft das im Hauptkontext und blaeht ihn auf. Ein Sub-Agent (z. B. `Explore` oder `ticket-reviewer`) der nur den verdichteten Befund zurueckgibt, waere sauberer.

### Modell-Empfehlung gegenchecken

Boris Chernys Empfehlung: **Plan = Opus, Implementation = Sonnet** — also umgekehrt zu meinem F10-Vorschlag (`plan-ticket` = Sonnet, `implement-ticket` = Opus).

Beide Sichten haben Substanz:
- *Plan = Opus*: Architektur-Reasoning, Trade-off-Bewertung, API-Recherche profitiert von extended thinking.
- *Implement = Opus*: TDD + Refactoring + iOS-Edge-Cases sind anspruchsvoll.

**Empfehlung:** Stillmoment-Plaene sind oft strukturell einfach (Datei-Liste, kleine Refactorings). Implementation ist anspruchsvoller. Daher: **F10-Vorschlag bleibt** (plan=Sonnet, implement=Opus), mit der Option, bei rein-architektonischen Tickets fuer `plan-ticket` per `--model opus` zu uebersteuern. Oder: beide auf Sonnet, Opus nur bei Bedarf — und beobachten, wie Qualitaet ausfaellt.

### CLAUDE.md schlanker (HumanLayer / Boris Cherny)

- *„< 200 Zeilen pro File"* (Boris Cherny), *„60 Zeilen optimal fuer hoechste Compliance"* (HumanLayer)
- Stillmoment `CLAUDE.md` (root) hat ~150 Zeilen — okay.
- `ios/CLAUDE.md` und `android/CLAUDE.md` sind plattformspezifisch — gut.
- **`<important if="...">`-Tags** als Stop-Ignore-Pattern bei wachsender CLAUDE.md (HumanLayer).
- **`.claude/rules/*.md`** mit `paths:`-Frontmatter fuer Lazy-Loading nur bei Datei-Match — relevant fuer wachsende Regelsammlungen, heute nicht akut.

### Bewusst nicht uebernehmen

- **Gesamte Workflow-Frameworks** (`Superpowers`, `BMAD-METHOD`, `Get Shit Done`, `gstack`, `Spec Kit`) — fuer kleine Solo-Projekte Overkill, eigene Disziplin reicht.
- **`/ultraplan`, `/ultrareview`**: bezahlte Mehragenten-Cloud-Reviews. Bei Stillmoments lokalem Flow nicht passend.
- **Computer-Use, Voice Dictation, Chrome Extension** — orthogonal zum Workflow.
- **Permission-Management `/sandbox`**: heute reichen die Allow-Listen in `settings.local.json`.

---

## Konkrete Aenderungs-Roadmap

### Sofort (1 Stunde)

1. **F1**: `implement-ticket` Schritt 1 um `pull --rebase main` erweitern
2. **F5**: `implement-ticket` Schritt 3 um Subagent-Wrapper fuer Tests
3. `commit-commands`-Plugin installieren — `/clean_gone` als Lueckenschluss fuer F8
4. Modell-Frontmatter setzen (F10): haiku fuer create/close, sonnet fuer plan/review, opus fuer implement

### Mittelfristig (halber Tag)

5. **F2**: `plan-ticket` Schritt 6b (Plan-Commit-Konvention) ergaenzen
6. **F3**: Status-Inkonsistenz beheben — entweder INDEX.md auf `[~]` mitziehen oder Status-Update zentralisieren
7. **F7**: `review-code` Schritt 5 bedingt machen (nur bei Aenderungen seit letztem Commit)
8. **F11**: `plan-ticket` Schritt 8 auf Kurzfassung beschraenken

### Optional / Diskussion

9. **F4**: `review-code` strikt read-only machen (Fix-Schritt entfernen) — oder explizit als Mischmodus dokumentieren
10. **F6**: `close-ticket` AK-Pruefung als Quick-Check, wenn Review-Report vorliegt
11. **F12**: Klare Regel "wann Hauptkontext, wann ticket-implementer/ticket-reviewer-Agent"
12. **F9**: `close-ticket` prueft Branch-Status (gemerged?, sauber?)

### Inspiration einarbeiten (search-backend)

13. **I1**: Status-Frontmatter auf Plaenen einfuehren (`status: ready-for-implement`/`done`) — beseitigt INDEX-Drift (loest F3 sauberer als der dort vorgeschlagene Fix)
14. **I2**: Goldene-Regeln-Section am Anfang jedes Skills (besonders `plan-ticket`, `review-code`)
15. **I3**: `plan-ticket` Vorlage — "Verworfene Alternativen" als Pflichtsektion statt optional
16. **I4**: "Plan ist Gesetz"-Regel in `implement-ticket` — bei Plan-Konflikten stoppen und zurueckspiegeln, nicht schweigend abweichen
17. **I6**: Eine-Frage-auf-einmal-Disziplin in `plan-ticket` (besonders bei API-Recherche und Annahmen)
18. **I7**: Annahmen in Plaenen explizit markieren (`??? Annahme — bitte bestaetigen`) — Konsistenz ≠ Korrektheit
19. **I5** (optional): Mermaid-Ist/Soll-Diagramme als optionale Vorlage in `plan-ticket` fuer Architektur-Tickets

### Community-Best-Practices einarbeiten

20. **B1**: Dynamic Injection (`!git status` etc.) in `close-ticket` und `implement-ticket` — automatischer Branch-/Sauberkeits-Check ohne Tool-Calls
21. **B2**: `## Gotchas`-Sektion in jeden Skill — wiederkehrende Stolpersteine aus Memory naeher an den Skill bringen
22. **B3**: Skill-Descriptions sharpening (Trigger-Fokus) — besonders `review-code` und `plan-ticket`
23. **B8**: Sub-Agent fuer Code-Reading in `review-code` Schritt 2 (Hauptkontext schonen)
24. **B6** (optional): Challenge-Phase in `review-code` fuer Architektur-Tickets („Was ist das einfachste Szenario, in dem das falsch ist?")
25. **B7** (optional): Squash-Merge-Konvention dokumentieren oder bewusst Mix-Strategy festhalten
26. **B5** (optional): Vertical Slices in `plan-ticket` „Reihenfolge der Akzeptanzkriterien" — pro AK alle Layer durch, nicht pro Layer alle AKs

### Modell-Strategie nochmal entscheiden (F10 vs. B-Empfehlung)

Boris Cherny empfiehlt **plan=Opus, implement=Sonnet**, F10 schlaegt umgekehrt vor. Vor der Adoption: Bewusst entscheiden:
- Stillmoment-Plaene meist strukturell einfach → Sonnet okay (F10-Vorschlag)
- Stillmoment-Implementation TDD-/iOS-anspruchsvoll → Opus rechtfertigt sich (F10-Vorschlag)
- Alternativ: beide auf Sonnet, Opus nur per `--model opus` Override
- Empfehlung: **F10 testen, beobachten, ggf. anpassen**

### Nicht uebernehmen (bewusst)

- **`feature-dev`** als Ersatz: zu generisch, zerstoert Ticket-Disziplin.
- **`code-review`** als Ersatz fuer `/review-code`: PR-zentriert, passt nicht zum lokal-Merge-Flow.
- Vollumstellung auf `pr-review-toolkit`: Eigen-Skills sind besser auf Stillmoment-Patterns abgestimmt.

---

## Anhang: Modell-Verteilung in Sessions

Aus 13 ausgewerteten Sessions:

| Modell | Calls | Anteil |
|---|---|---|
| `claude-opus-4-7` | 5430 | 84 % |
| `claude-opus-4-6` (fast mode) | 788 | 12 % |
| `claude-sonnet-4-6` | 578 | 9 % |

Aktuell wird Sonnet praktisch nur ueber den `ticket-reviewer`-Agent angefasst. Mit Modell-Frontmatter in den Skills wuerde sich das Bild deutlich verschieben.
