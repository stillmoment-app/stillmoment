---
name: feedback-runtest-realthread-virtual-timeout
description: runTest + Code mit echtem Dispatchers.IO + Hintergrund-Timeout auf dem Test-Scheduler = Flake; Dispatcher injizieren
metadata:
  type: feedback
---

Wartet der Test-Body in `runTest` auf einen echten Thread (z.B. `withContext(Dispatchers.IO)`
im Produktcode), arbeitet die runTest-Schleife derweil die Hintergrund-Tasks ab und springt
**virtuell** zu deren verzögerten Ereignissen (`withTimeoutOrNull`, `delay`). Ein Timeout
feuert so "sofort", bevor der Test seine Antwort liefert. Selten (CI ~1/1500), lokal grün.

**Why:** android-079 `CustomAudioRepositoryImplImportTest` (Fix 2026-10-10, Branch
fix/android-079-flaky-test). Rot reproduzierbar per temporärem `Thread.sleep(200)` nach dem
Scheduling im Produktcode.

**How to apply:** Produktcode mit `withContext(Dispatchers.IO)` + Hintergrundarbeit mit
Timeout: IO-Dispatcher injizierbar machen (Primärkonstruktor + `@Inject`-Sekundärkonstruktor
mit `Dispatchers.IO`), im Test `StandardTestDispatcher(testScheduler)` übergeben. Verwandt:
[[feedback-runtest-backgroundscope-runcurrent]].
