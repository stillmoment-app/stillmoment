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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURE="$SCRIPT_DIR/lint-fixtures/ServiceCreatedOutsideCompositionRoot.swift.fixture"
RULE="service_created_outside_composition_root"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TARGET="$TMP_DIR/ServiceCreatedOutsideCompositionRoot.swift"
cp "$FIXTURE" "$TARGET"

# Expected: every line marked "EXPECT" in the fixture, nothing else.
expected_lines="$(grep -n '// EXPECT' "$TARGET" | cut -d: -f1 | sort -n | tr '\n' ' ')"

# swiftlint exits non-zero when it finds violations — that is the point here.
output="$(swiftlint lint --quiet --no-cache --config "$IOS_DIR/.swiftlint.yml" "$TARGET" 2>/dev/null || true)"
actual_lines="$(printf '%s\n' "$output" | grep "($RULE)" | cut -d: -f2 | sort -n | tr '\n' ' ' || true)"

echo "🧪 Lint-Selbsttest ($RULE)..."
if [ -z "$expected_lines" ]; then
    echo "❌ Fixture enthaelt keine EXPECT-Zeilen"
    exit 1
fi

if [ "$expected_lines" != "$actual_lines" ]; then
    echo "❌ Regel greift nicht wie erwartet"
    echo "   erwartet in Zeilen: $expected_lines"
    echo "   gemeldet in Zeilen: ${actual_lines:-<keine>}"
    exit 1
fi

echo "   ✅ Regel meldet genau die erwarteten Zeilen: $expected_lines"
