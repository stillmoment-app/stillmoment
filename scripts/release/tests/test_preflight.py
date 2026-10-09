import subprocess
import sys
from pathlib import Path

from conftest import changelog, write

import preflight

PREFLIGHT_SCRIPT = Path(__file__).resolve().parent.parent / "preflight.py"

RELEASED_250 = "## [2.5.0] - 2026-08-01\n\n### Added\n- **Feature** - Beschreibung\n\n"
RELEASED_240 = "## [2.4.0] - 2026-06-19\n\n### Fixed\n- (iOS) Fix\n"


# --- CHANGELOG.md --------------------------------------------------------


def test_changelog_with_moved_entries_is_ready_for_release():
    text = changelog(sections=RELEASED_250 + RELEASED_240)

    assert preflight.check_changelog(text, "2.5.0") == []


def test_changelog_without_section_for_version_is_not_ready():
    text = changelog(sections=RELEASED_240)

    problems = preflight.check_changelog(text, "2.5.0")

    assert len(problems) == 1
    assert "## [2.5.0]" in problems[0]


def test_section_of_a_similar_version_does_not_count():
    text = changelog(sections="## [2.5.10] - 2026-09-01\n\n- x\n\n" + RELEASED_240)

    problems = preflight.check_changelog(text, "2.5.1")

    assert any("## [2.5.1]" in p for p in problems)


def test_entries_left_under_unreleased_block_the_release():
    # Praezedenzfall 2.5.0: Fastlane-Changelogs geschrieben, CHANGELOG-Umzug vergessen.
    text = changelog(unreleased="### Added\n- **Neues Feature** - Text\n\n", sections=RELEASED_250)

    problems = preflight.check_changelog(text, "2.5.0")

    assert len(problems) == 1
    assert "[Unreleased]" in problems[0]
    assert "### Added" in problems[0]


def test_missing_section_and_leftover_entries_are_both_reported():
    text = changelog(unreleased="- loser Eintrag\n\n", sections=RELEASED_240)

    problems = preflight.check_changelog(text, "2.5.0")

    assert len(problems) == 2


def test_changelog_without_unreleased_heading_only_needs_the_version_section():
    text = "# Changelog\n\n" + RELEASED_250

    assert preflight.check_changelog(text, "2.5.0") == []


# --- Release Notes (Fastlane-Changelogs) ---------------------------------


def test_release_notes_within_store_limit_pass(repo):
    de = write(repo / "de-DE/changelogs/21.txt", "- Kurze Notiz\n")
    en = write(repo / "en-US/changelogs/21.txt", "- Short note\n")

    assert preflight.check_release_notes([de, en], max_chars=500) == []


def test_release_notes_exactly_at_limit_pass(repo):
    notes = write(repo / "de-DE/changelogs/21.txt", "x" * 500)

    assert preflight.check_release_notes([notes], max_chars=500) == []


def test_release_notes_over_limit_are_reported_with_overflow(repo):
    ok = write(repo / "de-DE/changelogs/21.txt", "- ok\n")
    too_long = write(repo / "en-US/changelogs/21.txt", "y" * 501)

    problems = preflight.check_release_notes([ok, too_long], max_chars=500)

    assert len(problems) == 1
    assert "en-US/changelogs/21.txt" in problems[0]
    assert "501/500" in problems[0]


def test_umlauts_count_as_one_character_not_as_bytes(repo):
    # 250 x "ü" = 250 Zeichen, aber 500 Bytes in UTF-8.
    notes = write(repo / "de-DE/changelogs/21.txt", "ü" * 250)

    assert preflight.check_release_notes([notes], max_chars=250) == []


def test_missing_release_notes_are_reported(repo):
    missing = repo / "de-DE/changelogs/21.txt"

    problems = preflight.check_release_notes([missing], max_chars=500)

    assert len(problems) == 1
    assert "de-DE/changelogs/21.txt" in problems[0]
    assert "/release-notes" in problems[0]


def test_empty_release_notes_are_reported(repo):
    empty = write(repo / "de-DE/changelogs/21.txt", "  \n")

    problems = preflight.check_release_notes([empty], max_chars=500)

    assert len(problems) == 1
    assert "empty" in problems[0]


# --- CLI -----------------------------------------------------------------


def run_preflight(*args):
    return subprocess.run(
        [sys.executable, str(PREFLIGHT_SCRIPT), *args],
        capture_output=True,
        text=True,
        check=False,
    )


def test_cli_succeeds_when_everything_is_ready(repo):
    log = write(repo / "CHANGELOG.md", changelog(sections=RELEASED_250))
    de = write(repo / "de-DE/changelogs/2.5.0.txt", "- Notiz\n")
    en = write(repo / "en-GB/changelogs/2.5.0.txt", "- Note\n")

    result = run_preflight("--version", "2.5.0", "--changelog", str(log), "--max-chars", "4000", str(de), str(en))

    assert result.returncode == 0, result.stderr
    assert "2.5.0" in result.stdout


def test_cli_fails_and_lists_every_problem(repo):
    log = write(repo / "CHANGELOG.md", changelog(unreleased="### Fixed\n- x\n\n", sections=RELEASED_240))
    too_long = write(repo / "de-DE/changelogs/21.txt", "z" * 600)
    missing = repo / "en-US/changelogs/21.txt"

    result = run_preflight("--version", "2.5.0", "--changelog", str(log), "--max-chars", "500", str(too_long), str(missing))

    assert result.returncode == 1
    assert "## [2.5.0]" in result.stderr
    assert "[Unreleased]" in result.stderr
    assert "600/500" in result.stderr
    assert "en-US/changelogs/21.txt" in result.stderr


def test_cli_reports_missing_changelog_file(repo):
    result = run_preflight("--version", "2.5.0", "--changelog", str(repo / "CHANGELOG.md"), "--max-chars", "500")

    assert result.returncode == 1
    assert "CHANGELOG.md" in result.stderr
