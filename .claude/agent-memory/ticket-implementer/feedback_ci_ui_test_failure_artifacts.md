---
name: feedback_ci_ui_test_failure_artifacts
description: Flaky Android-UI-Test in CI analysieren — Stacktrace steht nicht im Job-Log, sondern im Artefakt android-ui-test-results; "Failed to inject touch input" ist oft nur "Knoten nicht gefunden"
metadata:
  type: feedback
---

CI-UI-Test-Fehler nicht aus der Meldung allein deuten. `gh run view --log-failed` zeigt nur "There were failing tests". Den echten Stacktrace und ein Logcat pro Test liefert das Artefakt `android-ui-test-results` (bei Re-Runs gibt es mehrere — das mit `<failure` im JUnit-XML nehmen; per `gh api repos/{owner}/{repo}/actions/runs/<id>/artifacts` listen, `.../artifacts/<id>/zip` laden).

**Why:** Bei android-096 (2026-10-10) klang `AssertionError: Failed to inject touch input.` nach Fenster-Fokus/Injektionsproblem. Die zweite Zeile ("Reason: … could not find any node") zeigte: Compose-`performClick` fand den Tab-Knoten nicht, weil `StillMomentNavHost` bis zum DataStore-Read des gespeicherten Tabs nichts rendert und `waitForIdle()` diesen IO-Read nicht abwartet.

**How to apply:** Erst Artefakt + Logcat lesen (Lifecycle-Zeilen von `ActivityScenario` zeigen das Timing), dann Hypothese bilden. Tests, die `MainActivity` starten, müssen auf einen echten UI-Anker warten (`waitUntil`), nicht nur auf `waitForIdle()`.
