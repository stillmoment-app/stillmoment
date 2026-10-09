# Plan shared-130: Ticket-System mit Archiv, Frontmatter und generiertem Index

Ticket: `dev-docs/tickets/shared/shared-130-ticket-system-archiv-frontmatter-index.md`

## Zielstruktur

```
dev-docs/tickets/
├── INDEX.md              ← GENERIERT (make tickets-index), nie von Hand editieren
├── README.md             ← Konventionen/Workflow/Philosophie (bisher Prosa-Teil von INDEX.md)
├── TEMPLATE-platform.md
├── TEMPLATE-shared.md
├── shared/ ios/ android/ ← nur aktive Tickets (todo / in-progress)
├── archive/
│   └── shared/ ios/ android/   ← abgeschlossene Tickets (done / wontfix)
└── plans/                ← unveraendert
```

Ticket per ID finden: Glob `dev-docs/tickets/**/<id>-*.md` (schliesst `plans/` aus, weil Plaene `<id>.md` heissen;
im Zweifel `plans/` explizit ausschliessen).

## Frontmatter-Schema

Plattform-Ticket (`ios-NNN`, `android-NNN`):

```yaml
---
id: ios-053
title: Anleitung "So importierst du aus Apple Podcasts"
status: todo
phase: 4-Polish
priority: niedrig        # optional
depends_on: [shared-128] # optional, nur Ticket-IDs
---
```

Shared-Ticket (`shared-NNN`):

```yaml
---
id: shared-026
title: iOS Store Publishing
status:
  ios: done
  android: n/a
phase: 2-Architektur
priority: mittel         # optional
depends_on: []           # optional
---
```

Feldregeln:

- `id`: muss zum Dateinamen-Prefix passen (`<id>-<slug>.md`).
- `title`: Einzeiler. Bei Migration aus der INDEX.md-Zeile uebernommen (kanonischer Kurztitel).
- `status` (Plattform-Ticket): `todo` | `in-progress` | `done` | `wontfix`
- `status` (Shared-Ticket): Map mit genau `ios` und `android`; Werte wie oben plus `n/a` (Plattform nicht betroffen, frueher `-`).
- `phase`: `1-Quick Fix` | `2-Architektur` | `3-Feature` | `4-Polish` | `5-QA`
- `priority` (optional): `kritisch` | `hoch` | `mittel` | `niedrig`
- `depends_on` (optional): Liste von Ticket-IDs. Freitext-Abhaengigkeiten gehen in den Ticket-Text (Abschnitt `## Hinweise`), nicht ins Frontmatter.

**Abgeschlossen** = Plattform-Ticket `done|wontfix`; Shared-Ticket: alle Plattformwerte in `done|wontfix|n/a` und mindestens einer nicht `n/a`.
Abgeschlossene Tickets liegen in `archive/<bereich>/`, aktive im Bereichsordner. Der Generator prueft das (falscher Ordner → Fehler).

Body: Unveraendert ausser:
- Zeilen `**Status**: …`, `**Prioritaet**: …`, `**Phase**: …` entfallen (stehen im Frontmatter).
- Shared: Abschnitt `## Plattform-Status` (Tabelle) entfaellt. Nicht-triviale Inhalte der Abhaengigkeits-Spalte (alles ausser `-`/leer/reine IDs) wandern als Stichpunkt nach `## Hinweise`.
- Andere Kopfzeilen (`**Komplexitaet**`, `**Aufwand**`, …) bleiben.
- WONTFIX-/SPLIT-Begruendungen im Text bleiben.

Status-Mapping bei Migration: `[ ] TODO`→todo, `[~] IN PROGRESS`→in-progress, `[x] DONE`→done, `[x]/[-] WONTFIX`→wontfix,
`[x] SPLIT …`→done (Begruendungstext bleibt im Body), INDEX-`-`→n/a.

## Tooling

- Ort: `scripts/tickets/` (Python, PEP-723-Inline-Metadaten, ausgefuehrt via `uv run`), Tests in `scripts/tickets/tests/` (pytest).
- Root-`Makefile`-Targets:
  - `make tickets-index` → validiert alle Tickets, schreibt `INDEX.md`. Fehler (Datei + Problem) → Exit ≠ 0, INDEX.md unveraendert.
  - `make tickets-check` → wie oben, schreibt nicht; Exit ≠ 0 wenn INDEX.md veraltet.
  - `make test-tickets` → pytest.
- Migration: einmaliges Skript `scripts/tickets/migrate.py` mit `--dry-run` (Bericht: Konflikte Datei-Status vs. INDEX-Status, Dateien ohne INDEX-Zeile, INDEX-Zeilen ohne Datei, unbekannte Statusformate, Abhaengigkeiten mit Freitext). Verschieben per `git mv`. Wird nach erfolgreicher Migration geloescht (bleibt in der Git-Historie).
  **Erledigt:** Migration in Commit `4491dc26`; Skript und Tests im Folge-Commit entfernt
  (wiederherstellen mit `git show 4491dc26:scripts/tickets/migrate.py`).

## Generiertes INDEX.md

1. Kopf: Hinweis "Generiert von `make tickets-index` — nicht von Hand bearbeiten", Link auf `README.md`, Status-Legende.
2. `## Aktiv`: drei Tabellen (Cross-Platform / iOS / Android), nach ID aufsteigend.
   - Shared: `| Nr | Ticket | Phase | iOS | Android |`
   - Plattform: `| Nr | Ticket | Phase | Status | Abhaengigkeit |`
3. `## Archiv`: dieselben drei Tabellen fuer abgeschlossene Tickets.
4. Status-Darstellung in Tabellen: `[ ]` todo, `[~]` in-progress, `[x]` done, `[-]` wontfix, `-` n/a. Abhaengigkeit: IDs als Links, sonst `-`.
5. Links relativ zu `dev-docs/tickets/`. Deterministische Ausgabe (gleiche Eingabe → byte-identisch).

## Arbeitspakete

1. **Tooling (TDD)**: Parser/Validator, Generator, Migrationsskript, Tests, Make-Targets.
2. **Skills & Doku**: create/plan/implement/close-ticket, review-code, review-view und alle weiteren Ticket-Leser; Templates; `dev-docs/agents/issue-tracker.md`; Prosa aus INDEX.md → `README.md`.
3. **Migration**: Dry-Run → Konflikte klaeren → Migration → Index generieren.
4. **Pfad-Referenzen**: alle Verweise auf verschobene Ticket-Dateien im Repo nachziehen.
5. **Review & manueller Test** gemaess Ticket.
