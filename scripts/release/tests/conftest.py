import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

HEADER = (
    "# Changelog\n\n"
    "All notable changes to Still Moment will be documented in this file.\n\n"
)


def changelog(unreleased: str = "", sections: str = "") -> str:
    """Baut eine CHANGELOG.md im Keep-a-Changelog-Format wie im Repo."""
    return f"{HEADER}## [Unreleased]\n\n{unreleased}{sections}"


def write(path: Path, text: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


@pytest.fixture
def repo(tmp_path):
    """Leeres Arbeitsverzeichnis fuer CHANGELOG.md und Release-Notes-Dateien."""
    return tmp_path
