---
id: android-096
title: "Android-UI-Tests in der CI ausführen"
status: done
phase: 5-QA
priority: mittel
depends_on: [android-095]
---

# Ticket android-096: Android-UI-Tests in der CI ausführen

## Was

Jeder Pull Request und jeder Push auf main führt die Android-UI-Tests auf einem Emulator aus. Das Ergebnis erscheint als eigener Check, so wie auf iOS der Check „UI Tests“.

## Warum

Die CI führt für Android bisher nur Unit-Tests aus. Deshalb sind seit Mai 2026 neun UI-Tests rot geworden, ohne dass es jemandem auffiel (android-095). Erst bei android-091 kam es heraus, und dort war nur durch einen Vergleich mit einem älteren Stand zu klären, ob die Fehler neu waren. Dependabot liefert jetzt jeden Monat Updates für Compose und AndroidX. Deren Änderungen an der Oberfläche fangen nur UI-Tests, und die laufen bisher nur, wenn jemand sie lokal startet.

---

## Akzeptanzkriterien

- [ ] Pull Requests und Pushes auf main zeigen einen eigenen Check für die Android-UI-Tests
- [ ] Ein absichtlich roter UI-Test lässt diesen Check rot werden, nachgewiesen an einem Wegwerf-PR
- [ ] Der Check führt dieselben UI-Tests aus wie ein lokaler Lauf; kein Test wird für die CI ausgenommen
- [ ] Zwei Läufe auf demselben Stand liefern dasselbe Ergebnis
- [ ] Der Check braucht nicht länger als der iOS-Check „UI Tests“ (zuletzt 9 bis 16 Minuten)
- [ ] Lokal lassen sich die Android-UI-Tests mit einem einzigen Befehl starten, wie auf iOS
- [ ] Bei einem roten Lauf lässt sich in der CI ablesen, welche Tests fehlgeschlagen sind und warum

---

## Manueller Test

1. Einen Wegwerf-PR öffnen, der nur einen UI-Test absichtlich scheitern lässt
2. Erwartung: Der Android-UI-Test-Check wird rot und nennt den Test
3. Den PR auf den grünen Stand zurücksetzen und den Check zweimal laufen lassen
4. Erwartung: Beide Läufe sind grün, und die Laufzeit liegt im Rahmen

---

## Nicht Teil dieses Tickets

- Die neun roten UI-Tests reparieren. Das ist android-095 und muss vorher erledigt sein, sonst ist der neue Check von Anfang an rot.
- Den Check zum Pflicht-Check für den Merge machen. Das ist eine Repo-Einstellung, die nur ein Admin vornehmen kann. Sinnvoll erst, wenn der Check sich als stabil erwiesen hat.

---

## Umsetzungsnotiz

- Neuer Job „Android UI Tests“ in `.github/workflows/ci.yml`: `reactivecircus/android-emulator-runner` auf `ubuntu-latest` mit KVM, API 36 `google_apis` x86_64, frischer Emulator ohne Snapshot, Animationen aus. Führt `make test-ui` (= `connectedDebugAndroidTest`) aus, alle 75 Tests inkl. Screengrab-Screenshots, keiner ausgenommen.
- Fehlgeschlagene Tests erscheinen als Annotation am Check und in der Job-Zusammenfassung (`android/scripts/ui-test-summary.py`); JUnit-XML und HTML-Report als Artefakt `android-ui-test-results`.
- Lokal: `make test-ui`, knapp für Agents `make test-ui-agent` (75/75 grün in 154 s).
- Nachweise (2026-10-10, PR #18/#19): Wegwerf-PR mit absichtlich rotem Test → Check rot, Annotation nennt `TimerScreenTest.timerScreen_showsDurationQuestion_whenIdle` mit Meldung. Laufzeit 10–11 min (iOS „UI Tests“ 9–14 min). Ein Re-Run deckte einen flaky Screenshot-Test auf (Tab-Klick, bevor die Tab-Leiste nach dem DataStore-Lesen erschien); behoben durch Warten auf die App-Shell. Danach zwei Läufe auf identischem Stand grün.

---

## Hinweise

- Die Android-Checks sind derzeit keine Pflicht-Checks. Deshalb konnten die Dependabot-PRs #9 und #10 mit roter CI gemergt werden.
- Die Screenshot-Tests liegen in derselben Suite. Wenn sie im Check mitlaufen, fallen kaputte Store-Screenshots nicht erst beim Release auf.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
