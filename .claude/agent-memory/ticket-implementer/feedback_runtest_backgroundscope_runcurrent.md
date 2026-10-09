---
name: feedback-runtest-backgroundscope-runcurrent
description: In runTest laufen Coroutinen in backgroundScope bei advanceUntilIdle nicht — runCurrent verwenden
metadata:
  type: feedback
---

Wird eine Klasse im Test mit `scope = backgroundScope` gebaut (damit nie endende Jobs
`runTest` nicht blockieren), fuehrt `advanceUntilIdle()` deren Arbeit **nicht** aus —
Hintergrundarbeit zaehlt nicht als "foreground". Symptom: gestartete Jobs laufen nie,
Fakes melden "nichts gestartet".

**Why:** In shared-132 (`SharedLinkImportTest`) schlugen alle Tests so fehl, bis auf `runCurrent()` umgestellt wurde.

**How to apply:** Bei `backgroundScope` im Test `runCurrent()` (bzw. `advanceTimeBy`) statt `advanceUntilIdle()` nutzen.
