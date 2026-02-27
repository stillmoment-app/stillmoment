# Ticket android-064: Test-Output strukturierte Zusammenfassung

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Android bekommt dieselben Make-Targets wie iOS: `make test-unit-agent`, `make test-single-agent`,
`make test-unit`, `make test-single` und `make test-failures`.

Danach werden alle Stellen in Doku, Skills und Agents bereinigt, die iOS und Android noch
unterschiedlich behandeln — die Plattform-Unterscheidung bei Test-Commands wird obsolet.

---

## Warum

Aktuell hat Android nur `make test` (roher Gradle-Output, 50-200 Zeilen). iOS hat seit langem:

- `make test-unit-agent` / `make test-single-agent` — buffered, strukturiert, <10 Zeilen Output
- `make test-unit` / `make test-single` — xcbeautify, human-readable

Weil Android das Agent-Format fehlt, stehen in CLAUDE.md, agents und guides
plattform-spezifische Abschnitte ("iOS: make test-unit-agent" / "Android: make test").
Nach diesem Ticket gibt es keine Unterscheidung mehr — beide Plattformen sprechen dieselbe Sprache.

---

## Akzeptanzkriterien

### Android Makefile

- [ ] `make test-unit` — Alle Unit-Tests, human-lesbarer Output (analog iOS)
- [ ] `make test-unit-agent` — Alle Unit-Tests, strukturierter Output (RESULT/PASSED/FAILED/TIME + Failures, <10 Zeilen bei Erfolg)
- [ ] `make test-single TEST=ClassName/methodName` — Einzeltest, human-lesbarer Output
- [ ] `make test-single-agent TEST=ClassName/methodName` — Einzeltest, strukturierter Output
- [ ] `make test-failures` — Zeigt Failures aus letztem Run (aus JUnit XML-Reports)
- [ ] `make test` bleibt erhalten (volle Suite inkl. Instrumented Tests, unveraendert)

### Strukturiertes Output-Format (identisch zu iOS)

- [ ] Erster Token ist immer `RESULT: PASS`, `RESULT: FAIL` oder `RESULT: BUILD_FAILED`
- [ ] Danach: `PASSED: N`, `FAILED: N`, `TOTAL: N`, `TIME: Xs`
- [ ] Bei Failures: `FAILURES:`-Block mit Testname und Assertion-Message
- [ ] Bei Build-Fehler: letzten 30 Zeilen des Gradle-Outputs

### Implementierungshinweise

- JUnit XML-Reports liegen nach `./gradlew test` in `app/build/test-results/testDebugUnitTest/*.xml`
- Ein Shell-Script das die XMLs parst reicht aus (analog zu `ios/scripts/run-tests-agent.sh`)
- `make test-single-agent` braucht Gradle's `--tests "ClassName.methodName"` Flag
- Platzierung der Scripts: `android/scripts/` (analog iOS)

### Dokumentation anpassen

Nach der Implementierung muessen folgende Stellen bereinigt werden — die Plattform-Unterscheidung
bei Test-Commands wird an allen Stellen entfernt:

**`CLAUDE.md` (root)**
- [ ] "Testing rules"-Block: `make test-unit-agent` / `make test-single-agent` gilt jetzt fuer beide Plattformen — Klammer `(ios/ directory)` entfernen oder verallgemeinern
- [ ] "Daily workflow"-Block: Android-Section mit den neuen Targets erganzen (analog iOS-Section)
- [ ] Satz "Always use `make test-unit-agent` / `make test-single-agent` — agent-optimized output" gilt uneingeschraenkt — keine Plattform-Einschraenkung mehr noetig

**`android/CLAUDE.md`**
- [ ] Testing-Abschnitt: neue Make-Targets dokumentieren (analog iOS-Abschnitt in `ios/CLAUDE.md`)

**`.claude/agents/ticket-implementer.md`**
- [ ] TDD-Workflow: iOS/Android-Split aufloesen — ein einheitlicher Workflow mit `make test-single-agent` / `make test-unit-agent` fuer beide Plattformen
- [ ] Qualitaetssicherung: iOS/Android-Split aufloesen

**`.claude/agents/ticket-reviewer.md`**
- [ ] Test-Ausfuehrung: iOS (`make test-unit-agent`) / Android (`make test`) Split entfernen — einheitlich `make test-unit-agent`
- [ ] Kommentar "WICHTIG: Nicht blind ... Plattform ableiten" bleibt sinnvoll (Verzeichniswahl), aber die Target-Namen sind jetzt identisch

**`dev-docs/guides/implement-ticket.md`**
- [ ] `make test-unit` Referenzen pruefen — falls iOS-zentrisch, verallgemeinern

**`dev-docs/guides/tdd.md`**
- [ ] `make test-unit` als plattformuebergreifendes Command dokumentieren (bisher iOS-zentrisch)
- [ ] Android-spezifische Beispiele bei Bedarf erganzen

**Memory (`MEMORY.md`)**
- [ ] "Test-Ausfuehrung"-Abschnitt: iOS-Klammern bei `make test-unit-agent` entfernen — gilt jetzt fuer beide

### Tests

- [ ] Manueller Test: Einen Test absichtlich brechen → `make test-unit-agent` zeigt `RESULT: FAIL` mit Testname + Message
- [ ] Manueller Test: `make test-single-agent TEST=TimerReducerTest/someMethod` laeuft nur diesen Test
- [ ] `make test-failures` nach fehlgeschlagenem Run zeigt Failure-Liste
- [ ] Alle Tests gruen → einzeilige Zusammenfassung

### Dokumentation

- [ ] Keine separaten Docs — Aenderungen in bestehenden Dateien (s.o.)

---

## Manueller Test

1. Einen bestehenden Test absichtlich brechen (z.B. `assertEquals(42, 1)`)
2. `make test-unit-agent` ausfuehren
3. Erwartung:
   ```
   RESULT: FAIL
   PASSED: 41
   FAILED: 1
   TOTAL: 42
   TIME: 45s

   FAILURES:
     TimerReducerTest/someMethod
       expected: <42> but was: <1>
   ```
4. Test wieder reparieren, nochmal laufen → `RESULT: PASS`

---

## Referenz

- iOS-Implementation: `ios/scripts/run-tests-agent.sh`
- Android JUnit XML-Reports: `app/build/test-results/testDebugUnitTest/`
- Gradle Einzeltest-Flag: `./gradlew test --tests "ClassName.methodName"`
