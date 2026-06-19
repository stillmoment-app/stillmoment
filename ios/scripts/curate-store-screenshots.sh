#!/bin/bash
# curate-store-screenshots.sh
#
# Reduziert die generierten Screenshots auf die kuratierte App-Store-Auswahl
# und nummeriert sie in die gewuenschte Anzeige-Reihenfolge um.
#
# Laeuft automatisch am Ende der `screenshots`-Fastlane-Lane (nach
# process-screenshots.sh, das vorher ALLE Screenshots fuer die Website sichert).
# Kein manueller Schritt pro Release.
#
# Idempotent: mehrfaches Ausfuehren aendert nichts.
#
# >>> Um die App-Store-Auswahl zu aendern: NUR die ORDER-Liste unten anpassen. <<<
# Apple erlaubt max. 10 Screenshots pro Geraetegroesse/Sprache.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHOTS_DIR="$SCRIPT_DIR/../fastlane/screenshots"
LOCALES=(de-DE en-GB)

# Kuratierte App-Store-Auswahl, in Anzeige-Reihenfolge (Library zuerst).
# Gematcht wird ueber den Screen-Schluessel (Token nach NN_ im Dateinamen).
ORDER=(
  LibraryList     # Bibliothek = Kern-Feature zuerst
  PlayerView      # Wellenform-Player (neu in 2.4.0)
  TrimEditor      # Zuschneiden (neu in 2.4.0)
  LibrarySearch
  ImportGuide
  GongSelection   # neu gestaltet
  Soundscape      # neu gestaltet
  TimerIdle
  TimerRunning
  Completion
)

position_of() {
  local key="$1" i
  for i in "${!ORDER[@]}"; do
    [ "${ORDER[$i]}" = "$key" ] && { echo "$i"; return 0; }
  done
  echo -1
}

curate_dir() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  shopt -s nullglob
  local tmps=() finals=() f base pre key pos nn tmp i
  for f in "$dir"/*.png; do
    base="$(basename "$f")"
    # Erwartet <Geraete-Prefix>NN_Key.png ; alles andere wird nicht angefasst.
    if [[ "$base" =~ ^(.*)([0-9]{2})_([A-Za-z0-9]+)\.png$ ]]; then
      pre="${BASH_REMATCH[1]}"
      key="${BASH_REMATCH[3]}"
      pos="$(position_of "$key")"
      if [ "$pos" -lt 0 ]; then
        rm -f "$f"
      else
        printf -v nn "%02d" $((pos + 1))
        tmp="$dir/.curate_tmp_${#tmps[@]}_$$"
        mv "$f" "$tmp"
        tmps+=("$tmp")
        finals+=("$dir/${pre}${nn}_${key}.png")
      fi
    fi
  done
  for i in "${!tmps[@]}"; do
    mv "${tmps[$i]}" "${finals[$i]}"
  done
  echo "  $(basename "$dir"): ${#tmps[@]} Screenshots behalten"
}

echo "Kuratiere App-Store-Screenshots (max. ${#ORDER[@]})..."
for loc in "${LOCALES[@]}"; do
  curate_dir "$SHOTS_DIR/$loc"
done
echo "Fertig."
