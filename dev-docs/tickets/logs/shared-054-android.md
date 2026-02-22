# Implementation Log: shared-054

Ticket: dev-docs/tickets/shared/shared-054-preview-audio-trennen.md
Platform: android
Branch: feature/shared-054-android
Started: 2026-02-22 18:32

---

## IMPLEMENT
Status: DONE
Commits:
- e451695 feat(android): #shared-054 Separate preview audio from timer lifecycle

Challenges:
<!-- CHALLENGES_START -->
- Android-Previews nutzten den AudioSessionCoordinator bisher gar nicht (im Gegensatz zu iOS, wo sie faelschlicherweise .timer nutzten). Die Aenderung fuegt also erstmals saubere Session-Verwaltung hinzu statt eine bestehende zu korrigieren.
- stopGongPreview/stopBackgroundPreview muessen idempotent bleiben — releaseAudioSession darf nur aufgerufen werden wenn tatsaechlich ein Player aktiv war. Loesung: `hadPlayer`-Flag vor Cleanup pruefen.
<!-- CHALLENGES_END -->

Summary:
Neuer AudioSource.PREVIEW Enum-Case hinzugefuegt. Preview-Methoden (playGongPreview, playBackgroundPreview) registrieren sich jetzt als PREVIEW beim AudioSessionCoordinator statt den Coordinator zu umgehen. Session wird bei Completion, explizitem Stop und Fade-Out-Ende freigegeben. PREVIEW Conflict Handler stoppt laufende Previews wenn Timer oder Guided Meditation startet. 10 neue Tests in AudioServiceTest und AudioSessionCoordinatorTest.

---

## REVIEW 1
Verdict: PASS

make check: OK
make test: OK

DISCUSSION:
<!-- DISCUSSION_START -->
- AudioService.kt:195 / AudioService.kt:306 – Wenn `mediaPlayerFactory.createFromResource(resourceId)` `null` zurückgibt (z.B. bei `resourceId == 0`), ist die PREVIEW-Session angefordert aber nie freigegeben. In der Praxis verhindert `GongSound.findOrDefault` diesen Pfad, aber ein explizites `if (player == null) { coordinator.releaseAudioSession(AudioSource.PREVIEW); return }` wäre defensiver – analog zu `startBackgroundAudio`, das `?: R.raw.silence` als Fallback nutzt.
- AudioServiceTest.kt:404 – `preview conflict handler stops all preview players` startet nur einen Gong-Preview. Ein zweites Szenario mit laufendem Background-Preview würde `cleanupPreviewPlayers()` vollständiger abdecken – ist aber kein Bug, da das Verhalten symmetrisch und bereits durch andere Tests gestützt ist.
<!-- DISCUSSION_END -->

Summary:
Saubere Implementierung. `AudioSource.PREVIEW` korrekt im Domain-Layer, Preview-Methoden registrieren sich jetzt beim Coordinator statt ihn zu umgehen. Das `hadPlayer`-Flag-Pattern verhindert Double-Release zuverlässig. `cleanupPreviewPlayers()` trennt sauber zwischen Cleanup (Conflict-Handler-Pfad) und Session-Release (expliziter Stop-Pfad) – das Coordinator-Design macht das korrekt, da `_activeSource` bei Conflict bereits auf die neue Source gesetzt ist. Alle kritischen Pfade getestet: Session-Request als PREVIEW, Release bei Completion/Stop, Idempotenz, Conflict-Handoff und Same-Source-Re-Request. `make check` und `make test` grün.

---

## CLOSE
Status: DONE
Commits:
- 2e03c0a docs: #shared-054 Close ticket
