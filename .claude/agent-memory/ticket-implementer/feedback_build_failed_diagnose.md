---
name: feedback-build-failed-diagnose
description: Bei RESULT BUILD_FAILED aus make test-*-agent die Ausgabe in eine Datei umleiten und darin nach dem Compiler-Fehler greppen, statt den Befehl erneut zu starten
metadata:
  type: feedback
---

Wenn `make test-unit-agent` / `make test-single-agent` mit `RESULT: BUILD_FAILED`
endet, die Ausgabe **beim ersten Lauf** in eine Datei im Scratchpad umleiten
(`make -C … test-single-agent TEST=… > <scratchpad>/red.log 2>&1`) und dort mit
`grep -n "Cannot find\|error:"` nach der Ursache suchen.

**Why:** Das Skript zeigt bei Build-Fehlern nur `tail -30` der xcodebuild-Ausgabe.
Darin steht oft nur die aufgeblähte `swift-frontend`-Kommandozeile, nicht die
eigentliche Fehlermeldung — der Diagnosewert ist dann null. Wer daraufhin denselben
Befehl mit anderem `grep` nochmal startet, verstößt gegen die Projektregel
„gleichen fehlgeschlagenen Command nie wiederholen" und verbrennt 20–40 Sekunden
pro Versuch.

**Android-Falle:** `android/scripts/run-tests-agent.sh` meldet einen Compile-/Hilt-Fehler
NICHT als `BUILD_FAILED`, sobald alte JUnit-XMLs eines früheren Laufs in
`app/build/test-results/` liegen — dann kommt `RESULT: FAIL` mit den Zahlen des
*vorherigen* Laufs und ohne Fehlerdetails (z.B. `PASSED: 3, FAILED: 0`). Ursache dann
per `./gradlew -p <android> compileDebugUnitTestKotlin -q > datei` holen (typisch:
fehlendes `@Provides` → `Dagger/MissingBinding`).

**How to apply:** Gilt vor allem im TDD-Red-Schritt, wo ein Build-Fehler der
erwartete Zustand ist und die Fehlermeldung („Cannot find 'X' in scope") der
Beweis dafür, dass der Test aus dem richtigen Grund rot ist. Beim ersten Aufruf
einer neuen Testklasse also direkt mit Umleitung starten.
