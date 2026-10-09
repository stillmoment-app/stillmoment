import subprocess
import sys
from pathlib import Path

from conftest import platform_ticket, shared_ticket, write

import ticketlib
from render import render_index

INDEX_SCRIPT = Path(__file__).resolve().parent.parent / "index.py"


def load(root):
    return ticketlib.load_tickets(root)


def messages(errors):
    return [f"{path}: {msg}" for path, msg in errors]


# --- Validierung ---------------------------------------------------------


def test_valid_platform_ticket_is_loaded(tickets_dir):
    write(
        tickets_dir,
        "ios/ios-053-podcast-anleitung.md",
        platform_ticket("ios-053", extra="priority: niedrig\n"),
    )

    tickets, errors = load(tickets_dir)

    assert errors == []
    assert len(tickets) == 1
    ticket = tickets[0]
    assert ticket.id == "ios-053"
    assert ticket.status == "todo"
    assert ticket.priority == "niedrig"
    assert not ticket.is_closed


def test_shared_ticket_with_mixed_platform_status_is_active(tickets_dir):
    write(tickets_dir, "shared/shared-050-x.md", shared_ticket("shared-050", ios="done", android="todo"))

    tickets, errors = load(tickets_dir)

    assert errors == []
    assert tickets[0].status == {"ios": "done", "android": "todo"}
    assert not tickets[0].is_closed


def test_shared_ticket_done_on_one_platform_and_na_on_other_is_closed(tickets_dir):
    write(tickets_dir, "archive/shared/shared-026-x.md", shared_ticket("shared-026", ios="done", android="n/a"))

    tickets, errors = load(tickets_dir)

    assert errors == []
    assert tickets[0].is_closed


def test_missing_frontmatter_reports_filename(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", "# Ticket ios-001: Kein Kopf\n")

    _, errors = load(tickets_dir)

    assert messages(errors) == ["ios/ios-001-x.md: Frontmatter fehlt (Datei muss mit '---' beginnen)"]


def test_invalid_yaml_is_reported(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", "---\nid: [unclosed\n---\n")

    _, errors = load(tickets_dir)

    assert len(errors) == 1
    assert errors[0][0] == "ios/ios-001-x.md"
    assert "ungueltiges YAML" in errors[0][1]


def test_id_must_match_filename(tickets_dir):
    write(tickets_dir, "ios/ios-002-x.md", platform_ticket("ios-001"))

    _, errors = load(tickets_dir)

    assert messages(errors) == ["ios/ios-002-x.md: id 'ios-001' passt nicht zum Dateinamen 'ios-002-x.md'"]


def test_ticket_in_wrong_area_folder(tickets_dir):
    write(tickets_dir, "shared/ios-001-x.md", platform_ticket("ios-001"))

    _, errors = load(tickets_dir)

    assert "gehoert nach 'ios/'" in messages(errors)[0]


def test_unknown_status_phase_priority_are_reported(tickets_dir):
    write(
        tickets_dir,
        "ios/ios-001-x.md",
        platform_ticket("ios-001", status="fertig", phase="3-Refactor", extra="priority: dringend\n"),
    )

    _, errors = load(tickets_dir)

    text = "\n".join(messages(errors))
    assert "unbekannter status 'fertig'" in text
    assert "unbekannte phase '3-Refactor'" in text
    assert "unbekannte priority 'dringend'" in text


def test_platform_ticket_must_not_use_status_map(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", shared_ticket("ios-001").replace("shared", "ios"))

    _, errors = load(tickets_dir)

    assert "status muss ein einzelner Wert sein" in messages(errors)[0]


def test_shared_ticket_needs_ios_and_android_status(tickets_dir):
    text = "---\nid: shared-001\ntitle: T\nstatus: todo\nphase: 4-Polish\n---\n"
    write(tickets_dir, "shared/shared-001-x.md", text)

    _, errors = load(tickets_dir)

    assert "status muss eine Map mit genau 'ios' und 'android' sein" in messages(errors)[0]


def test_shared_ticket_with_only_na_is_invalid(tickets_dir):
    write(tickets_dir, "shared/shared-001-x.md", shared_ticket("shared-001", ios="n/a", android="n/a"))

    _, errors = load(tickets_dir)

    assert "mindestens eine Plattform" in messages(errors)[0]


def test_platform_ticket_rejects_na(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", platform_ticket("ios-001", status="n/a"))

    _, errors = load(tickets_dir)

    assert "unbekannter status 'n/a'" in messages(errors)[0]


def test_unknown_dependency_is_reported(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", platform_ticket("ios-001", extra="depends_on: [ios-999]\n"))

    _, errors = load(tickets_dir)

    assert messages(errors) == ["ios/ios-001-x.md: depends_on verweist auf unbekanntes Ticket 'ios-999'"]


def test_dependency_on_archived_ticket_is_valid(tickets_dir):
    write(tickets_dir, "archive/ios/ios-001-x.md", platform_ticket("ios-001", status="done"))
    write(tickets_dir, "ios/ios-002-y.md", platform_ticket("ios-002", extra="depends_on: [ios-001]\n"))

    _, errors = load(tickets_dir)

    assert errors == []


def test_closed_ticket_outside_archive_is_reported(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", platform_ticket("ios-001", status="wontfix"))

    _, errors = load(tickets_dir)

    assert messages(errors) == ["ios/ios-001-x.md: abgeschlossenes Ticket gehoert nach 'archive/ios/'"]


def test_active_ticket_in_archive_is_reported(tickets_dir):
    write(tickets_dir, "archive/shared/shared-001-x.md", shared_ticket("shared-001", ios="done", android="todo"))

    _, errors = load(tickets_dir)

    assert messages(errors) == ["archive/shared/shared-001-x.md: aktives Ticket gehoert nach 'shared/'"]


def test_duplicate_id_is_reported(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", platform_ticket("ios-001"))
    write(tickets_dir, "ios/ios-001-y.md", platform_ticket("ios-001"))

    _, errors = load(tickets_dir)

    assert any("doppelte id 'ios-001'" in m for m in messages(errors))


def test_unknown_field_is_reported(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", platform_ticket("ios-001", extra="prio: hoch\n"))

    _, errors = load(tickets_dir)

    assert messages(errors) == ["ios/ios-001-x.md: unbekanntes Feld 'prio'"]


def test_all_errors_are_collected(tickets_dir):
    write(tickets_dir, "ios/ios-001-x.md", "kein frontmatter\n")
    write(tickets_dir, "android/android-001-x.md", platform_ticket("android-001", phase="9-Unsinn"))

    _, errors = load(tickets_dir)

    assert [path for path, _ in errors] == ["android/android-001-x.md", "ios/ios-001-x.md"]


def test_inline_yaml_comments_are_accepted(tickets_dir):
    text = (
        "---\nid: ios-001\ntitle: T\nstatus: todo  # todo | in-progress | done | wontfix\n"
        "phase: 4-Polish  # 1-Quick Fix | ...\npriority: hoch # optional\n---\n"
    )
    write(tickets_dir, "ios/ios-001-x.md", text)

    tickets, errors = load(tickets_dir)

    assert errors == []
    assert tickets[0].status == "todo"


def test_root_files_and_plans_are_not_tickets(tickets_dir):
    write(tickets_dir, "README.md", "# Readme\n")
    write(tickets_dir, "TEMPLATE-platform.md", "# Vorlage\n")
    write(tickets_dir, "INDEX.md", "# Index\n")
    write(tickets_dir, "plans/ios-001.md", "# Plan\n")

    tickets, errors = load(tickets_dir)

    assert tickets == [] and errors == []


# --- Generator -----------------------------------------------------------


def make_repo(tickets_dir):
    write(tickets_dir, "shared/shared-050-b.md", shared_ticket("shared-050", ios="done", android="todo", title="B"))
    write(tickets_dir, "archive/shared/shared-010-a.md", shared_ticket("shared-010", ios="done", android="n/a", title="A"))
    write(tickets_dir, "ios/ios-020-c.md", platform_ticket("ios-020", status="in-progress", title="C",
                                                             extra="depends_on: [shared-010]\n"))
    write(tickets_dir, "archive/ios/ios-003-d.md", platform_ticket("ios-003", status="wontfix", title="D"))
    write(tickets_dir, "android/android-003-2-e.md", platform_ticket("android-003-2", title="E"))
    write(tickets_dir, "android/android-003-f.md", platform_ticket("android-003", title="F"))


def test_index_lists_active_tickets_before_archive(tickets_dir):
    make_repo(tickets_dir)
    tickets, errors = load(tickets_dir)
    assert errors == []

    index = render_index(tickets)

    active, archive = index.split("## Archiv")
    assert "[shared-050]" in active and "[ios-020]" in active
    assert "[shared-010]" in archive and "[ios-003]" in archive
    assert "\n| [shared-010]" not in active


def test_index_rows_have_expected_format(tickets_dir):
    make_repo(tickets_dir)
    tickets, _ = load(tickets_dir)

    index = render_index(tickets)

    assert "| [shared-050](shared/shared-050-b.md) | B | 3-Feature | [x] | [ ] |" in index
    assert "| [shared-010](archive/shared/shared-010-a.md) | A | 3-Feature | [x] | - |" in index
    assert "| [ios-020](ios/ios-020-c.md) | C | 4-Polish | [~] | [shared-010](archive/shared/shared-010-a.md) |" in index
    assert "| [ios-003](archive/ios/ios-003-d.md) | D | 4-Polish | [-] | - |" in index
    assert "Generiert von `make tickets-index`" in index
    assert "[README.md](README.md)" in index


def test_index_sorts_ids_naturally(tickets_dir):
    make_repo(tickets_dir)
    tickets, _ = load(tickets_dir)

    index = render_index(tickets)

    assert index.index("[android-003]") < index.index("[android-003-2]")


def test_index_cli_writes_and_is_idempotent(tickets_dir):
    make_repo(tickets_dir)

    first = run_index(tickets_dir)
    content = (tickets_dir / "INDEX.md").read_text(encoding="utf-8")
    second = run_index(tickets_dir)
    check = run_index(tickets_dir, "--check")

    assert first.returncode == 0, first.stderr
    assert second.returncode == 0
    assert (tickets_dir / "INDEX.md").read_text(encoding="utf-8") == content
    assert check.returncode == 0


def test_index_cli_check_detects_stale_index(tickets_dir):
    make_repo(tickets_dir)
    run_index(tickets_dir)
    write(tickets_dir, "ios/ios-030-neu.md", platform_ticket("ios-030"))

    result = run_index(tickets_dir, "--check")

    assert result.returncode != 0
    assert "veraltet" in result.stderr


def test_index_cli_does_not_write_on_error(tickets_dir):
    make_repo(tickets_dir)
    (tickets_dir / "INDEX.md").write_text("alt\n", encoding="utf-8")
    write(tickets_dir, "ios/ios-031-kaputt.md", "# kein frontmatter\n")

    result = run_index(tickets_dir)

    assert result.returncode != 0
    assert "ios/ios-031-kaputt.md: Frontmatter fehlt" in result.stderr
    assert (tickets_dir / "INDEX.md").read_text(encoding="utf-8") == "alt\n"


def run_index(tickets_dir, *args):
    return subprocess.run(
        [sys.executable, str(INDEX_SCRIPT), "--tickets-dir", str(tickets_dir), *args],
        capture_output=True,
        text=True,
        check=False,
    )
