# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6"]
# ///
"""Validiert alle Tickets und erzeugt dev-docs/tickets/INDEX.md.

    uv run scripts/tickets/index.py            # validieren + INDEX.md schreiben
    uv run scripts/tickets/index.py --check    # validieren, Exit != 0 wenn INDEX.md veraltet
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # keine __pycache__-Ordner im Repo

from render import render_index
from ticketlib import load_tickets

DEFAULT_TICKETS_DIR = Path(__file__).resolve().parents[2] / "dev-docs" / "tickets"


def display_path(path: Path) -> str:
    try:
        return path.resolve().relative_to(Path.cwd().resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="nichts schreiben, nur pruefen ob INDEX.md aktuell ist")
    parser.add_argument("--tickets-dir", type=Path, default=DEFAULT_TICKETS_DIR, help="Ticket-Ordner")
    args = parser.parse_args(argv)

    root: Path = args.tickets_dir
    prefix = display_path(root)
    tickets, errors = load_tickets(root)
    if errors:
        for rel_path, problem in errors:
            print(f"{prefix}/{rel_path}: {problem}", file=sys.stderr)
        print(f"{len(errors)} Fehler — INDEX.md {'nicht geprueft' if args.check else 'nicht geschrieben'}.", file=sys.stderr)
        return 1

    index_path = root / "INDEX.md"
    content = render_index(tickets)
    current = index_path.read_text(encoding="utf-8") if index_path.exists() else None

    if args.check:
        if current != content:
            print(f"{prefix}/INDEX.md ist veraltet — 'make tickets-index' ausfuehren.", file=sys.stderr)
            return 1
        print(f"{len(tickets)} Tickets gueltig, INDEX.md aktuell.")
        return 0

    if current != content:
        index_path.write_text(content, encoding="utf-8")
        print(f"{prefix}/INDEX.md geschrieben ({len(tickets)} Tickets).")
    else:
        print(f"{prefix}/INDEX.md unveraendert ({len(tickets)} Tickets).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
