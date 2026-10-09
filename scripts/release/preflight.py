# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Release-Preflight: prueft CHANGELOG.md und die Fastlane-Release-Notes vor release-prepare.

    uv run scripts/release/preflight.py --version 2.6.0 --max-chars 500 \\
        android/fastlane/metadata/android/de-DE/changelogs/21.txt \\
        android/fastlane/metadata/android/en-US/changelogs/21.txt

Prueft:
  - CHANGELOG.md hat eine Sektion "## [VERSION]" und unter "## [Unreleased]" stehen
    keine Eintraege mehr (der Umzug aus /release-notes Schritt 10 ist passiert).
  - Jede uebergebene Release-Notes-Datei existiert, ist nicht leer und hat hoechstens
    --max-chars Zeichen (Unicode-Zeichen, nicht Bytes; Play Store 500, App Store 4000).

Exit 0 = bereit, Exit 1 = mindestens ein Problem (alle werden auf stderr gelistet).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

DEFAULT_CHANGELOG = Path(__file__).resolve().parents[2] / "CHANGELOG.md"
SECTION_RE = re.compile(r"^## \[")
UNRELEASED_HEADING = "## [Unreleased]"
MAX_LISTED_ENTRIES = 3


def check_changelog(text: str, version: str) -> list[str]:
    """Gibt die Probleme zurueck, die einen Release von `version` blockieren."""
    lines = text.splitlines()
    problems: list[str] = []

    version_heading = re.compile(rf"^## \[{re.escape(version)}\](\s|$)")
    if not any(version_heading.match(line) for line in lines):
        problems.append(
            f"CHANGELOG.md has no section '## [{version}]' — "
            "move the [Unreleased] entries there (/release-notes step 10)."
        )

    leftovers = _unreleased_entries(lines)
    if leftovers:
        listed = "; ".join(leftovers[:MAX_LISTED_ENTRIES])
        more = f" (+{len(leftovers) - MAX_LISTED_ENTRIES} more)" if len(leftovers) > MAX_LISTED_ENTRIES else ""
        problems.append(
            f"CHANGELOG.md still has {len(leftovers)} line(s) under '[Unreleased]': {listed}{more} — "
            f"move them to '## [{version}]'."
        )

    return problems


def _unreleased_entries(lines: list[str]) -> list[str]:
    """Nicht-leere Zeilen zwischen '## [Unreleased]' und der naechsten '## ['-Zeile."""
    entries: list[str] = []
    inside = False
    for line in lines:
        if SECTION_RE.match(line):
            if inside:
                break
            inside = line.strip() == UNRELEASED_HEADING
            continue
        if inside and line.strip():
            entries.append(_shorten(line.strip()))
    return entries


def _shorten(line: str, width: int = 60) -> str:
    return line if len(line) <= width else line[: width - 1] + "…"


def check_release_notes(paths: list[Path], max_chars: int) -> list[str]:
    """Prueft Existenz, Inhalt und Zeichenlimit jeder Release-Notes-Datei."""
    problems: list[str] = []
    for path in paths:
        label = _label(path)
        if not path.is_file():
            problems.append(f"Release notes missing: {label} — run '/release-notes' first.")
            continue
        text = path.read_text(encoding="utf-8")
        if not text.strip():
            problems.append(f"Release notes empty: {label}")
            continue
        length = len(text)
        if length > max_chars:
            problems.append(
                f"Release notes too long: {label} has {length}/{max_chars} characters ({length - max_chars} over)."
            )
    return problems


def _label(path: Path) -> str:
    """<locale>/changelogs/<datei> — kurz genug fuer die Ausgabe, eindeutig genug zum Finden."""
    return "/".join(path.parts[-3:])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--version", required=True, help="Release-Version, z.B. 2.6.0")
    parser.add_argument("--changelog", type=Path, default=DEFAULT_CHANGELOG, help="Pfad zur CHANGELOG.md")
    parser.add_argument("--max-chars", type=int, required=True, help="Zeichenlimit je Release-Notes-Datei")
    parser.add_argument("notes", nargs="*", type=Path, help="Release-Notes-Dateien (eine pro Locale)")
    args = parser.parse_args(argv)

    if args.changelog.is_file():
        problems = check_changelog(args.changelog.read_text(encoding="utf-8"), args.version)
    else:
        problems = [f"CHANGELOG.md not found: {args.changelog}"]
    problems += check_release_notes(args.notes, args.max_chars)

    if problems:
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        return 1

    sizes = ", ".join(f"{_label(p).split('/')[0]} {len(p.read_text(encoding='utf-8'))}/{args.max_chars}" for p in args.notes)
    print(f"CHANGELOG.md ready for {args.version}" + (f"; release notes: {sizes}" if sizes else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
