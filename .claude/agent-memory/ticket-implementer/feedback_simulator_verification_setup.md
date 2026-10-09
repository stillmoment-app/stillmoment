---
name: simulator-verification-setup
description: Visuelle Verifikation am Simulator — App auf Deutsch starten, sonst fehlen DE-only-Features; Lade- und Fehlerbilder brauchen ein gepatchtes App-Bundle.
metadata:
  type: feedback
---

Layout-Aenderungen werden in diesem Projekt am Simulator gegengeprueft, nicht nur per
Test. Zwei Dinge kosten sonst jedes Mal einen Fehlversuch:

1. **App mit deutscher Sprache starten.** Nicht nur den Simulator umstellen:
   `xcrun simctl launch <udid> com.stillmoment.StillMoment -AppleLanguages "(de)" -AppleLocale "de_DE"`.
   Die kuratierte Quellenliste ist DE-only (`meditation_sources.json`), der ganze
   Podcast-Abschnitt fehlt auf Englisch.
2. **Hell/Dunkel kommt aus der App, nicht vom System.** `xcrun simctl ui <udid> appearance
   light` bleibt wirkungslos, wenn in den App-Einstellungen „Dunkel" fest gewaehlt ist —
   Einstellungen-Tab → Darstellung umstellen.

**Why:** Die echten Feeds antworten in unter einer Sekunde. Lade- und Fehlerbild lassen
sich deshalb nicht durch schnelles Tippen erwischen.

**How to apply:** Fuer Ladezustand und Fehlerbild das gebaute `.app` kopieren, im Kopie-
Bundle in `meditation_sources.json` eine Feed-Adresse auf eine haengende (`https://10.255.255.1/…`)
und eine auf eine ungueltige (`https://…​.invalid/…`) setzen, das gepatchte Bundle
installieren, pruefen, danach das unveraenderte wieder installieren.

**Share-/Import-Flows ohne Share-Sheet nachstellen (ios-060, 2026-10-09):**
- Start-Tab setzen: `simctl spawn … defaults write` landet NICHT im App-Container — stattdessen
  Tab in der App antippen (iOS-26-Tab-Leiste reagiert auf `tap.sh`, iPhone 17 Pro: y=820 pt,
  x=102/200/300), dann `simctl terminate`; Wert per `plutil -p <data-container>/Library/Preferences/com.stillmoment.StillMoment.plist` pruefen.
- `.mp3` oder `.json` (`{"url","filename","timestamp"}`) nach `<group-container>/ShareInbox/`, dann
  `simctl openurl <udid> stillmoment://import`. Ist die App nicht vorne, fragt SpringBoard
  „In Still Moment oeffnen?" — „Oeffnen" antippen.
- Vorher-Nachweis: geaenderte Datei per `git checkout HEAD~1 -- <datei>` zuruecksetzen, in eigenen
  `-derivedDataPath` bauen, sofort `git checkout HEAD -- <datei>`, installieren, Szenario wiederholen.
- Eigenen Simulator per `simctl clone` anlegen und am Ende `simctl delete` — nicht 91211B93 nutzen. Fuer den
Fortschrittskreis eine lange Folge antippen und `xcrun simctl io … screenshot` mehrfach
ohne Pause hintereinander aufrufen.
