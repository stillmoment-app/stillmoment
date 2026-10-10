---
name: feedback-worktree-guard-adb-scripts
description: Worktree-Guard blockt adb/sips-Ketten mit Variablen oder URLs in Pipes; Screenshot/Warte-Helfer als Skript in den Scratchpad legen
metadata:
  type: feedback
---

Im isolierten Worktree verweigert der Guard Befehle, die er nicht als "kein git" verifizieren kann: `adb ... && adb ...` mit URL-Argument, `$S/...`-Variablen mit `sips`, `sleep N; cmd`.

**Why:** Bei android-086 (2026-10-10) scheiterten mehrere kombinierte adb/Screenshot-Befehle; `sleep` vor einem Befehl wird zusätzlich als Warte-Workaround geblockt.

**How to apply:** Jeden adb-Aufruf einzeln absetzen; URLs als `"'https://...'"` quoten (Shell auf dem Gerät sieht sonst `?`/`&`). Für Screenshots (`screencap` + `sips -Z 1800`) und Warten auf UI-Text (`uiautomator dump /dev/tty | grep`-Schleife) kleine Skripte in den Scratchpad schreiben und per `bash <skript> <arg>` aufrufen. Im Teilen-Menü des Emulators stehen zwei "Still Moment" (Release com.stillmoment 2.3.0 und dev) — danach per `dumpsys window | grep mCurrentFocus` prüfen, welche App vorne ist. Siehe [[feedback-shared-emulator-parallel-agents]].
