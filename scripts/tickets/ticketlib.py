"""Ticket-Dateien lesen und validieren (Frontmatter-Schema siehe dev-docs/tickets/README.md)."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

import yaml

AREAS = ("shared", "ios", "android")
PLATFORMS = ("ios", "android")
ARCHIVE = "archive"

STATUSES = ("todo", "in-progress", "done", "wontfix")
NOT_APPLICABLE = "n/a"
CLOSED = frozenset({"done", "wontfix"})
PHASES = ("1-Quick Fix", "2-Architektur", "3-Feature", "4-Polish", "5-QA")
PRIORITIES = ("kritisch", "hoch", "mittel", "niedrig")

REQUIRED_FIELDS = ("id", "title", "status", "phase")
OPTIONAL_FIELDS = ("priority", "depends_on")
FIELD_ORDER = REQUIRED_FIELDS + OPTIONAL_FIELDS

ID_RE = re.compile(r"^(shared|ios|android)-(\d{3})([a-z]?(?:-\d+)?)$")

Error = tuple[str, str]  # (Pfad relativ zum Ticket-Ordner, Problem)


@dataclass(frozen=True)
class Ticket:
    id: str
    title: str
    status: str | dict[str, str]
    phase: str
    priority: str | None
    depends_on: tuple[str, ...]
    path: str  # relativ zum Ticket-Ordner, POSIX

    @property
    def area(self) -> str:
        return self.id.split("-", 1)[0]

    @property
    def is_closed(self) -> bool:
        return is_closed(self.status)


def is_closed(status: str | dict[str, str]) -> bool:
    """Plattform: done|wontfix. Shared: alle Werte done|wontfix|n/a, mindestens einer nicht n/a."""
    if isinstance(status, dict):
        values = list(status.values())
        return all(v in CLOSED or v == NOT_APPLICABLE for v in values) and any(v != NOT_APPLICABLE for v in values)
    return status in CLOSED


def id_sort_key(ticket_id: str) -> tuple:
    match = ID_RE.match(ticket_id)
    if not match:
        return (ticket_id, 0, "")
    return (match.group(1), int(match.group(2)), match.group(3))


def ticket_dirs(root: Path) -> list[tuple[Path, bool]]:
    """Ordner, in denen Tickets liegen: (Ordner, archiviert)."""
    dirs = [(root / area, False) for area in AREAS]
    dirs += [(root / ARCHIVE / area, True) for area in AREAS]
    return dirs


def discover(root: Path) -> list[str]:
    """Alle Ticket-Dateien als POSIX-Pfade relativ zu `root`, sortiert."""
    found = []
    for directory, _ in ticket_dirs(root):
        if directory.is_dir():
            found += [p.relative_to(root).as_posix() for p in directory.glob("*.md")]
    return sorted(found)


def split_frontmatter(text: str) -> tuple[dict | None, str, str | None]:
    """Liefert (frontmatter, body, fehler)."""
    text = text.removeprefix("﻿")
    if not text.startswith("---\n"):
        return None, text, "Frontmatter fehlt (Datei muss mit '---' beginnen)"
    end = text.find("\n---\n", 3)
    if end == -1:
        if text.endswith("\n---"):
            end = len(text) - 4
        else:
            return None, text, "Frontmatter nicht abgeschlossen (schliessendes '---' fehlt)"
    raw = text[4 : end + 1]
    body = text[end + 5 :]
    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError as exc:
        reason = str(exc).replace("\n", " ")
        return None, body, f"ungueltiges YAML im Frontmatter: {reason}"
    if not isinstance(data, dict):
        return None, body, "Frontmatter muss eine YAML-Map sein"
    return data, body, None


def validate_fields(data: dict, rel_path: str) -> tuple[Ticket | None, list[Error]]:
    """Prueft ein einzelnes Frontmatter gegen Schema, Dateinamen und Ordner."""
    problems: list[str] = []

    for key in data:
        if key not in FIELD_ORDER:
            problems.append(f"unbekanntes Feld '{key}'")
    for key in REQUIRED_FIELDS:
        if key not in data or data[key] in (None, ""):
            problems.append(f"Pflichtfeld '{key}' fehlt")
    if problems:
        return None, [(rel_path, p) for p in problems]

    ticket_id = data["id"]
    filename = rel_path.rsplit("/", 1)[-1]
    match = ID_RE.match(str(ticket_id))
    if not isinstance(ticket_id, str) or not match:
        problems.append(f"ungueltige id '{ticket_id}' (erwartet z.B. ios-012, shared-039b, android-003-2)")
    elif not filename.startswith(f"{ticket_id}-"):
        problems.append(f"id '{ticket_id}' passt nicht zum Dateinamen '{filename}'")

    title = data["title"]
    if not isinstance(title, str) or "\n" in title.strip():
        problems.append("title muss ein einzeiliger Text sein")
    elif "|" in title:
        problems.append("title darf kein '|' enthalten")

    area = match.group(1) if match else None
    problems += _status_problems(data["status"], area)

    if data["phase"] not in PHASES:
        problems.append(f"unbekannte phase '{data['phase']}' (erlaubt: {', '.join(PHASES)})")

    priority = data.get("priority")
    if priority is not None and priority not in PRIORITIES:
        problems.append(f"unbekannte priority '{priority}' (erlaubt: {', '.join(PRIORITIES)})")

    depends_on = data.get("depends_on") or []
    if not isinstance(depends_on, list) or not all(isinstance(d, str) and ID_RE.match(d) for d in depends_on):
        problems.append("depends_on muss eine Liste von Ticket-IDs sein")
        depends_on = []

    if problems:
        return None, [(rel_path, p) for p in problems]

    ticket = Ticket(
        id=ticket_id,
        title=title.strip(),
        status=dict(data["status"]) if isinstance(data["status"], dict) else data["status"],
        phase=data["phase"],
        priority=priority,
        depends_on=tuple(depends_on),
        path=rel_path,
    )
    folder_problem = _folder_problem(ticket)
    if folder_problem:
        return None, [(rel_path, folder_problem)]
    return ticket, []


def _status_problems(status, area: str | None) -> list[str]:
    if area is None:
        return []
    if area != "shared":
        if isinstance(status, dict):
            return ["status muss ein einzelner Wert sein (Plattform-Ticket)"]
        if status not in STATUSES:
            return [f"unbekannter status '{status}' (erlaubt: {', '.join(STATUSES)})"]
        return []
    if not isinstance(status, dict) or set(status) != set(PLATFORMS):
        return ["status muss eine Map mit genau 'ios' und 'android' sein (shared-Ticket)"]
    problems = []
    for platform in PLATFORMS:
        value = status[platform]
        if value not in STATUSES and value != NOT_APPLICABLE:
            allowed = ", ".join((*STATUSES, NOT_APPLICABLE))
            problems.append(f"unbekannter status '{value}' fuer {platform} (erlaubt: {allowed})")
    if not problems and all(v == NOT_APPLICABLE for v in status.values()):
        problems.append("status: mindestens eine Plattform muss betroffen sein (nicht alle 'n/a')")
    return problems


def _folder_problem(ticket: Ticket) -> str | None:
    folder = ticket.path.rsplit("/", 1)[0] if "/" in ticket.path else ""
    archived = folder.startswith(f"{ARCHIVE}/")
    folder_area = folder.removeprefix(f"{ARCHIVE}/")
    if folder_area != ticket.area:
        expected = f"{ARCHIVE}/{ticket.area}/" if archived else f"{ticket.area}/"
        return f"Ticket gehoert nach '{expected}'"
    if ticket.is_closed and not archived:
        return f"abgeschlossenes Ticket gehoert nach '{ARCHIVE}/{ticket.area}/'"
    if not ticket.is_closed and archived:
        return f"aktives Ticket gehoert nach '{ticket.area}/'"
    return None


def cross_check(tickets: list[Ticket], known_ids: set[str] | None = None) -> list[Error]:
    """Pruefungen ueber alle Tickets: doppelte IDs, unbekannte Abhaengigkeiten.

    `known_ids` ergaenzt IDs, die als existent gelten, obwohl sie nicht in `tickets` stehen.
    """
    errors: list[Error] = []
    seen: dict[str, str] = {}
    for ticket in tickets:
        if ticket.id in seen:
            errors.append((ticket.path, f"doppelte id '{ticket.id}' (auch in {seen[ticket.id]})"))
        else:
            seen[ticket.id] = ticket.path
    known = set(seen) | (known_ids or set())
    for ticket in tickets:
        for dep in ticket.depends_on:
            if dep not in known:
                errors.append((ticket.path, f"depends_on verweist auf unbekanntes Ticket '{dep}'"))
    return errors


def load_tickets(root: Path) -> tuple[list[Ticket], list[Error]]:
    """Liest und validiert alle Tickets. Fehler werden gesammelt, nach Pfad sortiert."""
    tickets: list[Ticket] = []
    errors: list[Error] = []
    for rel_path in discover(root):
        text = (root / rel_path).read_text(encoding="utf-8")
        data, _, problem = split_frontmatter(text)
        if problem:
            errors.append((rel_path, problem))
            continue
        ticket, ticket_errors = validate_fields(data, rel_path)
        errors += ticket_errors
        if ticket:
            tickets.append(ticket)
    errors += cross_check(tickets)
    return tickets, sorted(errors)
