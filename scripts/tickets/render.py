"""INDEX.md aus validierten Tickets erzeugen (deterministisch)."""

from __future__ import annotations

from ticketlib import Ticket, id_sort_key

STATUS_MARKS = {
    "todo": "[ ]",
    "in-progress": "[~]",
    "done": "[x]",
    "wontfix": "[-]",
    "n/a": "-",
}

HEADER = """# Ticket-Index

> Generiert von `make tickets-index` — nicht von Hand bearbeiten.
> Konventionen, Workflow und Frontmatter-Format: [README.md](README.md)

Status: `[ ]` offen · `[~]` in Arbeit · `[x]` erledigt · `[-]` wontfix · `-` nicht betroffen
"""

SECTIONS = (("shared", "Cross-Platform"), ("ios", "iOS"), ("android", "Android"))


def render_index(tickets: list[Ticket]) -> str:
    by_id = {t.id: t for t in tickets}
    ordered = sorted(tickets, key=lambda t: id_sort_key(t.id))
    parts = [HEADER]
    for heading, closed in (("Aktiv", False), ("Archiv", True)):
        parts.append(f"\n## {heading}\n")
        for area, label in SECTIONS:
            selected = [t for t in ordered if t.area == area and t.is_closed == closed]
            parts.append(f"\n### {label}\n\n")
            parts.append(_table(selected, area, by_id))
    return "".join(parts)


def _table(tickets: list[Ticket], area: str, by_id: dict[str, Ticket]) -> str:
    if not tickets:
        return "_Keine Tickets._\n"
    if area == "shared":
        lines = ["| Nr | Ticket | Phase | iOS | Android |", "|----|--------|-------|-----|---------|"]
        lines += [
            f"| {_link(t)} | {t.title} | {t.phase} | {STATUS_MARKS[t.status['ios']]} | {STATUS_MARKS[t.status['android']]} |"
            for t in tickets
        ]
    else:
        lines = ["| Nr | Ticket | Phase | Status | Abhaengigkeit |", "|----|--------|-------|--------|---------------|"]
        lines += [
            f"| {_link(t)} | {t.title} | {t.phase} | {STATUS_MARKS[t.status]} | {_dependencies(t, by_id)} |"
            for t in tickets
        ]
    return "\n".join(lines) + "\n"


def _link(ticket: Ticket) -> str:
    return f"[{ticket.id}]({ticket.path})"


def _dependencies(ticket: Ticket, by_id: dict[str, Ticket]) -> str:
    links = [_link(by_id[dep]) if dep in by_id else dep for dep in ticket.depends_on]
    return ", ".join(links) if links else "-"
