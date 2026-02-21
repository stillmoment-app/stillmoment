# ticket-flow: Visueller Guide

> Generischer Agent-Orchestrator fuer Claude Code.
> Basiert auf: [ticket-flow-orchestrator.md](ticket-flow-orchestrator.md)

---

## 1. Big Picture

**Problem:** Ein 500-Zeilen Bash-Script orchestriert AI-Agents. Es funktioniert, ist aber nicht portierbar, nicht testbar und vermischt alles.

**Loesung:** Ein Python-Tool (`ticket-flow`) trennt Mechanik von Konfiguration.

```mermaid
graph TB
    subgraph "ticket-flow (generisch, Python)"
        Engine[Workflow Engine]
        Runner[Agent Runner]
        Logs[Log Manager]
        Progress[Progress Monitor]
        Git[Git Ops]
        Gates[Interactive Gates]
    end

    subgraph "Projekt-Konfiguration (z.B. Still Moment)"
        Agents[".claude/agents/<br/>Agent-Instruktionen"]
        Skills[".claude/skills/<br/>Projektspezifische Skills"]
        Workflow[".claude/workflows/<br/>Pipeline-Definition"]
    end

    Engine -->|liest| Workflow
    Runner -->|nutzt| Agents
    Runner -->|nutzt| Skills

    style Engine fill:#4a6fa5,color:#fff
    style Runner fill:#4a6fa5,color:#fff
    style Logs fill:#4a6fa5,color:#fff
    style Progress fill:#4a6fa5,color:#fff
    style Git fill:#4a6fa5,color:#fff
    style Gates fill:#4a6fa5,color:#fff
    style Agents fill:#6b8f71,color:#fff
    style Skills fill:#6b8f71,color:#fff
    style Workflow fill:#6b8f71,color:#fff
```

**Kernidee:** Der Workflow (Phasen, Review-Loop, Gates) ist ueberall gleich. Nur Agents, Skills und Quality-Gates sind projektspezifisch.

---

## 2. Pipeline-Ueberblick

Sechs Phasen. Zwei interaktive Gates. Ein Review/Fix-Loop.

```mermaid
flowchart LR
    U[UNDERSTAND] -->|Gate| P[PLAN]
    P -->|Gate| I[IMPLEMENT]
    I --> R[REVIEW]
    R -->|PASS| C[CLOSE]
    R -->|FAIL| F[FIX]
    F --> R
    C --> L[LEARN]

    U:::interactive
    P:::interactive
    I:::autonomous
    R:::autonomous
    F:::autonomous
    C:::autonomous
    L:::autonomous

    classDef interactive fill:#e8a838,color:#000,stroke:#c78c2e,stroke-width:2px
    classDef autonomous fill:#4a6fa5,color:#fff,stroke:#3a5f95,stroke-width:2px
```

| Farbe | Bedeutung |
|-------|-----------|
| Orange | Interaktiv — wartet auf User-Input |
| Blau | Autonom — laeuft ohne Eingriff |

---

## 3. Phasen im Detail

### 3.1 UNDERSTAND + PLAN (die interaktiven Phasen)

```mermaid
flowchart TD
    Start([Ticket-ID]) --> U

    subgraph UNDERSTAND ["Phase 1: UNDERSTAND (Sonnet)"]
        U[Ticket lesen<br/>Code pruefen<br/>Abhaengigkeiten checken]
        U --> Q{Rueckfragen?}
        Q -->|Nein| Ready[Status: READY]
        Q -->|Ja| Show[Fragen anzeigen]
        Show --> Wait[Auf User warten]
        Wait --> Answer[Antworten ins Log]
        Answer --> Ready
    end

    Ready --> P

    subgraph PLAN ["Phase 2: PLAN (Opus)"]
        P[Code analysieren<br/>Konventionen lesen<br/>Plan schreiben]
        P --> ShowPlan[Plan anzeigen]
        ShowPlan --> Approve{User?}
        Approve -->|Approved| Done[Weiter]
        Approve -->|Feedback| P
        Approve -->|Abbruch| Abort([Ende])
    end

    Done --> Impl([IMPLEMENT])

    style UNDERSTAND fill:#fdf0d5,stroke:#e8a838
    style PLAN fill:#fdf0d5,stroke:#e8a838
```

**Warum zwei Gates?**
- UNDERSTAND fragt *bevor* geplant wird: Ist das Ticket noch aktuell? Fehlen Infos?
- PLAN ist der Vertrag: 2 Minuten Review hier sparen 20 Minuten Revert spaeter.

### 3.2 IMPLEMENT (die autonome Arbeitsphase)

```mermaid
flowchart TD
    Start([Genehmigter Plan]) --> Read[Plan aus Log lesen]
    Read --> TDD

    subgraph TDD ["TDD-Zyklus (Opus)"]
        direction TB
        Red[Test schreiben<br/>rot] --> Green[Code schreiben<br/>gruen]
        Green --> Refactor[Refactoren]
        Refactor --> Check{make check<br/>+ test-unit}
        Check -->|OK| Commit[Commit]
        Check -->|Fail| Green
        Commit --> More{Weitere<br/>Schritte?}
        More -->|Ja| Red
    end

    More -->|Nein| Log[Commits + Challenges<br/>+ Deviations ins Log]
    Log --> Next([REVIEW])

    style TDD fill:#e8f4ea,stroke:#6b8f71
```

**Deviations:** Wenn der Implementer vom Plan abweichen muss, dokumentiert er das explizit. Der Reviewer bewertet spaeter ob die Abweichung gerechtfertigt war.

### 3.3 REVIEW / FIX Loop

```mermaid
flowchart TD
    Start([IMPLEMENT fertig]) --> Review

    subgraph Review ["REVIEW (Sonnet)"]
        R1[Akzeptanzkriterien pruefen]
        R2[/review-code ausfuehren/]
        R3[/review-localization/]
        R4[make check + test-unit]
        R5[Deviations bewerten]
        R1 --> R2 --> R3 --> R4 --> R5
        R5 --> Classify[Findings klassifizieren]
    end

    Classify --> V{Verdict?}

    V -->|PASS| Collect[NEEDS_INPUT + DISCUSSION<br/>in separate Dateien]
    Collect --> Close([CLOSE])

    V -->|FAIL| MaxCheck{Max Reviews<br/>erreicht?}
    MaxCheck -->|Ja| Abort([ABBRUCH])
    MaxCheck -->|Nein| Fix

    subgraph Fix ["FIX (Opus)"]
        F1[BLOCKER-Findings lesen]
        F2[Fixes implementieren]
        F3[make check + test-unit]
        F4[Commit]
        F1 --> F2 --> F3 --> F4
    end

    Fix --> Review

    style Review fill:#f0e6f6,stroke:#9b72b0
    style Fix fill:#e8f4ea,stroke:#6b8f71
```

#### Die drei Finding-Kategorien

```mermaid
graph LR
    F[Finding] --> B[BLOCKER]
    F --> N[NEEDS_INPUT]
    F --> D[DISCUSSION]

    B -->|"Blockiert"| Fix[Muss gefixt werden]
    N -->|"Wird gesammelt"| After[User entscheidet nach Workflow]
    D -->|"Wird gesammelt"| Later[Verbesserung fuer spaeter]

    style B fill:#d9534f,color:#fff
    style N fill:#e8a838,color:#000
    style D fill:#5bc0de,color:#000
```

| Kategorie | Blockiert? | Beispiel |
|-----------|-----------|---------|
| BLOCKER | Ja, Verdict = FAIL | Fehlender Test, Security-Problem |
| NEEDS_INPUT | Nein, fuer User nach Workflow | Naming-Entscheidung ohne klare Antwort |
| DISCUSSION | Nein, Vorschlag fuer spaeter | Design-Alternative, Zukunfts-Idee |

### 3.4 CLOSE + LEARN

```mermaid
flowchart LR
    subgraph CLOSE ["CLOSE (Haiku)"]
        C1[/close-ticket/ Skill]
        C2[Status → DONE]
        C3[INDEX.md updaten]
        C4[Commit]
        C1 --> C2 --> C3 --> C4
    end

    subgraph LEARN ["LEARN (Sonnet, best-effort)"]
        L1[Challenges sammeln]
        L2{Generisch genug?}
        L2 -->|Ja| L3[MEMORY.md /<br/>CLAUDE.md updaten]
        L2 -->|Nein| L4[Verwerfen]
    end

    CLOSE --> LEARN

    style CLOSE fill:#d5e8d4,stroke:#82b366
    style LEARN fill:#dae8fc,stroke:#6c8ebf
```

---

## 4. Datenfluss: Das Implementation-Log

Alle Phasen kommunizieren ueber ein einziges append-only Log.

```mermaid
flowchart TD
    subgraph Log ["Implementation-Log (append-only)"]
        direction TB
        S1["## UNDERSTAND<br/>Assessment, Questions, User-Answers"]
        S2["## PLAN<br/>Approach, Steps, Test-Strategy, Files"]
        S3["## IMPLEMENT<br/>Commits, Challenges, Deviations"]
        S4["## REVIEW 1<br/>Verdict: FAIL, Blockers"]
        S5["## FIX 1<br/>Commits, Challenges"]
        S6["## REVIEW 2<br/>Verdict: PASS"]
        S7["## CLOSE<br/>Commits"]
        S8["## LEARN<br/>Learnings"]
        S1 ~~~ S2 ~~~ S3 ~~~ S4 ~~~ S5 ~~~ S6 ~~~ S7 ~~~ S8
    end

    U([UNDERSTAND]) -->|schreibt| S1
    P([PLAN]) -->|liest S1, schreibt| S2
    I([IMPLEMENT]) -->|liest S2, schreibt| S3
    R1([REVIEW]) -->|liest S3, schreibt| S4
    F([FIX]) -->|liest S4, schreibt| S5
    R2([REVIEW]) -->|liest S5, schreibt| S6
    C([CLOSE]) -->|schreibt| S7
    L([LEARN]) -->|liest Challenges, schreibt| S8

    style Log fill:#fff9e6,stroke:#d4a843
```

### Orchestrator-Aufgaben zwischen Phasen

Der Orchestrator ist nicht nur ein Agent-Starter — er extrahiert und transformiert Daten:

```mermaid
flowchart LR
    U[UNDERSTAND] -->|"Questions/Answers<br/>extrahieren"| O1((O))
    O1 -->|"In Prompt<br/>einfuegen"| P[PLAN]

    P -->|"Plan validieren"| O2((O))
    O2 --> I[IMPLEMENT]

    I -->|"Abschnitt pruefen"| O3((O))
    O3 --> R[REVIEW]

    R -->|"BLOCKERs<br/>extrahieren"| O4((O))
    O4 -->|"In Prompt<br/>einfuegen"| F[FIX]

    R -->|"NEEDS_INPUT +<br/>DISCUSSION<br/>in Dateien"| O5((O))
    O5 --> C[CLOSE]

    C -->|"Challenges<br/>sammeln"| O6((O))
    O6 -->|"In Prompt<br/>einfuegen"| L[LEARN]

    style O1 fill:#4a6fa5,color:#fff
    style O2 fill:#4a6fa5,color:#fff
    style O3 fill:#4a6fa5,color:#fff
    style O4 fill:#4a6fa5,color:#fff
    style O5 fill:#4a6fa5,color:#fff
    style O6 fill:#4a6fa5,color:#fff
```

---

## 5. Agent-Architektur

Fuenf spezialisierte Agents statt einem Allzweck-Agent:

```mermaid
graph TD
    subgraph "Opus (teuer, maechtig)"
        Planner["ticket-planner<br/>PLAN"]
        Impl["ticket-implementer<br/>IMPLEMENT + FIX"]
    end

    subgraph "Sonnet (guenstig, analytisch)"
        Analyst["ticket-analyst<br/>UNDERSTAND"]
        Reviewer["ticket-reviewer<br/>REVIEW"]
        Learner["ticket-learner<br/>LEARN"]
    end

    subgraph "Haiku (billig, mechanisch)"
        Closer["ticket-closer<br/>CLOSE"]
    end

    style Planner fill:#d9534f,color:#fff
    style Impl fill:#d9534f,color:#fff
    style Analyst fill:#f0ad4e,color:#000
    style Reviewer fill:#f0ad4e,color:#000
    style Learner fill:#f0ad4e,color:#000
    style Closer fill:#5cb85c,color:#fff
```

### Tool-Zugriff pro Agent

```mermaid
graph LR
    subgraph ReadOnly ["Nur Lesen"]
        A1[ticket-analyst]
        A2[ticket-reviewer]
        A3[ticket-learner]
    end

    subgraph ReadWrite ["Lesen + Schreiben"]
        A4[ticket-planner]
        A5[ticket-implementer]
        A6[ticket-closer]
    end

    A1 --- T1["Read, Glob, Grep<br/>git log/diff"]
    A2 --- T2["Read, Glob, Grep<br/>make, git diff<br/>Skills: review-*"]
    A3 --- T3["Read, Glob, Grep<br/>Edit, Write"]
    A4 --- T4["Read, Glob, Grep<br/>make, git log/diff"]
    A5 --- T5["Read, Glob, Grep<br/>Edit, Write<br/>make, git add/commit"]
    A6 --- T6["Read, Glob, Grep<br/>Edit, Write<br/>git add/commit<br/>Skill: close-ticket"]
```

---

## 6. Interaktivitaets-Modell

```mermaid
stateDiagram-v2
    [*] --> UNDERSTAND

    state UNDERSTAND {
        [*] --> Analyse
        Analyse --> CheckQuestions
        CheckQuestions --> AutoWeiter: Keine Fragen
        CheckQuestions --> FragenAnzeigen: Hat Fragen
        FragenAnzeigen --> UserAntwort
        UserAntwort --> AutoWeiter
    }

    UNDERSTAND --> PLAN

    state PLAN {
        [*] --> PlanSchreiben
        PlanSchreiben --> PlanAnzeigen
        PlanAnzeigen --> Approved: User OK
        PlanAnzeigen --> PlanSchreiben: User Feedback
        PlanAnzeigen --> Abbruch: User Cancel
    }

    PLAN --> IMPLEMENT: Approved
    PLAN --> [*]: Abbruch

    state IMPLEMENT {
        [*] --> TDD
        TDD --> [*]
    }

    IMPLEMENT --> ReviewLoop

    state ReviewLoop {
        [*] --> REVIEW
        REVIEW --> [*]: PASS
        REVIEW --> FIX: FAIL
        FIX --> REVIEW
    }

    ReviewLoop --> CLOSE
    CLOSE --> LEARN
    LEARN --> [*]
```

### Autonomer Modus (`--auto`)

Fuer CI/Batch-Laeufe: gleicher Workflow, ohne Warten.

| Phase | Interaktiv (Default) | Autonom (`--auto`) |
|-------|---------------------|-------------------|
| UNDERSTAND | Fragen → User antwortet | Fragen → **Abbruch** |
| PLAN | Plan → User approved | Plan → **auto-approved** |
| Rest | Identisch | Identisch |

---

## 7. Artefakte

```mermaid
graph TD
    WF[ticket-flow run ios-032] --> L["logs/ios-032.md<br/>Implementation-Log"]
    WF --> N["needs-input/ios-032.md<br/>Offene Entscheidungen"]
    WF --> D["discussions/ios-032.md<br/>Verbesserungsvorschlaege"]

    L -->|"Hauptartefakt"| Full[Kompletter Verlauf<br/>aller Phasen]
    N -->|"Nach Workflow"| User[User prueft +<br/>entscheidet]
    D -->|"Spaeter"| Backlog[Fuer kuenftige<br/>Verbesserungen]

    style L fill:#4a6fa5,color:#fff
    style N fill:#e8a838,color:#000
    style D fill:#5bc0de,color:#000
```

---

## 8. Vorher / Nachher

```mermaid
graph LR
    subgraph Vorher ["IST: Bash-Script"]
        B1["500 Zeilen Bash"]
        B2["1 Agent fuer 4 Jobs"]
        B3["Hartcodiert"]
        B4["Nicht testbar"]
        B5["Kein Verstehen/Planen"]
    end

    subgraph Nachher ["SOLL: ticket-flow"]
        N1["Python-Package"]
        N2["5 spezialisierte Agents"]
        N3["Konfigurierbar"]
        N4["Testbar"]
        N5["UNDERSTAND + PLAN Phasen"]
    end

    B1 -.->|"wird zu"| N1
    B2 -.->|"wird zu"| N2
    B3 -.->|"wird zu"| N3
    B4 -.->|"wird zu"| N4
    B5 -.->|"wird zu"| N5

    style Vorher fill:#ffcccc,stroke:#cc0000
    style Nachher fill:#ccffcc,stroke:#00cc00
```
