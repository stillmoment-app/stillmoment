import subprocess

import pytest
from conftest import write

import migrate
import ticketlib

# --- Status-Zeilen der alten Ticket-Dateien -----------------------------------


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("[ ] TODO", "todo"),
        ("[x] DONE ", "done"),
        ("[x] DONE (2026-05-03)", "done"),
        ("[x] DONE (iOS + Android)", "done"),
        ("[x] DONE (beide Plattformen)", "done"),
        ("[x] WONTFIX", "wontfix"),
        ("[-] WONTFIX", "wontfix"),
        ("[x] WONTFIX (obsolet durch android-036)", "wontfix"),
        ("[~] IN PROGRESS", "in-progress"),
        ("[x] SPLIT → shared-043, shared-044, shared-045, shared-046", "done"),
        ("[x] SPLIT — Aufgeteilt in shared-061 bis shared-066", "done"),
        ("[ ] TODO | [~] IN PROGRESS | [x] DONE → **[x] DONE**", "done"),
    ],
)
def test_status_line_variants(raw, expected):
    lead, per_platform = migrate.parse_status_line(raw)

    assert lead == expected
    assert per_platform == {}


def test_template_status_line_without_choice_is_unparseable():
    assert migrate.parse_status_line("[ ] TODO | [~] IN PROGRESS | [x] DONE") == (None, {})


def test_garbage_status_line_is_unparseable():
    assert migrate.parse_status_line("irgendwann") == (None, {})


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("[x] DONE (iOS)", {"ios": "done"}),
        ("[x] DONE (iOS) / [ ] TODO (Android)", {"ios": "done", "android": "todo"}),
        ("[x] DONE (iOS) — Android [-] WONTFIX, obsolet durch shared-097", {"ios": "done", "android": "wontfix"}),
        ("[~] IN PROGRESS (iOS done, Android offen)", {"ios": "done", "android": "todo"}),
        ("[~] IN PROGRESS (iOS DONE, Android offen)", {"ios": "done", "android": "todo"}),
    ],
)
def test_status_line_with_platform_qualifiers(raw, expected):
    _, per_platform = migrate.parse_status_line(raw)

    assert per_platform == expected


@pytest.mark.parametrize(
    ("cell", "expected"),
    [
        ("[x]", "done"),
        ("[ ]", "todo"),
        ("[~]", "in-progress"),
        ("[-]", "wontfix"),
        ("-", "n/a"),
        ("[x] SPLIT", "done"),
        ("[x] WONTFIX", "wontfix"),
        ("[x] DONE", "done"),
        ("— WONTFIX (uebersprungen, da shared-089 ...)", "wontfix"),
        ("via ios-048", "done"),
        ("shared-057", None),
    ],
)
def test_index_cell_variants(cell, expected):
    value, _ = migrate.parse_cell(cell)

    assert value == expected


# --- Migration gegen ein Mini-Repo --------------------------------------------

OLD_INDEX = """# Stillmoment Ticket-System

## Cross-Platform Tickets

| Nr | Ticket | Phase | iOS | Android |
|----|--------|-------|-----|---------|
| [shared-001](shared/shared-001-fade.md) | Ambient Fade | 4-Polish | [x] | [x] |
| [shared-002](shared/shared-002-tab.md) | Letzter Tab | 4-Polish | [x] | [ ] |
| [shared-003](shared/shared-003-geist.md) | Geister-Zeile | 4-Polish | [ ] | [ ] |

## iOS Tickets

| Nr | Ticket | Phase | Status | Abhaengigkeit |
|----|--------|-------|--------|---------------|
| [ios-001](ios/ios-001-kopfhoerer.md) | Kopfhoerer | 1-Quick Fix | [x] | - |
| [ios-002](ios/ios-002-offen.md) | Offen | 3-Feature | [ ] | ios-001 |
| [ios-003](ios/ios-003-obsolet.md) | Obsolet | 5-QA | [x] WONTFIX | obsolet durch ios-002 |
"""

SHARED_001 = """# Ticket shared-001: Ambient Sound Fade

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: klein
**Phase**: 4-Polish

---

## Was

Fade.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | shared-115 (vorhanden) |

iOS wird zuerst umgesetzt.

---

## Akzeptanzkriterien

- [x] fertig
"""

SHARED_002 = """# Ticket shared-002: Letzten Tab merken

**Status**: [~] IN PROGRESS
**Prioritaet**: MITTEL
**Phase**: 4-Polish

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## Hinweise

- bestehender Hinweis
"""

IOS_001 = """# Ticket ios-001: Play/Pause Kopfhoerer

**Status**: [x] DONE
**Plan**: [Plan](../plans/ios-001.md)
**Prioritaet**: KRITISCH
**Phase**: 1-Quick Fix

---

Siehe auch [shared-002](../shared/shared-002-tab.md).
"""

IOS_002 = """# Ticket ios-002: Offen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG (Polish)
**Phase**: 3-Feature

---

Baut auf [ios-001](../ios/ios-001-kopfhoerer.md) auf.
"""

IOS_003 = """# Ticket ios-003: Obsolet

**Status**: [x] WONTFIX (obsolet durch ios-002)
**Prioritaet**: MITTEL
**Phase**: 5-QA

---

## Was

Nichts.
"""

PLAN_IOS_001 = """# Plan ios-001

Ticket: [ios-001](../ios/ios-001-kopfhoerer.md#was), aktiv: [ios-002](../ios/ios-002-offen.md)
Extern: [Apple](https://developer.apple.com), Doppelt: [x](../../tickets/ios/ios-001-kopfhoerer.md)
"""


@pytest.fixture
def old_repo(tmp_path):
    root = tmp_path / "dev-docs" / "tickets"
    write(root, "INDEX.md", OLD_INDEX)
    write(root, "shared/shared-001-fade.md", SHARED_001)
    write(root, "shared/shared-002-tab.md", SHARED_002)
    write(root, "ios/ios-001-kopfhoerer.md", IOS_001)
    write(root, "ios/ios-002-offen.md", IOS_002)
    write(root, "ios/ios-003-obsolet.md", IOS_003)
    write(root, "android/android-001-ohne-index.md", "# Ticket android-001: Ohne Index\n\n**Status**: [ ] TODO\n**Phase**: 4-Polish\n")
    write(root, "plans/ios-001.md", PLAN_IOS_001)
    return root


def test_plan_reports_index_rows_without_file_and_files_without_row(old_repo):
    plan = migrate.build_plan(old_repo, resolutions={})

    assert "shared-003: INDEX verweist auf shared/shared-003-geist.md, Datei fehlt" in plan.report["index_without_file"]
    assert "android-001: android/android-001-ohne-index.md" in plan.report["file_without_index"]


def test_plan_detects_status_conflict_per_platform(old_repo):
    text = SHARED_002.replace("| Android   | [ ]", "| Android   | [x]")
    write(old_repo, "shared/shared-002-tab.md", text)

    plan = migrate.build_plan(old_repo, resolutions={})

    assert "shared-002 android: Datei=done, INDEX=todo" in plan.report["status_conflicts"]
    assert plan.blocking


def test_plan_detects_platform_status_conflict(old_repo):
    write(old_repo, "ios/ios-002-offen.md", IOS_002.replace("[ ] TODO", "[x] DONE"))

    plan = migrate.build_plan(old_repo, resolutions={})

    assert "ios-002: Datei=done, INDEX=todo" in plan.report["status_conflicts"]


def test_conflict_is_resolved_by_explicit_resolution(old_repo):
    write(old_repo, "ios/ios-002-offen.md", IOS_002.replace("[ ] TODO", "[x] DONE"))

    plan = migrate.build_plan(old_repo, resolutions={"ios-002": {"status": "index"}})

    assert plan.report["status_conflicts"] == []
    assert plan.items_by_id["ios-002"].frontmatter["status"] == "todo"


def test_status_line_contradicting_index_aggregate_is_a_conflict(old_repo):
    write(old_repo, "shared/shared-002-tab.md", SHARED_002.replace("[~] IN PROGRESS", "[x] DONE"))

    plan = migrate.build_plan(old_repo, resolutions={})

    assert any(c.startswith("shared-002 Status-Zeile") for c in plan.report["status_conflicts"])


def test_plan_reports_free_text_dependencies(old_repo):
    plan = migrate.build_plan(old_repo, resolutions={})

    free = plan.report["free_text"]
    assert "shared-001 android: shared-115 (vorhanden)" in free
    assert "ios-003: obsolet durch ios-002" in free


def test_plan_builds_frontmatter_and_moves(old_repo):
    plan = migrate.build_plan(old_repo, resolutions={})
    items = plan.items_by_id

    assert items["shared-001"].frontmatter == {
        "id": "shared-001",
        "title": "Ambient Fade",
        "status": {"ios": "done", "android": "done"},
        "phase": "4-Polish",
        "priority": "hoch",
        "depends_on": [],
    }
    assert items["shared-001"].target == "archive/shared/shared-001-fade.md"
    assert items["shared-002"].target == "shared/shared-002-tab.md"
    assert items["ios-002"].frontmatter["depends_on"] == ["ios-001"]
    assert items["ios-002"].frontmatter["priority"] == "niedrig"
    assert items["ios-003"].frontmatter["status"] == "wontfix"
    assert items["android-001"].frontmatter["title"] == "Ohne Index"


def test_body_drops_status_lines_and_platform_section(old_repo):
    plan = migrate.build_plan(old_repo, resolutions={})

    body = plan.items_by_id["shared-001"].content

    assert body.startswith("---\nid: shared-001\n")
    assert "**Status**" not in body and "**Prioritaet**" not in body and "**Phase**:" not in body
    assert "**Aufwand**: klein" in body
    assert "## Plattform-Status" not in body
    assert "# Ticket shared-001: Ambient Sound Fade\n\n**Aufwand**: klein\n\n---\n\n## Was" in body
    assert "Fade.\n\n---\n\n## Akzeptanzkriterien" in body
    assert body.endswith(
        "## Hinweise\n\n"
        "- Abhaengigkeit Android (aus Plattform-Status): shared-115 (vorhanden)\n"
        "- iOS wird zuerst umgesetzt.\n"
    )


def test_hinweise_are_appended_to_existing_section(old_repo):
    write(
        old_repo,
        "shared/shared-002-tab.md",
        SHARED_002.replace("| iOS       | [x]    | -  ", "| iOS       | [x]    | nur Teil 2"),
    )

    plan = migrate.build_plan(old_repo, resolutions={})

    body = plan.items_by_id["shared-002"].content
    assert body.count("## Hinweise") == 1
    assert "- bestehender Hinweis\n- Abhaengigkeit iOS (aus Plattform-Status): nur Teil 2" in body


def test_links_in_moved_ticket_are_rewritten(old_repo):
    plan = migrate.build_plan(old_repo, resolutions={})

    content = plan.items_by_id["ios-001"].content

    assert "[Plan](../../plans/ios-001.md)" in content
    assert "[shared-002](../../shared/shared-002-tab.md)" in content


def test_links_to_moved_ticket_are_rewritten_in_other_files(old_repo):
    plan = migrate.build_plan(old_repo, resolutions={})

    ios_002 = plan.items_by_id["ios-002"].content
    plan_text = plan.link_updates["plans/ios-001.md"]

    assert "[ios-001](../archive/ios/ios-001-kopfhoerer.md)" in ios_002
    assert "[ios-001](../archive/ios/ios-001-kopfhoerer.md#was)" in plan_text
    assert "[ios-002](../ios/ios-002-offen.md)" in plan_text
    assert "[x](../archive/ios/ios-001-kopfhoerer.md)" in plan_text
    assert "[Apple](https://developer.apple.com)" in plan_text
    assert plan.rewritten_links >= 5


def test_old_index_is_not_link_rewritten(old_repo):
    plan = migrate.build_plan(old_repo, resolutions={})

    assert "INDEX.md" not in plan.link_updates


def test_blocked_ticket_does_not_cause_follow_up_dependency_error(old_repo):
    write(old_repo, "ios/ios-001-kopfhoerer.md", IOS_001.replace("**Phase**: 1-Quick Fix", "**Phase**: 9-Unsinn"))
    text = OLD_INDEX.replace("| 1-Quick Fix |", "| 9-Unsinn |")
    write(old_repo, "INDEX.md", text)

    plan = migrate.build_plan(old_repo, resolutions={})

    assert plan.report["phase_problems"] == ["ios-001: unbekannte Phase '9-Unsinn'"]
    assert plan.report["validation"] == []


def test_extra_platform_rows_drop_empty_cells(old_repo):
    text = SHARED_002.replace("| Android   | [ ]    | -             |", "| Android   | [ ]    | -             |\n| Website | [ ] | - |")
    write(old_repo, "shared/shared-002-tab.md", text)

    plan = migrate.build_plan(old_repo, resolutions={})

    assert "shared-002: Website: [ ]" in plan.report["moved_to_hinweise"]


def test_generated_tickets_are_valid(old_repo):
    plan = migrate.build_plan(old_repo, resolutions={})

    assert plan.report["validation"] == []


def test_real_run_refuses_on_conflict(old_repo):
    git_init(old_repo)
    write(old_repo, "ios/ios-002-offen.md", IOS_002.replace("[ ] TODO", "[x] DONE"))

    code = migrate.main(["--tickets-dir", str(old_repo)])

    assert code != 0
    assert (old_repo / "ios/ios-002-offen.md").read_text(encoding="utf-8").startswith("# Ticket")


def test_real_run_migrates_with_git_mv(old_repo):
    git_init(old_repo)

    code = migrate.main(["--tickets-dir", str(old_repo)])

    assert code == 0
    assert not (old_repo / "ios/ios-001-kopfhoerer.md").exists()
    moved = old_repo / "archive/ios/ios-001-kopfhoerer.md"
    assert moved.read_text(encoding="utf-8").startswith("---\nid: ios-001\n")
    status = subprocess.run(["git", "status", "--porcelain"], cwd=old_repo, capture_output=True, text=True).stdout
    assert "RM ios/ios-001-kopfhoerer.md -> archive/ios/ios-001-kopfhoerer.md" in status
    assert "[ios-001](../archive/ios/ios-001-kopfhoerer.md#was)" in (old_repo / "plans/ios-001.md").read_text("utf-8")

    tickets, errors = ticketlib.load_tickets(old_repo)
    assert errors == []
    assert len(tickets) == 6


def test_dry_run_changes_nothing(old_repo, capsys):
    before = {p: p.read_text("utf-8") for p in old_repo.rglob("*.md")}

    code = migrate.main(["--tickets-dir", str(old_repo), "--dry-run"])

    assert code == 0
    assert {p: p.read_text("utf-8") for p in old_repo.rglob("*.md")} == before
    assert "Geplante Verschiebungen" in capsys.readouterr().out


def git_init(root):
    for args in (
        ["init", "-q"],
        ["add", "."],
        ["-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "init"],
    ):
        subprocess.run(["git", *args], cwd=root, check=True)
