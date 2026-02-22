# Ticket android-064: Test-Output strukturierte Zusammenfassung

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

`make test` soll nach dem Test-Run eine kompakte, maschinenlesbare Zusammenfassung aller Failures ausgeben: Testname, Datei:Zeile, Fehlermeldung, pass/fail counts.

## Warum

Aktuell gibt `make test` nur den rohen Gradle-Output aus. Bei Test-Failures muss ein LLM-Subagent den unstrukturierten Output interpretieren, was zu iterativen Test-Fix-Test-Zyklen fuehrt. Jede Iteration erfordert eine erneute Genehmigung durch den User. Mit einer strukturierten Zusammenfassung bekommt der Subagent alle Informationen in einem Durchgang.

---

## Akzeptanzkriterien

### Feature
- [ ] Bei allen Tests gruen: Einzeilige Zusammenfassung mit Gesamtanzahl (z.B. "631 tests passed, 0 failed")
- [ ] Bei Failures: Pro Failure eine kompakte Ausgabe mit Testklasse, Testname, Assertion-Message und Stacktrace-Zeile
- [ ] Pass/fail counts immer am Ende sichtbar
- [ ] Kompilierungsfehler werden ebenfalls strukturiert ausgegeben (Datei, Zeile, Fehlermeldung)
- [ ] `make test` Verhalten bleibt unveraendert wenn keine Failures auftreten (kein Overhead)

### Tests
- [ ] Manueller Test: Absichtlich einen Test brechen, `make test` ausfuehren, pruefen ob Zusammenfassung alle Infos enthaelt

### Dokumentation
- [ ] Keine (internes Tooling)

---

## Manueller Test

1. Einen bestehenden Test absichtlich brechen (z.B. `assertEquals(42, 1)`)
2. `make test` ausfuehren
3. Erwartung: Am Ende des Outputs eine klare Zusammenfassung mit Testname, Datei:Zeile, Fehlermeldung
4. Test wieder reparieren

---

## Referenz

- iOS hat `make test-unit` mit xcbeautify fuer aufbereiteten Output
- Gradle schreibt JUnit XML-Reports nach `app/build/test-results/` — diese enthalten alle Failure-Details strukturiert

---

## Hinweise

- JUnit XML-Reports in `build/test-results/testDebugUnitTest/` enthalten Testname, Classname, Failure-Message und Stacktrace
- Ein einfaches Shell-Script das nach `./gradlew test` die XMLs parst reicht aus
- Auch `make test-unit` als Alias analog zu iOS erwaegen
