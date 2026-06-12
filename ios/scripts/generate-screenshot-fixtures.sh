#!/usr/bin/env bash
#
# generate-screenshot-fixtures.sh
#
# Regenerates the 5 screenshot test-fixture MP3s for the StillMoment-Screenshots
# target. These are NOT real meditations — they are synthetic audio whose only job
# is to render a natural, gently "breathing" waveform in the player (the waveform
# reads real PCM peak amplitudes, so silent fixtures would draw a flat line).
#
# Each fixture gets its own envelope (different sine periods/phases) so the 5
# meditations don't look identical in screenshots. Durations match the values
# hardcoded in TestFixtureSeeder.swift so the library length and the actual audio
# length stay in sync.
#
# Requires: ffmpeg (brew install ffmpeg)
# Usage:    ios/scripts/generate-screenshot-fixtures.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/../StillMoment-Screenshots/Resources/TestFixtures"

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "error: ffmpeg not found (brew install ffmpeg)" >&2
    exit 1
fi

mkdir -p "$OUT_DIR"

# name|duration_seconds|volume_envelope_expression
# Envelope = floor + sum of slow sines (calm swells). Distinct periods/phases per file.
FIXTURES=(
  "test-mindful-breathing|453|0.24+0.30*(0.5+0.5*sin(2*PI*t/13.0+0.4))+0.24*(0.5+0.5*sin(2*PI*t/5.1))+0.16*(0.5+0.5*sin(2*PI*t/2.3+1.1))"
  "test-body-scan|942|0.20+0.32*(0.5+0.5*sin(2*PI*t/17.0))+0.22*(0.5+0.5*sin(2*PI*t/6.4+0.7))+0.18*(0.5+0.5*sin(2*PI*t/2.9+2.0))"
  "test-loving-kindness|737|0.26+0.28*(0.5+0.5*sin(2*PI*t/9.5+1.3))+0.26*(0.5+0.5*sin(2*PI*t/4.2))+0.14*(0.5+0.5*sin(2*PI*t/1.8+0.5))"
  "test-evening-wind-down|1145|0.18+0.34*(0.5+0.5*sin(2*PI*t/21.0+0.9))+0.20*(0.5+0.5*sin(2*PI*t/7.7))+0.16*(0.5+0.5*sin(2*PI*t/3.3+1.6))"
  "test-present-moment|1548|0.22+0.30*(0.5+0.5*sin(2*PI*t/15.0+2.2))+0.24*(0.5+0.5*sin(2*PI*t/5.8+0.3))+0.16*(0.5+0.5*sin(2*PI*t/2.6))"
)

for entry in "${FIXTURES[@]}"; do
    IFS='|' read -r name duration envelope <<< "$entry"
    out="$OUT_DIR/$name.mp3"
    echo "Generating $name.mp3 (${duration}s)..."
    ffmpeg -y -loglevel error \
        -f lavfi -i "anoisesrc=color=brown:amplitude=0.9:duration=$duration" \
        -af "volume='$envelope':eval=frame" \
        -ar 22050 -ac 1 -b:a 16k \
        "$out"
done

echo "Done. Regenerated ${#FIXTURES[@]} fixtures in $OUT_DIR"
