---
name: screenshot-ios
description: Fernsteuert den iOS-Simulator (App tippen, wischen, tippen-mit-Text, Hardware-Tasten) und nimmt Verifikations-Screenshots auf. Aktiviere bei "Mach Screenshot...", "Tippe auf...", "Verifiziere die View visuell...", "Wische zum...", oder /screenshot-ios. NICHT fuer Fastlane/Marketing-Screenshots — dafuer /create-ui-test.
---

# Skill: iOS Simulator fernsteuern und Screenshots aufnehmen

Wrapper um axe + xcrun simctl + sips fuer den haeufigsten Loop:
**UI-Hierarchie lesen → Koordinate antippen → Screenshot verifizieren**.

Die Schritte sind als Shell-Scripts in `scripts/screenshot-ios/` versioniert.
Nicht jedes Mal neue Wege probieren — diese Scripts sind der Weg.

## Voraussetzungen

- iOS Simulator gebootet. Falls nicht: XcodeBuildMCP `boot_sim` aufrufen, oder
  `xcrun simctl boot <UDID>`.
- `axe` installiert (`brew install axe`).
- Bei mehreren gebooteten Simulatoren: `SM_IOS_UDID=<UDID>` exportieren um zu
  disambiguieren. Aktuell gebootete: `xcrun simctl list devices booted`.

## Scripts

Alle Scripts liegen unter `scripts/screenshot-ios/` und sind ausfuehrbar.
Alle ermitteln die Simulator-UDID automatisch (oder via `SM_IOS_UDID`).
Alle setzen sinnvolle Defaults (`--post-delay 1`, `--duration 0.5 --delta 5`)
hartcodiert ein — diese Werte sind durch Schmerzen erkauft, nicht anfassen.

| Script | Zweck | Output |
|--------|-------|--------|
| `udid.sh` | Liefert UDID des gebooteten Simulators | stdout |
| `dump_ui.sh [name]` | Accessibility-Hierarchie nach `tmp/<name>` (default `ui.json`) | Pfad auf stdout |
| `shot.sh [name]` | Screenshot nach `tmp/<name>`, auf 1800px resized (default `ios.png`) | Pfad auf stdout |
| `tap.sh <x> <y>` | Tippt an Koordinate | — |
| `swipe.sh <sx> <sy> <ex> <ey>` | Wischt von Start zu Ende | — |
| `type.sh <text>` | Tippt Text in fokussiertes Feld | — |
| `button.sh <name>` | Druckt Hardware-Button (home, lock, ...) | — |

## Standard-Loop

```bash
# 1. UI-Hierarchie holen und lesen
scripts/screenshot-ios/dump_ui.sh  # → schreibt tmp/ui.json
# → mit Read-Tool oeffnen, AXFrame finden, Mittelpunkt berechnen:
#   tap-x = x + width/2 ; tap-y = y + height/2

# 2. Interagieren
scripts/screenshot-ios/tap.sh 201 582

# 3. Visuell verifizieren
scripts/screenshot-ios/shot.sh   # → schreibt tmp/ios.png, gibt Pfad aus
# → mit Read-Tool oeffnen

# Wiederholen ab 1.
```

**Goldene Regel:** Nach jeder Interaktion frisch `dump_ui.sh` — gecachte Koordinaten
sind nach einem Frame schon falsch.

## Fallen, die diese Scripts NICHT loesen

- **SwiftUI `.menu`-Picker:** Element-Mittelpunkt oeffnet das Popup nicht. Tippe
  auf den Wert-Text auf der **rechten Seite** des Elements.
- **TabBar-Items:** Tauchen oft nicht im Accessibility-Baum auf und reagieren
  auch auf Koordinaten-Taps nicht zuverlaessig. Aendere den App-Zustand auf
  einem anderen Weg.
- **Wheel Picker** (z.B. Timer-Minuten): `AXValue` ist 0-basiert
  (`AXValue` 0 = 1 min). Eine Reihe ≈ 35pt. Nach Swipe immer `dump_ui.sh` und
  `AXValue` pruefen — visuelles Rendering kann nachhinken.
- **Element-Suche per `--id`:** Fragil auf iOS 18. Diese Scripts arbeiten
  ausschliesslich mit Koordinaten.

## App-Lifecycle (NICHT in Scripts)

Diese Aktionen laufen ueber **XcodeBuildMCP**-Tools und sind keine Bash-Calls:

| Aktion | Tool |
|--------|------|
| Bauen + starten | `mcp__XcodeBuildMCP__build_run_sim` |
| Nur starten | `mcp__XcodeBuildMCP__launch_app_sim` |
| Stoppen | `mcp__XcodeBuildMCP__stop_app_sim` |
| Simulator booten | `mcp__XcodeBuildMCP__boot_sim` |
| Defaults setzen | `mcp__XcodeBuildMCP__session_set_defaults` |

Vor dem ersten Build in einer Session: `session_show_defaults` aufrufen
(siehe globale MCP-Anweisungen).

## Wann diesen Skill NICHT nutzen

- **Fastlane-Marketing-Screenshots** (mehrsprachig, automatisiert via XCUITest):
  → `/create-ui-test`. Anderer Workflow, anderes Target.
- **Reine App-Lifecycle-Operationen** ohne Verifikation: direkter MCP-Aufruf.

## Wann andere Skills hier verweisen sollten

- `/review-view` und `/review-website`: wenn visuelle Verifikation einer View
  Teil der Bewertung ist.
- `/implement-ticket`: wenn die Akzeptanzkriterien eines Tickets visuelle
  UI-Aenderungen umfassen, die nicht durch Unit-Tests abgedeckt sind.

Diese Skills muessen den Verweis selbst im eigenen Markdown setzen — Skills
rufen einander nicht programmatisch auf.

## Referenzen

- Scripts: `scripts/screenshot-ios/*.sh`
- Standard-Simulator-Setup: XcodeBuildMCP `session-show-defaults`
- Tool-Hintergrund: `axe` (cameroncooke/axe, brew), `xcrun simctl`, `sips`
