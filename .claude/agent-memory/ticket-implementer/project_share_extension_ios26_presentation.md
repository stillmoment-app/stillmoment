---
name: share-extension-ios26-presentation
description: Share-Extension-Darstellung auf iOS 26 — NSExtensionActionWantsFullScreenPresentation wird ignoriert, Sheet opak; Share-Sheet im Simulator ueber Safari automatisierbar
metadata:
  type: project
---

Spike ios-059 (2026-10-09): `NSExtensionActionWantsFullScreenPresentation = true` +
halbtransparente View wirkt auf iOS 18.4 (fremde App abgedunkelt sichtbar, Vollbild),
auf iOS 26.5 **nicht**: die Extension bleibt ein Sheet (runde Ecken, ~75pt unter dem
oberen Rand) mit opakem Hintergrund. Erst das Leeren aller `superview`-Hintergruende
(private Hierarchie, Hack) macht es durchsichtig — aber es bleibt Sheet-Form.

**Why:** ios-059 wollte eine Karte ueber der abgedunkelten fremden App; darauf hing
das ganze Ticket. Orchestrator hatte fuer diesen Fall STOPP angeordnet.

**How to apply:** Bei jedem Extension-UI-Ticket diesen Befund vor Planung pruefen
(ob er auf neueren iOS-Versionen noch gilt). Verifikation ohne Dateien-App: im Simulator
`xcrun simctl openurl <udid> https://www.audiodharma.org/` → Safari-Teilen (iOS 26:
"..."-Menue → Teilen) → "Still Moment" antippen; Koordinaten per Screenshot/430pt-Skala.
Eigene Spike-Artefakte danach aus `ShareInbox` im App-Group-Container loeschen
(`xcrun simctl get_app_container <udid> com.stillmoment.StillMoment group.com.stillmoment`).
