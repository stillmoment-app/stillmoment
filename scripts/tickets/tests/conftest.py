import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


@pytest.fixture
def tickets_dir(tmp_path):
    root = tmp_path / "tickets"
    for area in ("shared", "ios", "android"):
        (root / area).mkdir(parents=True)
        (root / "archive" / area).mkdir(parents=True)
    return root


def write(root: Path, rel: str, text: str) -> Path:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


def platform_ticket(ticket_id, status="todo", phase="4-Polish", title="Titel", extra=""):
    return (
        f"---\nid: {ticket_id}\ntitle: {title}\nstatus: {status}\nphase: {phase}\n{extra}---\n\n"
        f"# Ticket {ticket_id}: {title}\n"
    )


def shared_ticket(ticket_id, ios="todo", android="todo", phase="3-Feature", title="Titel", extra=""):
    return (
        f"---\nid: {ticket_id}\ntitle: {title}\nstatus:\n  ios: {ios}\n  android: {android}\n"
        f"phase: {phase}\n{extra}---\n\n# Ticket {ticket_id}: {title}\n"
    )
