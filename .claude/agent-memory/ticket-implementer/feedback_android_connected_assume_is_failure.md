---
name: feedback-android-connected-assume-is-failure
description: AGP connectedDebugAndroidTest reports a JUnit assumeTrue skip as FAILURE; exclude opt-in androidTests via notClass runner argument instead
metadata:
  type: feedback
---

`Assume.assumeTrue(...)` in an androidTest does NOT count as skipped under `connectedDebugAndroidTest`
(`make test-ui`, CI): the JUnit XML shows `failures="1"` with the AssumptionViolatedException. Plain
`adb shell am instrument` reports it correctly as skipped (status -4), which hides the problem.

**Why:** shared-144 data-snapshot generator was gated by an instrumentation argument + assume; the full UI
suite went red with 1 failure.

**How to apply:** For opt-in instrumented helpers (generators, destructive tools) add
`testInstrumentationRunnerArguments["notClass"] = "<fqcn>"` in `defaultConfig` — AGP passes it only to
connected runs, `am instrument -e class <fqcn>` from a script still runs it. Keep the assume as a second
guard. Related: [[feedback-runtest-backgroundscope-runcurrent]]. Also useful from the same ticket: Preferences
DataStore runs fine in plain JVM unit tests via `PreferenceDataStoreFactory.create(scope, produceFile)`
(file must end in `.preferences_pb`), no Robolectric needed.
