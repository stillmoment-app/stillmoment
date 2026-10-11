---
name: xcodebuild-diagnose-hang
description: make test-*-agent hängt ~10 min nach roten Tests — xcodebuild startet "simctl diagnose --timeout=600"; Kindprozess gezielt beenden
metadata:
  type: feedback
---

Nach fehlschlagenden Unit-Tests (Red-Schritt) lief `make test-single-agent` jedes Mal ~610 s, obwohl
die Tests nach Sekunden fertig waren (shared-138, 2026-10-11). Ursache: `xcodebuild test` startet
danach `simctl diagnose -l -b --timeout=600` als Kindprozess und wartet darauf. Grüne Läufe sind
nicht betroffen (7–20 s).

**Why:** Kostet pro Red-Schritt 10 Minuten und sieht wie ein hängender Test aus.

**How to apply:** Test-Lauf im Hintergrund starten und währenddessen nur den Kindprozess des
*eigenen* xcodebuild beenden (andere Agenten haben eigene): Schleife über
`pgrep -f "xcodebuild test .*id=<eigene UDID>"` → `pkill -P <pid> -f "simctl diagnose"`.
Das Agent-Ergebnis (RESULT/FAILURES) bleibt vollständig. Passt zu [[dedicated-simulator-parallel-agents]].

**Share Extension echt bedienen (iOS 18.4, 430-pt-Gerät):** MP3 in
`<FileProvider.LocalStorage-Gruppe>/File Provider Storage/` legen, Dateien-App → Durchsuchen,
Datei per `axe touch --down --up --delay 1.5` lange drücken → „Teilen“ → „Still Moment“ → „Fertig“,
dann App per `simctl launch` öffnen. Für langes Ladefenster: JSON mit `https://10.255.255.1/…` in die
App-Group-`ShareInbox` + `simctl openurl stillmoment://import` (siehe [[simulator-verification-setup]]).
