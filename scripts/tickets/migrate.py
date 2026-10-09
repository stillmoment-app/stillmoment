# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6"]
# ///
"""Einmalige Migration der Tickets auf Frontmatter + Archiv (shared-130).

    uv run scripts/tickets/migrate.py --dry-run                         # nur Bericht
    uv run scripts/tickets/migrate.py --resolutions resolutions.yaml    # migrieren

Quelle fuer Status, Titel und Phase ist die alte INDEX.md; die Ticket-Dateien
werden dagegen geprueft. Widersprueche blockieren die echte Migration, bis sie
in einer Resolutions-Datei (YAML) entschieden sind:

    shared-058:
      status: index            # index | file | <wert> | {ios: <wert>, android: <wert>}
      phase: 2-Architektur     # ueberschreibt Phase
    android-070:
      phase: 2-Architektur
    # weitere Felder: title, priority, depends_on

Echte Migration: schreibt Frontmatter, entfernt **Status**/**Prioritaet**/**Phase**
und den Abschnitt '## Plattform-Status', verschiebt abgeschlossene Tickets per
'git mv' nach archive/<bereich>/ und passt relative Links unter dev-docs/tickets/ an.
Die alte INDEX.md bleibt unangetastet (danach 'make tickets-index').
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml

sys.dont_write_bytecode = True  # keine __pycache__-Ordner im Repo

import ticketlib
from ticketlib import AREAS, CLOSED, ID_RE, NOT_APPLICABLE, PHASES, PLATFORMS, PRIORITIES

DEFAULT_TICKETS_DIR = Path(__file__).resolve().parents[2] / "dev-docs" / "tickets"

WORDS = {"TODO": "todo", "IN PROGRESS": "in-progress", "DONE": "done", "WONTFIX": "wontfix", "SPLIT": "done"}
TOKEN = r"\[[ xX~\-]\]\s*(TODO|IN PROGRESS|DONE|WONTFIX|SPLIT)"
MARKS = {"[x]": "done", "[X]": "done", "[ ]": "todo", "[~]": "in-progress", "[-]": "wontfix"}
PLATFORM_NAMES = {"ios": "ios", "android": "android"}
LABELS = {"ios": "iOS", "android": "Android"}

HEADER_LINE_RE = re.compile(r"^\*\*(Status|Prioritaet|Phase)\*\*:\s*(.*?)\s*$")
HEADING_RE = re.compile(r"^# Ticket ([\w-]+):\s*(.*?)\s*$")
INDEX_ROW_RE = re.compile(r"^\|\s*\[([^\]]+)\]\(([^)]+)\)\s*\|(.*)\|\s*$")
ID_LIST_RE = re.compile(r"^[a-z]+-\d{3}[a-z]?(?:-\d+)?(?:\s*,\s*[a-z]+-\d{3}[a-z]?(?:-\d+)?)*$")
LINK_RE = re.compile(r"(\]\()([^)\s]+)((?:\s+\"[^\"]*\")?\))")

REPORT_SECTIONS = (
    # (Schluessel, Ueberschrift, blockierend)
    ("status_conflicts", "Statuskonflikte Datei vs. INDEX", True),
    ("status_unknown", "Status nicht bestimmbar", True),
    ("phase_problems", "Phasen: Konflikte und unbekannte Werte", True),
    ("id_problems", "ID-Probleme", True),
    ("validation", "Validierungsfehler im Migrationsergebnis", True),
    ("resolution_problems", "Fehler in den Resolutions", True),
    ("unparseable", "Unparsebare Statuswerte (durch andere Quelle ersetzt)", False),
    ("file_without_index", "Dateien ohne INDEX-Zeile (Daten aus der Datei)", False),
    ("index_without_file", "INDEX-Zeilen ohne Datei", False),
    ("index_problems", "Unlesbare INDEX-Zeilen", False),
    ("free_text", "Freitext-Abhaengigkeiten (wandern nach '## Hinweise')", False),
    ("moved_to_hinweise", "Weitere Inhalte aus '## Plattform-Status' (wandern nach '## Hinweise')", False),
    ("interpretations", "Interpretierte Werte", False),
    ("resolved", "Per Resolution entschieden", False),
)


# --- Parsing alter Formate ------------------------------------------------------


def parse_status_line(raw: str) -> tuple[str | None, dict[str, str]]:
    """'**Status**:'-Wert → (Hauptwert, Werte pro Plattform falls die Zeile Plattformen nennt)."""
    text = raw.strip()
    if "|" in text:  # Template-Rest: "[ ] TODO | [~] IN PROGRESS | [x] DONE → **[x] DONE**"
        if "→" not in text:
            return None, {}
        text = text.split("→", 1)[1].replace("**", "").strip()
    match = re.match(TOKEN, text)
    if not match:
        return None, {}
    lead = WORDS[match.group(1)]
    rest = text[match.end() :]
    per_platform: dict[str, str] = {}

    qualifier = re.match(r"\s*\((iOS|Android)\)", rest)
    if qualifier:
        per_platform[qualifier.group(1).lower()] = lead
    for m in re.finditer(TOKEN + r"\s*\((iOS|Android)\)", rest):  # "/ [ ] TODO (Android)"
        per_platform[m.group(2).lower()] = WORDS[m.group(1)]
    for m in re.finditer(r"\b(iOS|Android)\s+" + TOKEN, rest):  # "— Android [-] WONTFIX"
        per_platform[m.group(1).lower()] = WORDS[m.group(2)]
    for m in re.finditer(r"\b(iOS|Android)\s+(done|offen)\b", rest, re.IGNORECASE):  # "(iOS done, Android offen)"
        per_platform[m.group(1).lower()] = "done" if m.group(2).lower() == "done" else "todo"
    return lead, per_platform


def parse_cell(cell: str) -> tuple[str | None, str | None]:
    """Statuszelle aus INDEX oder Plattform-Status-Tabelle → (wert, interpretationshinweis)."""
    text = cell.strip()
    if text in MARKS:
        return MARKS[text], None
    if text in ("-", "—", ""):
        return (NOT_APPLICABLE, None) if text else (None, None)
    match = re.fullmatch(TOKEN, text)
    if match:
        return WORDS[match.group(1)], None
    if text[0] in "-—" and "WONTFIX" in text:
        return "wontfix", f"'{text}' → wontfix"
    if text.startswith("via "):
        return "done", f"'{text}' → done"
    return None, None


@dataclass
class IndexRow:
    id: str
    link: str
    title: str
    phase: str
    col4: str
    col5: str


def parse_old_index(text: str) -> tuple[dict[str, IndexRow], list[str]]:
    rows: dict[str, IndexRow] = {}
    problems: list[str] = []
    for line in text.splitlines():
        match = INDEX_ROW_RE.match(line)
        if not match or not ID_RE.match(match.group(1)):
            continue
        cells = [c.strip() for c in match.group(3).split("|")]
        if len(cells) != 4:
            problems.append(f"{match.group(1)}: erwartet 5 Spalten, gefunden {len(cells) + 1}: {line}")
            continue
        row = IndexRow(match.group(1), match.group(2), *cells)
        if row.id in rows:
            problems.append(f"{row.id}: doppelte INDEX-Zeile")
            continue
        rows[row.id] = row
    return rows, problems


@dataclass
class OldTicket:
    rel: str
    heading_id: str | None
    heading_title: str | None
    header: dict[str, str]  # Status / Prioritaet / Phase (Rohwerte)
    table: dict[str, tuple[str, str]]  # plattform -> (statuszelle, abhaengigkeitszelle)
    extra_rows: list[str]
    prose: list[str]
    body: str  # ohne Kopfzeilen und Plattform-Status-Abschnitt


def parse_old_ticket(rel: str, text: str) -> OldTicket:
    lines = text.removeprefix("﻿").split("\n")
    heading = HEADING_RE.match(lines[0]) if lines else None
    header: dict[str, str] = {}
    table: dict[str, tuple[str, str]] = {}
    extra_rows: list[str] = []
    prose: list[str] = []
    kept: list[str] = []
    removed = False
    i = 0
    while i < len(lines):
        line = lines[i]
        header_match = HEADER_LINE_RE.match(line)
        if header_match:
            header.setdefault(header_match.group(1), header_match.group(2))
            removed = True
            i += 1
            continue
        if line.strip() == "## Plattform-Status":
            i = _consume_platform_section(lines, i + 1, table, extra_rows, prose)
            removed = True
            continue
        if line.strip() == "" and kept and kept[-1].strip() == "" and removed:
            i += 1
            continue
        kept.append(line)
        if line.strip():
            removed = False
        i += 1
    return OldTicket(
        rel=rel,
        heading_id=heading.group(1) if heading else None,
        heading_title=heading.group(2) if heading else None,
        header=header,
        table=table,
        extra_rows=extra_rows,
        prose=prose,
        body="\n".join(kept),
    )


def _consume_platform_section(lines, i, table, extra_rows, prose) -> int:
    """Liest den Abschnitt bis zum naechsten '## ' oder '---' (inkl. '---' und Leerzeilen danach)."""
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith("## "):
            return i
        if line == "---":
            i += 1
            while i < len(lines) and lines[i].strip() == "":
                i += 1
            return i
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            first = cells[0]
            is_separator = all(set(c) <= set("-: ") for c in cells)
            if not is_separator and first not in ("Plattform", "Bereich"):
                platform = next((p for p in PLATFORMS if first.lower().startswith(p)), None)
                if platform and platform not in table:
                    table[platform] = (cells[1] if len(cells) > 1 else "", cells[2] if len(cells) > 2 else "")
                else:
                    extra_rows.append(": ".join(c for c in cells if c not in ("", "-", "—")))
        elif line and not line.startswith("Legende:"):
            prose.append(line)
        i += 1
    return i


# --- Migrationsplan --------------------------------------------------------------


@dataclass
class Item:
    id: str
    source: str
    target: str
    frontmatter: dict
    content: str = ""


@dataclass
class Plan:
    items: list[Item]
    report: dict[str, list[str]]
    link_updates: dict[str, str] = field(default_factory=dict)  # nicht verschobene Dateien → neuer Inhalt
    rewritten_links: int = 0

    @property
    def items_by_id(self) -> dict[str, Item]:
        return {item.id: item for item in self.items}

    @property
    def blocking(self) -> bool:
        return any(self.report[key] for key, _, blocking in REPORT_SECTIONS if blocking)


def build_plan(root: Path, resolutions: dict) -> Plan:
    report: dict[str, list[str]] = {key: [] for key, _, _ in REPORT_SECTIONS}
    index_rows, report["index_problems"] = parse_old_index((root / "INDEX.md").read_text(encoding="utf-8"))
    report["resolution_problems"] = _check_resolutions(resolutions)

    files = [rel for rel in ticketlib.discover(root) if not rel.startswith(f"{ticketlib.ARCHIVE}/")]
    items: list[Item] = []
    hinweise: dict[str, list[str]] = {}
    bodies: dict[str, str] = {}
    seen_ids: set[str] = set()

    for rel in files:
        old = parse_old_ticket(rel, (root / rel).read_text(encoding="utf-8"))
        ticket_id = _ticket_id(old, index_rows, report)
        if ticket_id is None:
            continue
        seen_ids.add(ticket_id)
        row = index_rows.get(ticket_id)
        if row is None:
            report["file_without_index"].append(f"{ticket_id}: {rel}")
        elif row.link != rel:
            report["interpretations"].append(f"{ticket_id}: INDEX-Link {row.link} ≠ Datei {rel} (Datei gilt)")
        resolution = resolutions.get(ticket_id, {})
        notes: list[str] = []
        frontmatter = {
            "id": ticket_id,
            "title": _title(old, row, resolution),
            "status": _status(ticket_id, old, row, resolution, report),
            "phase": _phase(ticket_id, old, row, resolution, report),
            "priority": _priority(ticket_id, old, resolution, report),
            "depends_on": _depends_on(ticket_id, old, row, resolution, report, notes),
        }
        for line in old.extra_rows:
            notes.append(f"Plattform-Status {line}")
            report["moved_to_hinweise"].append(f"{ticket_id}: {line}")
        for line in old.prose:
            notes.append(line)
            report["moved_to_hinweise"].append(f"{ticket_id}: {line}")
        area = ticket_id.split("-", 1)[0]
        status = frontmatter["status"]
        closed = status is not None and ticketlib.is_closed(status)
        filename = rel.rsplit("/", 1)[-1]
        target = f"{ticketlib.ARCHIVE}/{area}/{filename}" if closed else f"{area}/{filename}"
        items.append(Item(ticket_id, rel, target, frontmatter))
        hinweise[ticket_id] = notes
        bodies[ticket_id] = old.body

    for ticket_id, row in sorted(index_rows.items()):
        if ticket_id not in seen_ids:
            report["index_without_file"].append(f"{ticket_id}: INDEX verweist auf {row.link}, Datei fehlt")

    report["validation"] = _validate(items)

    for item in items:
        body = _add_hinweise(bodies[item.id], hinweise[item.id])
        item.content = ticketlib.dump_frontmatter(item.frontmatter) + "\n" + body
    plan = Plan(items, report)
    _rewrite_links(root, plan)
    return plan


def _check_resolutions(resolutions: dict) -> list[str]:
    problems = []
    allowed = {"status", "phase", "title", "priority", "depends_on"}
    for ticket_id, entry in resolutions.items():
        if not isinstance(entry, dict):
            problems.append(f"{ticket_id}: Eintrag muss eine Map sein")
            continue
        problems += [f"{ticket_id}: unbekannter Schluessel '{key}'" for key in entry if key not in allowed]
    return problems


def _ticket_id(old: OldTicket, index_rows: dict[str, IndexRow], report) -> str | None:
    filename = old.rel.rsplit("/", 1)[-1]
    area = old.rel.split("/", 1)[0]
    candidates = [old.heading_id] if old.heading_id else []
    candidates += [row.id for row in index_rows.values() if row.link == old.rel]
    for candidate in candidates:
        if ID_RE.match(candidate) and filename.startswith(f"{candidate}-") and candidate.startswith(f"{area}-"):
            return candidate
    report["id_problems"].append(f"{old.rel}: keine passende ID (Ueberschrift: {old.heading_id or '-'})")
    return None


def _title(old: OldTicket, row: IndexRow | None, resolution: dict) -> str:
    if "title" in resolution:
        return resolution["title"]
    if row is not None:
        return row.title
    return old.heading_title or ""


def _status(ticket_id, old: OldTicket, row: IndexRow | None, resolution: dict, report):
    choice = resolution.get("status")
    shared = ticket_id.startswith("shared-")
    file_values, line_lead = _file_status(ticket_id, old, shared, report)
    index_values = _index_status(ticket_id, row, shared, report)

    if choice not in (None, "index", "file"):
        report["resolved"].append(f"{ticket_id}: status = {choice}")
        return dict(choice) if isinstance(choice, dict) else choice
    if choice:
        report["resolved"].append(f"{ticket_id}: status aus {choice}")
        values = index_values if choice == "index" else file_values
    else:
        _report_status_conflicts(ticket_id, file_values, index_values, line_lead, row, old, report)
        values = {key: index_values.get(key) or file_values.get(key) for key in set(file_values) | set(index_values)}

    keys = PLATFORMS if shared else ("value",)
    missing = [key for key in keys if not values.get(key)]
    if missing:
        detail = f"Datei='{old.header.get('Status', '')}'" + (f", INDEX='{row.col4} | {row.col5}'" if row else "")
        report["status_unknown"].append(f"{ticket_id}: {detail}")
        return None
    return {p: values[p] for p in PLATFORMS} if shared else values["value"]


def _file_status(ticket_id, old: OldTicket, shared: bool, report) -> tuple[dict[str, str], str | None]:
    raw = old.header.get("Status")
    lead, per_platform = parse_status_line(raw) if raw is not None else (None, {})
    if raw is not None and lead is None:
        report["unparseable"].append(f"{ticket_id}: Datei-Status '{raw}'")
    if not shared:
        return ({"value": lead} if lead else {}), lead
    values: dict[str, str] = {}
    if per_platform:
        values.update(per_platform)
        report["interpretations"].append(f"{ticket_id}: Status-Zeile '{raw}' → {per_platform}")
    for platform, (cell, _) in old.table.items():
        value, note = parse_cell(cell)
        if value:
            values[platform] = value
        else:
            report["unparseable"].append(f"{ticket_id} {platform}: Plattform-Status-Zelle '{cell}'")
        if note:
            report["interpretations"].append(f"{ticket_id} {platform}: Plattform-Status {note}")
    return values, (lead if not per_platform else None)


def _index_status(ticket_id, row: IndexRow | None, shared: bool, report) -> dict[str, str]:
    if row is None:
        return {}
    cells = {"ios": row.col4, "android": row.col5} if shared else {"value": row.col4}
    values = {}
    for key, cell in cells.items():
        value, note = parse_cell(cell)
        if value == NOT_APPLICABLE and not shared:
            value = None
        label = f"{ticket_id} {key}" if shared else ticket_id
        if value is None:
            report["unparseable"].append(f"{label}: INDEX-Zelle '{cell}'")
            continue
        if note:
            report["interpretations"].append(f"{label}: INDEX {note}")
        values[key] = value
    return values


def _report_status_conflicts(ticket_id, file_values, index_values, line_lead, row, old, report):
    for key in sorted(set(file_values) & set(index_values)):
        if file_values[key] != index_values[key]:
            label = f"{ticket_id} {key}" if key in PLATFORMS else ticket_id
            report["status_conflicts"].append(f"{label}: Datei={file_values[key]}, INDEX={index_values[key]}")
    # Unqualifizierte Status-Zeile eines shared-Tickets gegen den Gesamtzustand im INDEX pruefen.
    if ticket_id.startswith("shared-") and line_lead and set(index_values) == set(PLATFORMS):
        index_closed = ticketlib.is_closed(index_values)
        if (line_lead in CLOSED) != index_closed:
            raw = old.header.get("Status", "")
            report["status_conflicts"].append(
                f"{ticket_id} Status-Zeile: Datei='{raw}' ({line_lead}), INDEX={index_values['ios']}/{index_values['android']}"
            )


def _phase(ticket_id, old: OldTicket, row: IndexRow | None, resolution: dict, report) -> str | None:
    if "phase" in resolution:
        report["resolved"].append(f"{ticket_id}: phase = {resolution['phase']}")
        return resolution["phase"]
    file_phase = old.header.get("Phase")
    index_phase = row.phase if row else None
    if file_phase and index_phase and file_phase != index_phase:
        report["phase_problems"].append(f"{ticket_id}: Datei='{file_phase}', INDEX='{index_phase}'")
        return None
    phase = index_phase or file_phase
    if phase not in PHASES:
        report["phase_problems"].append(f"{ticket_id}: unbekannte Phase '{phase}'")
        return None
    return phase


def _priority(ticket_id, old: OldTicket, resolution: dict, report) -> str | None:
    if "priority" in resolution:
        return resolution["priority"]
    raw = old.header.get("Prioritaet")
    if not raw:
        return None
    value = raw.split()[0].lower()
    if value not in PRIORITIES:
        report["interpretations"].append(f"{ticket_id}: Prioritaet '{raw}' unbekannt → weggelassen")
        return None
    if raw.strip().lower() != value:
        report["interpretations"].append(f"{ticket_id}: Prioritaet '{raw}' → {value}")
    return value


def _depends_on(ticket_id, old: OldTicket, row: IndexRow | None, resolution: dict, report, notes) -> list[str]:
    if "depends_on" in resolution:
        return list(resolution["depends_on"])
    cells: list[tuple[str, str]] = []
    if ticket_id.startswith("shared-"):
        cells = [(LABELS[p], old.table[p][1]) for p in PLATFORMS if p in old.table]
    elif row is not None:
        cells = [("", row.col5)]
    result: list[str] = []
    for label, cell in cells:
        text = cell.strip()
        if text in ("", "-", "—"):
            continue
        if ID_LIST_RE.match(text):
            result += [dep.strip() for dep in text.split(",") if dep.strip() not in result]
            continue
        source = "Plattform-Status" if label else "INDEX"
        prefix = f"Abhaengigkeit {label} (aus {source})" if label else f"Abhaengigkeit (aus {source})"
        notes.append(f"{prefix}: {text}")
        report["free_text"].append(f"{ticket_id} {label.lower()}: {text}" if label else f"{ticket_id}: {text}")
    return result


def _validate(items: list[Item]) -> list[str]:
    tickets = []
    problems = []
    for item in items:
        if item.frontmatter["status"] is None or item.frontmatter["phase"] is None:
            continue  # bereits als blockierendes Problem berichtet
        ticket, errors = ticketlib.validate_fields(item.frontmatter, item.target)
        problems += [f"{path}: {msg}" for path, msg in errors]
        if ticket:
            tickets.append(ticket)
    # Auch IDs blockierter Tickets gelten als bekannt — sonst entstehen Folgefehler bei depends_on.
    known_ids = {item.id for item in items}
    problems += [f"{path}: {msg}" for path, msg in ticketlib.cross_check(tickets, known_ids)]
    return problems


def _add_hinweise(body: str, notes: list[str]) -> str:
    if not notes:
        return body
    bullets = [f"- {note}" for note in notes]
    lines = body.split("\n")
    start = next((i for i, line in enumerate(lines) if line.strip() == "## Hinweise"), None)
    if start is None:
        return body.rstrip("\n") + "\n\n## Hinweise\n\n" + "\n".join(bullets) + "\n"
    end = len(lines)
    for i in range(start + 1, len(lines)):
        if lines[i].startswith("## ") or lines[i].strip() == "---":
            end = i
            break
    insert_at = end
    while insert_at > start + 1 and lines[insert_at - 1].strip() == "":
        insert_at -= 1
    return "\n".join(lines[:insert_at] + bullets + lines[insert_at:])


# --- Links ------------------------------------------------------------------------


def _rewrite_links(root: Path, plan: Plan) -> None:
    """Relative Links in allen Markdown-Dateien unter `root` an die neuen Orte anpassen."""
    base = root.resolve()
    moves = {(base / i.source).resolve(): (base / i.target).resolve() for i in plan.items if i.source != i.target}
    items_by_source = {i.source: i for i in plan.items}

    for path in sorted(base.rglob("*.md")):
        rel = path.relative_to(base).as_posix()
        if rel == "INDEX.md":
            continue  # wird nach der Migration neu generiert
        item = items_by_source.get(rel)
        text = item.content if item else path.read_text(encoding="utf-8")
        old_dir = path.parent
        new_dir = (base / item.target).parent if item else old_dir
        new_text, count = _rewrite_text(text, old_dir, new_dir, moves)
        if not count:
            continue
        plan.rewritten_links += count
        if item:
            item.content = new_text
        else:
            plan.link_updates[rel] = new_text


def _rewrite_text(text: str, old_dir: Path, new_dir: Path, moves: dict[Path, Path]) -> tuple[str, int]:
    count = 0

    def replace(match: re.Match) -> str:
        nonlocal count
        target = match.group(2)
        if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.IGNORECASE) or target.startswith(("#", "/")):
            return match.group(0)
        path_part, hash_sign, anchor = target.partition("#")
        if not path_part:
            return match.group(0)
        resolved = Path(os.path.normpath(old_dir / path_part))
        new_target = moves.get(resolved, resolved)
        if new_target == resolved and new_dir == old_dir:
            return match.group(0)
        new_link = Path(os.path.relpath(new_target, new_dir)).as_posix() + hash_sign + anchor
        if new_link == target:
            return match.group(0)
        count += 1
        return match.group(1) + new_link + match.group(3)

    return LINK_RE.sub(replace, text), count


# --- Ausfuehrung ------------------------------------------------------------------


def format_report(plan: Plan, dry_run: bool) -> str:
    moves = [i for i in plan.items if i.source != i.target]
    lines = [
        f"Migrationsbericht ({'Dry-Run' if dry_run else 'Migration'})",
        f"Tickets: {len(plan.items)} — aktiv bleiben {len(plan.items) - len(moves)}, ins Archiv {len(moves)}",
        f"Links anzupassen: {plan.rewritten_links} "
        f"(in {len(plan.link_updates)} weiteren Dateien unter dev-docs/tickets/ plus verschobene Tickets)",
        "",
    ]
    for key, heading, blocking in REPORT_SECTIONS:
        entries = plan.report[key]
        marker = " [BLOCKIEREND]" if blocking and entries else ""
        lines.append(f"## {heading} ({len(entries)}){marker}")
        lines += [f"- {entry}" for entry in entries]
        lines.append("")
    lines.append(f"## Geplante Verschiebungen ({len(moves)})")
    lines += [f"- {i.source} → {i.target}" for i in moves]
    lines.append("")
    if plan.link_updates:
        lines.append(f"## Dateien mit angepassten Links ausser Tickets ({len(plan.link_updates)})")
        lines += [f"- {rel}" for rel in sorted(plan.link_updates)]
        lines.append("")
    lines.append("Ergebnis: " + ("BLOCKIERT — erst Konflikte aufloesen." if plan.blocking else "bereit zur Migration."))
    return "\n".join(lines)


def apply_plan(root: Path, plan: Plan) -> None:
    for item in plan.items:
        if item.source != item.target:
            (root / item.target).parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(["git", "mv", item.source, item.target], cwd=root, check=True)
        (root / item.target).write_text(item.content, encoding="utf-8")
    for rel, text in plan.link_updates.items():
        (root / rel).write_text(text, encoding="utf-8")


def load_resolutions(path: Path | None) -> dict:
    if path is None:
        return {}
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    if not isinstance(data, dict):
        raise ValueError(f"{path}: Resolutions muessen eine YAML-Map sein")
    return data


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true", help="nur Bericht, nichts aendern")
    parser.add_argument("--resolutions", type=Path, help="YAML-Datei mit Entscheidungen fuer Konflikte")
    parser.add_argument("--tickets-dir", type=Path, default=DEFAULT_TICKETS_DIR, help="Ticket-Ordner")
    args = parser.parse_args(argv)

    root: Path = args.tickets_dir
    try:
        resolutions = load_resolutions(args.resolutions)
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"Resolutions nicht lesbar: {exc}", file=sys.stderr)
        return 2
    plan = build_plan(root, resolutions)
    print(format_report(plan, args.dry_run))
    if args.dry_run:
        return 0
    if plan.blocking:
        print("Migration abgebrochen: blockierende Probleme (siehe oben). Nichts geaendert.", file=sys.stderr)
        return 1
    apply_plan(root, plan)
    print(f"Migration abgeschlossen: {len(plan.items)} Tickets. Naechster Schritt: make tickets-index")
    return 0


if __name__ == "__main__":
    sys.exit(main())
