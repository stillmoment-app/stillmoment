# Ticket-Implementierungs-Pipeline

## Status

Konzept - revidiert nach kritischer Bewertung

---

## Problem

Die autonome Ticket-Implementation (`scripts/implement-ticket.sh`) orchestriert Claude-Code-Agents ueber ein Bash-Script:

```
IMPLEMENT (Opus) → REVIEW (Sonnet) → FIX-Loop → CLOSE (Opus) → LEARN (Opus)
```

Das funktioniert (14+ erfolgreiche Laeufe), hat aber strukturelle Schwaechen:

1. **Schwer lesbar**: ~500 Zeilen Bash die Git-Operationen, Agent-Invocation, Progress-Monitoring (eingebettetes Python!), Log-Parsing (grep/awk/sed), Error-Handling und Konfiguration vermischen.

2. **Log-Parsing im falschen Werkzeug**: Marker-Bloecke extrahieren, Verdicts pruefen, Challenges sammeln — das ist strukturierte Textverarbeitung, nicht Bash-Domaene. Das Script hat bereits eingebettetes Python fuer Progress-Monitoring — ein Eingestaendnis.

3. **Fragiles Error-Handling**: `set -e` + Subshells + Pipes = unvorhersehbares Verhalten. Konkreter Bug: `grep ... || true` schluckte den xcodebuild Exit-Code.

4. **Ein Agent, vier Jobs**: `ticket-implementer` wird fuer IMPLEMENT, FIX, CLOSE und LEARN verwendet. Agent-Dateien werden vom Script via `--allowedTools` ueberschrieben und sind teilweise irrefuehrend.

5. **Fehlende Phasen**: Kein Ticket-Verstaendnis vor der Implementierung, kein Implementierungsplan. Der Agent springt direkt in den Code.

---

## Loesung

Ein leichtgewichtiges Python-Script das das Bash-Script ersetzt. Kein Package, kein Framework, keine Abstraktionen fuer hypothetische Zukunft.

```
scripts/
  implement-ticket.py    # ~200-300 Zeilen, ersetzt implement-ticket.sh
```

Aufruf:

```bash
uv run scripts/implement-ticket.py ios-032 --platform ios
uv run scripts/implement-ticket.py ios-032 --platform ios --auto  # ohne Gates
```

### Was das Script tut

- Phasen sequenziell ausfuehren (`claude --agent ... --append-log ...`)
- Log-Abschnitte parsen (Verdict, Blockers, Questions, Challenges)
- Den Review/Fix-Loop steuern
- Gates handhaben (Fragen anzeigen, Antworten einlesen, Plan zur Genehmigung zeigen)
- Am Ende: Challenges und NEEDS_INPUT-Items dem User anzeigen

### Was das Script NICHT tut

- Keine eigenen Klassen oder Abstraktionen — Phasen sind Funktionen
- Keine generische Workflow-Engine — hartcodierte Reihenfolge
- Keine Portierbarkeit — dieses Script, dieses Projekt
- Kein LEARN-Agent — Challenges werden dem User angezeigt, er entscheidet was in MEMORY.md kommt

---

## Pipeline

```
UNDERSTAND → [Gate] → PLAN → [Gate] → IMPLEMENT → REVIEW/FIX-Loop → CLOSE
                                                                       │
                                                          Challenges + NEEDS_INPUT
                                                          werden dem User angezeigt
```

Fuenf Phasen, zwei Gates. UNDERSTAND und PLAN koennen auf User-Input warten. Der Rest laeuft autonom.

---

## Drei Agents

Die Aufteilung folgt drei Kriterien: unterschiedliche Tool-Rechte, unterschiedliche Denkweisen, sinnvolle Model-Wahl.

| Agent-Datei | Phasen | Model | Rechte | Charakter |
|-------------|--------|-------|--------|-----------|
| `ticket-planner.md` | UNDERSTAND, PLAN | Opus | Read-only | Analytisch: Ticket verstehen, Plan schreiben |
| `ticket-implementer.md` | IMPLEMENT, FIX, CLOSE | Opus | Read-write | Handwerklich: TDD, Code schreiben, Ticket schliessen |
| `ticket-reviewer.md` | REVIEW | Sonnet | Read-only | Kritisch: Findings klassifizieren, nicht fixen |

### Begruendung fuer drei (nicht sechs)

**Planner = UNDERSTAND + PLAN.** Beides ist Read-only-Analyse. Der Planner prueft das Ticket, stellt Fragen, und schreibt dann den Plan. Zwei separate Agents wuerden Kontext verlieren — der Planner muesste den UNDERSTAND-Output aus dem Log rekonstruieren statt sein eigenes Verstaendnis zu nutzen.

**Implementer = IMPLEMENT + FIX + CLOSE.** Alles braucht Schreibzugriff und Code-Verstaendnis. CLOSE ist ein `/close-ticket`-Aufruf — kein eigener Agent noetig.

**Reviewer bleibt separat.** Read-only-Rechte erzwingen die richtige Denkweise: analysieren statt fixen. Sonnet statt Opus ist ausreichend und guenstiger.

**LEARN entfaellt als Agent.** Ein LLM das selbst entscheidet was "gelernt" werden soll produziert oft Noise. Stattdessen: Das Script sammelt Challenges und zeigt sie am Ende an. Der Entwickler entscheidet was in MEMORY.md kommt.

---

## Phasen im Detail

### Phase 1: UNDERSTAND

**Zweck:** Ticket verstehen, Aktualitaet pruefen, Rueckfragen identifizieren.

**Agent:** `ticket-planner` (Opus, Read-only)

**Was wird gemacht:**
- Ticket lesen und Akzeptanzkriterien verstehen
- Pruefen ob referenzierter Code noch existiert (Dateien, Klassen, Funktionen)
- Pruefen ob es Konflikte mit kuerzlich geaenderten Bereichen gibt (`git log`)
- Pruefen ob Abhaengigkeiten zu anderen Tickets bestehen (INDEX.md)
- Unklarheiten und Rueckfragen identifizieren
- Einschaetzung der Komplexitaet

**Tools:** Read, Glob, Grep, Bash (git read-only)

**Output → Log:**
```markdown
## UNDERSTAND
Status: READY | QUESTIONS

Assessment:
- Ticket ist aktuell, referenzierter Code existiert
- Geschaetzte Komplexitaet: [niedrig|mittel|hoch]
- Betroffene Bereiche: [Dateien/Module]

Questions:
<!-- QUESTIONS_START -->
- [Frage 1 mit Kontext warum die Frage relevant ist]
- [Frage 2 ...]
<!-- QUESTIONS_END -->

Dependencies:
- [Abhaengigkeiten zu anderen Tickets, falls vorhanden]
```

**Gate:**
- Status `READY` → automatisch weiter zu PLAN
- Status `QUESTIONS` → Workflow pausiert, Fragen werden im Terminal angezeigt
- User beantwortet Fragen → Antworten als `User-Answers:` ins Log → weiter zu PLAN
- `--auto` Modus: Wenn Questions vorhanden → Abbruch

**Abbruch:** Ticket nicht gefunden, Ticket bereits geschlossen, User bricht ab.

---

### Phase 2: PLAN

**Zweck:** Implementierungsplan schreiben — konkrete Schritte, betroffene Dateien, Test-Strategie.

**Agent:** `ticket-planner` (Opus, Read-only) — selber Agent wie UNDERSTAND, behaelt Kontext.

**Was wird gemacht:**
- Assessment und eventuelle User-Antworten aus UNDERSTAND nutzen
- Relevanten bestehenden Code analysieren (Patterns, Konventionen)
- Plattformspezifische CLAUDE.md lesen
- Schritt-fuer-Schritt Implementierungsplan schreiben
- Test-Strategie definieren
- Risiken dokumentieren

**Tools:** Read, Glob, Grep, Bash (git read-only, make read-only)

**Output → Log:**
```markdown
## PLAN
Status: DONE

Approach:
[2-3 Saetze zur gewaehlten Herangehensweise und Begruendung]

Steps:
1. [Konkreter Schritt - was wird wo geaendert]
2. [Konkreter Schritt]
3. ...

Test-Strategy:
- [Welche Tests werden geschrieben]
- [Welche Szenarien werden abgedeckt]
- [Welche bestehenden Tests muessen angepasst werden]

Files:
- [Datei 1 - was wird geaendert]
- [Datei 2 - neu erstellt]

Risks:
- [Potenzielle Risiken und wie sie mitigiert werden]
```

**Gate:**
- Plan wird im Terminal angezeigt
- User approved → weiter zu IMPLEMENT
- User gibt Feedback → Plan wird angepasst (Agent erneut mit Feedback, max 3 Iterationen)
- User bricht ab → Workflow endet
- `--auto` Modus: Plan wird automatisch akzeptiert

**Begruendung fuer das Gate:** Der Plan ist der Vertrag zwischen Mensch und Maschine. Lieber 2 Minuten Review hier als 20 Minuten Revert spaeter.

**Abbruch:** User lehnt Plan ab und will nicht iterieren, Ticket zu vage fuer Plan.

---

### Phase 3: IMPLEMENT

**Zweck:** Code implementieren gemaess Plan und Projektstandards.

**Agent:** `ticket-implementer` (Opus, Read-write)

**Was wird gemacht:**
- Plan aus Log lesen und Schritt fuer Schritt abarbeiten
- TDD-Workflow: Test rot → Code gruen → Refactor
- `make check` + `make test-unit` vor jedem Commit
- Logische Einheiten committen
- Challenges dokumentieren (Stolpersteine, Workarounds, unerwartetes Verhalten)

**Tools:** Read, Glob, Grep, Edit, Write, Bash (make, git add/commit/status/diff/log)

**Output → Log:**
```markdown
## IMPLEMENT
Status: DONE

Commits:
- <hash> <message>
- <hash> <message>

Challenges:
<!-- CHALLENGES_START -->
- [Was unerwartet war, Workarounds, Erkenntnisse]
<!-- CHALLENGES_END -->

Deviations:
- [Abweichungen vom Plan mit Begruendung, falls vorhanden]

Summary:
[2-3 Saetze was gemacht wurde]
```

**Kein Gate.** Laeuft autonom.

**Abbruch:** `make check`/`make test-unit` schlaegt wiederholt fehl, max-turns erreicht, IMPLEMENT-Abschnitt fehlt im Log.

---

### Phase 4: REVIEW / FIX Loop

#### 4a: REVIEW

**Zweck:** Code gegen Projektstandards und Akzeptanzkriterien pruefen.

**Agent:** `ticket-reviewer` (Sonnet, Read-only)

**Was wird gemacht:**
- Aenderungen gegen Ticket-Akzeptanzkriterien pruefen
- `/review-code` ausfuehren (Wartbarkeit, Architektur, Lesbarkeit, Testabdeckung)
- `/review-localization` ausfuehren (Uebersetzungen, ungenutzte Keys)
- `make check` + `make test-unit` ausfuehren
- Findings klassifizieren: BLOCKER, NEEDS_INPUT, DISCUSSION
- Abweichungen vom Plan (Deviations) bewerten

**Tools:** Read, Glob, Grep, Bash (make, git diff/log), Skills (review-code, review-localization)

**Output → Log:**
```markdown
## REVIEW <n>
Verdict: PASS | FAIL

make check: OK | FAIL
make test-unit: OK | FAIL

Plan-Adherence:
- [Bewertung ob Deviations gerechtfertigt sind]

BLOCKER:
- datei:zeile - Beschreibung des Problems

NEEDS_INPUT:
<!-- NEEDS_INPUT_START -->
- datei:zeile - Beschreibung, warum keine eindeutige Entscheidung moeglich ist
<!-- NEEDS_INPUT_END -->

DISCUSSION:
<!-- DISCUSSION_START -->
- datei:zeile - Verbesserungsvorschlag
<!-- DISCUSSION_END -->

Summary:
[Review-Zusammenfassung]
```

**Drei Kategorien von Findings:**

| Kategorie | Wirkung | Beispiel |
|-----------|---------|---------|
| **BLOCKER** | Fuehrt zu `FAIL`, muss gefixt werden | Fehlender Test, Security-Problem, Akzeptanzkriterium nicht erfuellt |
| **NEEDS_INPUT** | Kein `FAIL`, wird nach Workflow-Ende dem User angezeigt | Naming-Entscheidung mit gleichwertigen Optionen, Architektur-Frage ohne klare Antwort |
| **DISCUSSION** | Kein `FAIL`, Verbesserungsvorschlag fuer spaeter | Design-Alternative, Zukunfts-Verbesserung |

#### 4b: FIX

**Agent:** `ticket-implementer` (Opus, Read-write)

**Was wird gemacht:**
- BLOCKER-Findings aus dem letzten Review lesen
- Fixes implementieren
- `make check` + `make test-unit` vor Commit

**Tools:** Read, Glob, Grep, Edit, Write, Bash (make, git add/commit/status/diff/log)

**Output → Log:**
```markdown
## FIX <n>
Status: DONE

Commits:
- <hash> <message>

Challenges:
<!-- CHALLENGES_START -->
- [Neue Erkenntnisse aus dem Fix]
<!-- CHALLENGES_END -->

Summary:
[Was gefixt wurde, Bezug auf BLOCKER-Findings]
```

#### Loop-Logik

```
REVIEW → Verdict PASS?  → ja  → weiter zu CLOSE
                        → nein → FIX → REVIEW (naechste Runde)
                        → max erreicht → ABBRUCH
```

Maximal 5 Review-Runden (konfigurierbar). NEEDS_INPUT- und DISCUSSION-Items werden vom Script pro Runde gesammelt.

---

### Phase 5: CLOSE

**Zweck:** Ticket formal abschliessen.

**Agent:** `ticket-implementer` (Opus, Read-write) — selber Agent, nur anderer Prompt.

**Was wird gemacht:**
- `/close-ticket` Skill ausfuehren (Status in Ticket-Datei, INDEX.md, CHANGELOG.md)
- Commit erstellen

**Tools:** Read, Glob, Grep, Edit, Write, Bash (git add/commit), Skills (close-ticket)

**Output → Log:**
```markdown
## CLOSE
Status: DONE

Commits:
- <hash> <message>
```

**Kein Gate.** Laeuft autonom.

---

## Workflow-Ende

Nach Abschluss (oder Abbruch) zeigt das Script dem User:

1. **Challenges** aus allen IMPLEMENT/FIX-Abschnitten — der User entscheidet ob etwas in MEMORY.md gehoert
2. **NEEDS_INPUT-Items** die menschliche Entscheidung brauchen
3. **DISCUSSION-Items** als Verbesserungsvorschlaege fuer spaeter
4. **Zusammenfassung** (Commits, Phasen-Status, Dauer)

---

## Datenfluss

### Implementation-Log als Kommunikationskanal

Alle Phasen schreiben in dasselbe Log. Jede Phase liest den bisherigen Verlauf und haengt ihren Abschnitt an.

```
┌──────────────┐   ┌───────────┐   ┌────────┐   ┌───────┐
│ UNDERSTAND + │──▶│IMPLEMENT  │──▶│ REVIEW │──▶│ CLOSE │
│ PLAN         │   └───────────┘   └────────┘   └───────┘
└──────────────┘         │              │            │
       │                 ▼              ▼            ▼
       ▼         ┌────────────────────────────────────────┐
┌──────────────┐ │  Implementation-Log (append-only)      │
│ Log          │ │                                        │
│ + Gate-      │ │  ## UNDERSTAND  → Assessment, Q&A      │
│   Interaktion│ │  ## PLAN        → Plan, Test-Strategie │
└──────────────┘ │  ## IMPLEMENT   → Commits, Challenges  │
                 │  ## REVIEW 1    → Verdict, Findings    │
                 │  ## FIX 1       → Commits, Challenges  │
                 │  ## REVIEW 2    → Verdict (PASS)       │
                 │  ## CLOSE       → Commits              │
                 └────────────────────────────────────────┘
```

### Was das Script zwischen Phasen tut

| Uebergang | Script-Aktion |
|-----------|--------------|
| UNDERSTAND → PLAN | Questions/Answers pruefen. Wenn READY → PLAN-Prompt aufbauen |
| PLAN → IMPLEMENT | Plan-Gate: anzeigen, Approval einholen |
| IMPLEMENT → REVIEW | Pruefen ob IMPLEMENT-Abschnitt existiert |
| REVIEW → FIX | BLOCKER-Findings extrahieren, in FIX-Prompt einfuegen |
| REVIEW (PASS) → CLOSE | NEEDS_INPUT/DISCUSSION in separate Listen sammeln |

### Artefakte

| Datei | Inhalt |
|-------|--------|
| `logs/<ticket-id>.md` | Implementation-Log (Hauptartefakt) |

NEEDS_INPUT- und DISCUSSION-Items werden im Terminal angezeigt, nicht als separate Dateien gespeichert. Das Log enthaelt alles.

---

## Autonomer Modus

```bash
uv run scripts/implement-ticket.py ios-032 --platform ios --auto
```

| Phase | Interaktiv | `--auto` |
|-------|-----------|----------|
| UNDERSTAND | Questions → User antwortet | Questions → Abbruch |
| PLAN | Plan → User approved | Plan → automatisch akzeptiert |
| Rest | Identisch | Identisch |

---

## Abgrenzung zum bisherigen Konzept

Was gegenueber dem urspruenglichen Entwurf geaendert wurde und warum:

| Urspruenglich | Jetzt | Begruendung |
|--------------|-------|-------------|
| Generisches Python-Package (PyPI) | Einzelnes Python-Script | Ein Projekt, ein Consumer. YAGNI. |
| 6 Agent-Dateien | 3 Agent-Dateien | Trennung nur wo Tool-Rechte oder Denkweise sich unterscheiden |
| LEARN-Phase mit eigenem Agent | Challenges am Ende anzeigen | LLM-entschiedenes Learning produziert Noise. Mensch entscheidet. |
| PhaseSpec/PipelineStep/GateType Klassen | Funktionen + if-Statements | Keine Abstraktionen fuer einen einzelnen Workflow |
| Separate Dateien fuer NEEDS_INPUT/DISCUSSION | Terminal-Ausgabe am Ende | Log enthaelt alles, separate Dateien sind Overhead |
| Konfigurierbarer Workflow | Hartcodierte Reihenfolge | Flexibilitaet die niemand braucht ist Komplexitaet |

---

## Offene Fragen

1. **UNDERSTAND + PLAN als ein Agent-Lauf oder zwei?** Ein Lauf behaelt Kontext, zwei Laeufe erlauben ein Gate dazwischen. Aktueller Vorschlag: Zwei Laeufe mit demselben Agent, weil das PLAN-Gate (User-Approval) zwischen beiden liegen muss.
2. **Fehler-Recovery:** Soll das Script einen abgebrochenen Lauf fortsetzen koennen? Das Log ist append-only — theoretisch moeglich, aber erhoeht die Komplexitaet. Erstmal: Neustart.
3. **PLAN-Iterationen:** Max 3 Feedback-Runden beim Plan-Gate, dann Abbruch. Reicht das?
4. **Kosten-Tracking:** `claude` CLI gibt Kosten aus. Das Script koennte sie pro Phase sammeln und am Ende anzeigen. Nice-to-have, nicht kritisch.
