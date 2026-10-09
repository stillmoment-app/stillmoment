#!/bin/bash
#
# lint-selftest.sh — Gegenbeweis fuer die SwiftLint-Regel
# `service_created_outside_composition_root` (ios-055).
#
# Lintet eine Fixture mit bekannten Verstoessen und erlaubten Faellen und
# erwartet genau die markierten Treffer. Schlaegt fehl, wenn die Regel
# einen Verstoss nicht (mehr) erkennt oder einen erlaubten Fall meldet.
#
# Die Fixture endet auf .fixture, damit weder Xcode noch SwiftFormat noch
# der normale Lint-Lauf sie anfassen; fuer den Test wird sie als .swift
# in ein temporaeres Verzeichnis kopiert.
#
# Exit-Codes: 0 = Regel greift wie erwartet, 1 = Regel greift nicht wie
# erwartet, 3 = SwiftLint konnte nicht laufen (fehlt, Config-Fehler, Absturz).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURE="$SCRIPT_DIR/lint-fixtures/ServiceCreatedOutsideCompositionRoot.swift.fixture"
CONFIG="$IOS_DIR/.swiftlint.yml"
RULE="service_created_outside_composition_root"

echo "🧪 Lint-Selbsttest ($RULE)..."

if ! command -v swiftlint > /dev/null 2>&1; then
    echo "❌ swiftlint nicht gefunden — Selbsttest kann nicht laufen"
    exit 3
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TARGET="$TMP_DIR/ServiceCreatedOutsideCompositionRoot.swift"
cp "$FIXTURE" "$TARGET"

# Expected: every line marked "EXPECT" in the fixture, nothing else.
expected_lines="$(grep -n '// EXPECT' "$TARGET" | cut -d: -f1 | sort -n | tr '\n' ' ')"
if [ -z "$expected_lines" ]; then
    echo "❌ Fixture enthaelt keine EXPECT-Zeilen"
    exit 1
fi

# SwiftLint exits 2 when it finds error-level violations — that is the point here.
# Any other non-zero exit (missing/invalid config, crash) must not be swallowed.
set +e
output="$(swiftlint lint --quiet --no-cache --config "$CONFIG" "$TARGET" 2> "$TMP_DIR/stderr.log")"
status=$?
set -e
if [ "$status" -ne 0 ] && [ "$status" -ne 2 ]; then
    echo "❌ swiftlint ist mit Exit-Code $status abgebrochen:"
    sed 's/^/   /' "$TMP_DIR/stderr.log"
    exit 3
fi
if grep -qiE "error|invalid|could not" "$TMP_DIR/stderr.log"; then
    echo "❌ swiftlint meldet ein Problem mit Konfiguration oder Lauf:"
    sed 's/^/   /' "$TMP_DIR/stderr.log"
    exit 3
fi

actual_lines="$(printf '%s\n' "$output" | grep "($RULE)" | cut -d: -f2 | sort -n | tr '\n' ' ' || true)"

if [ "$expected_lines" != "$actual_lines" ]; then
    echo "❌ Regel greift nicht wie erwartet"
    echo "   erwartet in Zeilen: $expected_lines"
    echo "   gemeldet in Zeilen: ${actual_lines:-<keine>}"
    exit 1
fi

echo "   ✅ Regel meldet genau die erwarteten Zeilen: $expected_lines"
