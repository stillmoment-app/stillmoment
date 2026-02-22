# Discussion Items: shared-054

Gesammelt waehrend automatischem Review. Zum spaeteren Abarbeiten.

## Review-Runde 1

- ~~AudioService.kt:195 / AudioService.kt:306 – Wenn `mediaPlayerFactory.createFromResource(resourceId)` `null` zurückgibt (z.B. bei `resourceId == 0`), ist die PREVIEW-Session angefordert aber nie freigegeben.~~ **Gefixt:** `requestAudioSession` wird jetzt erst nach erfolgreicher Player-Erstellung aufgerufen. Kein Session-Leak mehr moeglich.
- AudioServiceTest.kt:404 – `preview conflict handler stops all preview players` startet nur einen Gong-Preview. Ein zweites Szenario mit laufendem Background-Preview würde `cleanupPreviewPlayers()` vollständiger abdecken – ist aber kein Bug, da das Verhalten symmetrisch und bereits durch andere Tests gestützt ist. **Entscheidung:** Kein Handlungsbedarf.
